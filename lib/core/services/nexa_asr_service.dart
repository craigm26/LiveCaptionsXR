import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:nexa_ai_flutter/nexa_ai_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../models/speech_config.dart';
import '../models/speech_result.dart';
import 'app_logger.dart';
import 'whisper_service_impl.dart';

/// Event class for Nexa ASR progress and status
/// Compatible with WhisperSTTEvent for seamless integration
class NexaAsrEvent {
  final double progress; // 0.0 to 1.0
  final String message;
  final bool isComplete;
  final Object? error;
  final String? transcription;

  const NexaAsrEvent({
    required this.progress,
    required this.message,
    this.isComplete = false,
    this.error,
    this.transcription,
  });

  /// Convert to WhisperSTTEvent for compatibility with existing code
  WhisperSTTEvent toWhisperSTTEvent() {
    return WhisperSTTEvent(
      progress: progress,
      message: message,
      isComplete: isComplete,
      error: error,
    );
  }
}

/// Inference mode for Nexa SDK
enum NexaInferenceMode {
  npu, // Qualcomm Hexagon NPU
  gpu, // GPU acceleration
  cpu, // CPU fallback
}

/// Device information from Nexa SDK
class NexaDeviceInfo {
  final String manufacturer;
  final String model;
  final String device;
  final String hardware;
  final String chipset;
  final int sdkVersion;
  final bool npuAvailable;
  final bool gpuAvailable;
  final NexaInferenceMode currentInferenceMode;

  const NexaDeviceInfo({
    required this.manufacturer,
    required this.model,
    required this.device,
    required this.hardware,
    required this.chipset,
    required this.sdkVersion,
    required this.npuAvailable,
    required this.gpuAvailable,
    required this.currentInferenceMode,
  });

  factory NexaDeviceInfo.fromMap(Map<dynamic, dynamic> map) {
    return NexaDeviceInfo(
      manufacturer: map['manufacturer'] as String? ?? '',
      model: map['model'] as String? ?? '',
      device: map['device'] as String? ?? '',
      hardware: map['hardware'] as String? ?? '',
      chipset: map['chipset'] as String? ?? '',
      sdkVersion: map['sdkVersion'] as int? ?? 0,
      npuAvailable: map['npuAvailable'] as bool? ?? false,
      gpuAvailable: map['gpuAvailable'] as bool? ?? false,
      currentInferenceMode: _parseInferenceMode(map['currentInferenceMode']),
    );
  }

  static NexaInferenceMode _parseInferenceMode(String? mode) {
    switch (mode?.toUpperCase()) {
      case 'NPU':
        return NexaInferenceMode.npu;
      case 'GPU':
        return NexaInferenceMode.gpu;
      default:
        return NexaInferenceMode.cpu;
    }
  }

  bool get isNpuAccelerated => currentInferenceMode == NexaInferenceMode.npu;
}

/// Service for handling Nexa SDK ASR (Automatic Speech Recognition)
///
/// This service provides on-device speech-to-text using Nexa SDK with:
/// - NPU acceleration on Qualcomm Snapdragon devices
/// - GPU fallback for other Android devices
/// - CPU fallback for unsupported hardware
///
/// Uses the nexa_ai_flutter package for direct Flutter integration.
///
/// For the Qualcomm x Nexa On-Device AI Bounty Program.
class NexaAsrService {
  static final AppLogger _logger = AppLogger.instance;

  // Method channel for device info (native Android)
  static const MethodChannel _deviceChannel =
      MethodChannel('live_captions_xr/nexa_asr');

  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _sdkInitialized = false;
  SpeechConfig _config = const SpeechConfig();
  NexaInferenceMode _inferenceMode = NexaInferenceMode.cpu;
  NexaDeviceInfo? _deviceInfo;

  // Nexa SDK ASR wrapper
  AsrWrapper? _asrWrapper;
  String? _modelPath;

  final StreamController<SpeechResult> _speechResultController =
      StreamController<SpeechResult>.broadcast();

  // Compatible event stream with WhisperSTTEvent
  final StreamController<WhisperSTTEvent> _sttEventController =
      StreamController<WhisperSTTEvent>.broadcast();

  // Native Nexa event stream
  final StreamController<NexaAsrEvent> _nexaEventController =
      StreamController<NexaAsrEvent>.broadcast();

  /// Stream of speech results
  Stream<SpeechResult> get speechResults => _speechResultController.stream;

  /// Stream of STT events (compatible with existing WhisperService)
  Stream<WhisperSTTEvent> get sttEvents => _sttEventController.stream;

  /// Stream of Nexa-specific events
  Stream<NexaAsrEvent> get nexaEvents => _nexaEventController.stream;

  bool get isInitialized => _isInitialized;
  bool get isProcessing => _isProcessing;
  NexaInferenceMode get inferenceMode => _inferenceMode;
  NexaDeviceInfo? get deviceInfo => _deviceInfo;
  bool get isNpuAccelerated => _inferenceMode == NexaInferenceMode.npu;

  /// Check if Nexa ASR is available on this platform
  static bool get isAvailable => Platform.isAndroid;

  /// Check if NPU acceleration is available on this device
  Future<bool> isNpuAvailable() async {
    if (!Platform.isAndroid) return false;

    try {
      // Check device compatibility via native channel
      final result = await _deviceChannel.invokeMethod<bool>('isNpuAvailable');
      return result ?? false;
    } catch (e) {
      _logger.e('Failed to check NPU availability', error: e);
      // Try to detect via model compatibility check
      try {
        final models = await ModelDownloader.getAvailableModels();
        // If we can get NPU-compatible models, NPU is likely available
        return models.any((m) => m.pluginId == 'npu');
      } catch (_) {
        return false;
      }
    }
  }

  /// Get device information
  Future<NexaDeviceInfo?> getDeviceInfo() async {
    if (!Platform.isAndroid) return null;

    try {
      final result =
          await _deviceChannel.invokeMethod<Map<dynamic, dynamic>>('getDeviceInfo');
      if (result != null) {
        _deviceInfo = NexaDeviceInfo.fromMap(result);
        return _deviceInfo;
      }
      return null;
    } catch (e) {
      _logger.e('Failed to get device info', error: e);
      return null;
    }
  }

  /// Initialize the Nexa SDK
  Future<bool> _initializeSdk() async {
    if (_sdkInitialized) return true;

    try {
      _logger.i('🚀 Initializing Nexa SDK...', category: LogCategory.speech);
      await NexaSdk.getInstance().init();
      _sdkInitialized = true;
      _logger.i('✅ Nexa SDK initialized', category: LogCategory.speech);
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to initialize Nexa SDK',
          error: e, stackTrace: stackTrace, category: LogCategory.speech);
      return false;
    }
  }

  /// Initialize the Nexa ASR service with configuration
  Future<bool> initialize({
    SpeechConfig? config,
    String? modelPath,
    bool preferNpu = true,
  }) async {
    if (!Platform.isAndroid) {
      _logger.w('Nexa ASR is only available on Android');
      return false;
    }

    if (_isInitialized) {
      _logger.i('Nexa ASR already initialized');
      return true;
    }

    try {
      _config = config ?? const SpeechConfig();

      // Emit STT event for initialization start
      _emitEvent(const NexaAsrEvent(
        progress: 0.0,
        message: 'Initializing Nexa ASR service...',
      ));

      // Initialize Nexa SDK first
      final sdkReady = await _initializeSdk();
      if (!sdkReady) {
        _emitEvent(const NexaAsrEvent(
          progress: 0.0,
          message: 'Failed to initialize Nexa SDK',
          error: 'SDK initialization failed',
        ));
        return false;
      }

      _emitEvent(const NexaAsrEvent(
        progress: 0.2,
        message: 'Checking NPU availability...',
      ));

      // Check NPU availability
      final npuAvailable = await isNpuAvailable();
      _inferenceMode = preferNpu && npuAvailable
          ? NexaInferenceMode.npu
          : NexaInferenceMode.cpu;

      _logger.i('🚀 Selected inference mode: ${_inferenceMode.name.toUpperCase()}',
          category: LogCategory.speech);

      _emitEvent(NexaAsrEvent(
        progress: 0.4,
        message: 'Using ${_inferenceMode.name.toUpperCase()} acceleration...',
      ));

      // Get model path
      _modelPath = modelPath ?? await _getDefaultModelPath();

      _emitEvent(const NexaAsrEvent(
        progress: 0.6,
        message: 'Loading ASR model...',
      ));

      // Create ASR wrapper with appropriate plugin
      final pluginId = _inferenceMode == NexaInferenceMode.npu ? 'npu' : 'cpu_gpu';

      try {
        _asrWrapper = await AsrWrapper.create(
          AsrCreateInput(
            modelName: 'parakeet', // Nexa's ASR model for NPU
            modelPath: _modelPath!,
            config: ModelConfig(
              maxTokens: 2048,
            ),
            pluginId: pluginId,
          ),
        );

        _isInitialized = true;

        _emitEvent(NexaAsrEvent(
          progress: 1.0,
          message: 'Nexa ASR ready (${_inferenceMode.name.toUpperCase()})',
          isComplete: true,
        ));

        _logger.i(
            '✅ Nexa ASR initialized with ${_inferenceMode.name.toUpperCase()} acceleration',
            category: LogCategory.speech);

        // Get device info for analytics
        await getDeviceInfo();

        return true;
      } catch (e) {
        _logger.w('⚠️ Failed to create ASR wrapper with $pluginId, trying fallback',
            error: e, category: LogCategory.speech);

        // Try CPU fallback if NPU fails
        if (_inferenceMode == NexaInferenceMode.npu) {
          _inferenceMode = NexaInferenceMode.cpu;
          try {
            _asrWrapper = await AsrWrapper.create(
              AsrCreateInput(
                modelPath: _modelPath!,
                config: ModelConfig(maxTokens: 2048),
                pluginId: 'cpu_gpu',
              ),
            );

            _isInitialized = true;
            _emitEvent(NexaAsrEvent(
              progress: 1.0,
              message: 'Nexa ASR ready (CPU fallback)',
              isComplete: true,
            ));
            return true;
          } catch (fallbackError) {
            _logger.e('❌ ASR fallback also failed',
                error: fallbackError, category: LogCategory.speech);
          }
        }
        rethrow;
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to initialize Nexa ASR',
          error: e, stackTrace: stackTrace, category: LogCategory.speech);

      _emitEvent(NexaAsrEvent(
        progress: 0.0,
        message: 'Failed to initialize Nexa ASR',
        error: e,
      ));

      return false;
    }
  }

  /// Start processing audio data
  Future<bool> startProcessing() async {
    if (!_isInitialized || _asrWrapper == null) {
      _logger.w('Nexa ASR not initialized');
      return false;
    }

    if (_isProcessing) {
      _logger.i('Nexa ASR already processing');
      return true;
    }

    _isProcessing = true;
    _logger.i('🎤 Nexa ASR processing started', category: LogCategory.speech);
    return true;
  }

  /// Process audio buffer and return transcription
  Future<SpeechResult> processAudioBuffer(Uint8List audioData) async {
    if (!_isInitialized || _asrWrapper == null) {
      _logger.w('Nexa ASR not initialized, returning fallback result');

      _emitEvent(const NexaAsrEvent(
        progress: 0.0,
        message: 'Nexa ASR not initialized',
        error: 'Service not initialized',
      ));

      return SpeechResult(
        text: '',
        confidence: 0.0,
        isFinal: true,
        timestamp: DateTime.now(),
      );
    }

    try {
      _logger.d('🎵 Processing audio buffer (${audioData.length} bytes) with Nexa ASR',
          category: LogCategory.speech);

      _emitEvent(const NexaAsrEvent(
        progress: 0.3,
        message: 'Transcribing with Nexa ASR...',
      ));

      // Save audio to temporary file for Nexa ASR
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/nexa_audio_${DateTime.now().millisecondsSinceEpoch}.wav');
      await tempFile.writeAsBytes(audioData);

      try {
        // Transcribe using Nexa ASR
        final result = await _asrWrapper!.transcribe(
          AsrTranscribeInput(
            audioPath: tempFile.path,
            language: _config.language,
          ),
        );

        final transcription = result.result.transcript;

        final speechResult = SpeechResult(
          text: transcription,
          confidence: 0.95, // Nexa doesn't provide confidence, use high default
          isFinal: true,
          timestamp: DateTime.now(),
        );

        _logger.d(
            '📝 Nexa ASR result: "${speechResult.text}"',
            category: LogCategory.speech);

        _emitEvent(NexaAsrEvent(
          progress: 1.0,
          message: 'Transcription complete',
          isComplete: true,
          transcription: speechResult.text,
        ));

        _speechResultController.add(speechResult);
        return speechResult;
      } finally {
        // Clean up temp file
        try {
          await tempFile.delete();
        } catch (_) {}
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Error processing audio with Nexa ASR',
          error: e, stackTrace: stackTrace, category: LogCategory.speech);

      _emitEvent(NexaAsrEvent(
        progress: 0.0,
        message: 'Error processing audio',
        error: e,
      ));

      final fallbackResult = SpeechResult(
        text: '',
        confidence: 0.0,
        isFinal: true,
        timestamp: DateTime.now(),
      );

      _speechResultController.add(fallbackResult);
      return fallbackResult;
    }
  }

  /// Stop processing
  Future<void> stopProcessing() async {
    if (!_isProcessing) return;

    _isProcessing = false;
    _logger.i('🛑 Stopped Nexa ASR processing', category: LogCategory.speech);

    _emitEvent(const NexaAsrEvent(
      progress: 0.0,
      message: 'Nexa ASR processing stopped',
    ));
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      await stopProcessing();

      if (_asrWrapper != null) {
        await _asrWrapper!.destroy();
        _asrWrapper = null;
      }

      await _speechResultController.close();
      await _sttEventController.close();
      await _nexaEventController.close();

      _isInitialized = false;
      _logger.i('🗑️ Nexa ASR service disposed', category: LogCategory.speech);
    } catch (e, stackTrace) {
      _logger.e('Error disposing Nexa ASR service',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Get the default model path for ASR
  Future<String> _getDefaultModelPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/models/nexa-asr';
  }

  /// Emit event to all streams
  void _emitEvent(NexaAsrEvent event) {
    _nexaEventController.add(event);
    _sttEventController.add(event.toWhisperSTTEvent());
  }
}
