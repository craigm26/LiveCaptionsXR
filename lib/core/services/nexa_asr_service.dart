import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:nexa_ai_flutter/nexa_ai_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../di/service_locator.dart';
import '../models/device_model_config.dart';
import '../models/speech_config.dart';
import '../models/speech_result.dart';
import 'app_logger.dart';
import 'download/unified_download_manager.dart';
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
  DeviceModelConfig? _deviceModelConfig;

  // Device model registry for optimal model selection
  final DeviceModelRegistry _modelRegistry = DeviceModelRegistry();

  // Nexa SDK ASR wrapper
  AsrWrapper? _asrWrapper;
  String? _modelPath;
  String _currentModelName = 'parakeet'; // Default, will be overridden by registry

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
  DeviceModelConfig? get deviceModelConfig => _deviceModelConfig;
  String get currentModelName => _currentModelName;
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
        return models.any((m) =>
          m.displayName.toLowerCase().contains('npu') ||
          m.type.toLowerCase().contains('npu'));
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
        progress: 0.1,
        message: 'Detecting device capabilities...',
      ));

      // Get optimal model configuration for this device
      _deviceModelConfig = await _modelRegistry.getDeviceConfig();
      _currentModelName = _deviceModelConfig!.asrModel.name;

      _logger.i('📱 Device config: ${_deviceModelConfig!.deviceId}',
          category: LogCategory.speech);
      _logger.i('🎤 Selected ASR model: $_currentModelName (${_deviceModelConfig!.asrModel.displayName})',
          category: LogCategory.speech);

      _emitEvent(const NexaAsrEvent(
        progress: 0.2,
        message: 'Checking NPU availability...',
      ));

      // Check NPU availability and use device recommendation
      final npuAvailable = await isNpuAvailable();
      _inferenceMode = preferNpu && npuAvailable && _deviceModelConfig!.preferNpu
          ? NexaInferenceMode.npu
          : _deviceModelConfig!.recommendedInferenceMode;

      _logger.i('🚀 Selected inference mode: ${_inferenceMode.name.toUpperCase()}',
          category: LogCategory.speech);

      _emitEvent(NexaAsrEvent(
        progress: 0.4,
        message: 'Using ${_inferenceMode.name.toUpperCase()} acceleration...',
      ));

      // Get model path (use provided path or check/download model)
      if (modelPath != null) {
        _modelPath = modelPath;
      } else {
        // Ensure model is downloaded via UnifiedDownloadManager
        final modelDownloaded = await _ensureModelDownloaded(_currentModelName);
        if (!modelDownloaded) {
          _logger.w('⚠️ Model download failed/skipped, checking native SDK path...',
              category: LogCategory.speech);
          // Try Nexa SDK's native path lookup as fallback
          try {
            final nativePath = await ModelDownloader.getModelPath(_currentModelName);
            if (nativePath != null) {
              _modelPath = nativePath;
              _logger.i('✅ Found model at native SDK path: $nativePath',
                  category: LogCategory.speech);
            } else {
              _modelPath = await _getDefaultModelPath();
            }
          } catch (_) {
            _modelPath = await _getDefaultModelPath();
          }
        }
      }

      _emitEvent(NexaAsrEvent(
        progress: 0.6,
        message: 'Loading $_currentModelName model...',
      ));

      // Create ASR wrapper with appropriate plugin
      final pluginId = _inferenceMode == NexaInferenceMode.npu ? 'npu' : 'cpu_gpu';

      try {
        _asrWrapper = await AsrWrapper.create(
          AsrCreateInput(
            modelName: _currentModelName, // Device-specific model from registry
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
        _logger.w('⚠️ Failed to create ASR wrapper with $pluginId for $_currentModelName, trying fallbacks',
            error: e, category: LogCategory.speech);

        // Try fallback models from registry
        final fallbacks = _deviceModelConfig?.asrFallbacks ?? [];
        for (final fallbackModel in fallbacks) {
          _logger.i('🔄 Trying fallback model: ${fallbackModel.name}',
              category: LogCategory.speech);

          _emitEvent(NexaAsrEvent(
            progress: 0.7,
            message: 'Trying ${fallbackModel.displayName}...',
          ));

          try {
            final fallbackPluginId = fallbackModel.supportsNpu && _inferenceMode == NexaInferenceMode.npu
                ? 'npu'
                : 'cpu_gpu';

            _asrWrapper = await AsrWrapper.create(
              AsrCreateInput(
                modelName: fallbackModel.name,
                modelPath: await _getDefaultModelPath(),
                config: ModelConfig(maxTokens: 2048),
                pluginId: fallbackPluginId,
              ),
            );

            _currentModelName = fallbackModel.name;
            _isInitialized = true;
            _emitEvent(NexaAsrEvent(
              progress: 1.0,
              message: 'Nexa ASR ready (${fallbackModel.displayName})',
              isComplete: true,
            ));

            _logger.i('✅ ASR initialized with fallback: ${fallbackModel.name}',
                category: LogCategory.speech);
            return true;
          } catch (fallbackError) {
            _logger.w('⚠️ Fallback ${fallbackModel.name} also failed',
                error: fallbackError, category: LogCategory.speech);
          }
        }

        // Try CPU mode as last resort with original model
        if (_inferenceMode == NexaInferenceMode.npu) {
          _inferenceMode = NexaInferenceMode.cpu;
          try {
            _asrWrapper = await AsrWrapper.create(
              AsrCreateInput(
                modelName: _currentModelName,
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
            _logger.e('❌ All ASR fallbacks failed',
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

  /// Ensure the ASR model is downloaded before use
  Future<bool> _ensureModelDownloaded(String modelName) async {
    try {
      final downloadManager = sl<UnifiedDownloadManager>();

      // Check if model is already installed
      if (await downloadManager.isModelInstalled(modelName)) {
        _logger.i('✅ Model $modelName already installed', category: LogCategory.speech);
        final path = await downloadManager.getModelPath(modelName);
        if (path != null) {
          _modelPath = path;
        }
        return true;
      }

      _logger.i('📥 Downloading model $modelName...', category: LogCategory.speech);

      _emitEvent(NexaAsrEvent(
        progress: 0.3,
        message: 'Downloading $modelName model...',
      ));

      // Download the model
      await for (final progress in downloadManager.downloadModel(modelName)) {
        _emitEvent(NexaAsrEvent(
          progress: 0.3 + (progress.progress * 0.3), // Scale to 0.3-0.6 range
          message: 'Downloading: ${(progress.progress * 100).toStringAsFixed(0)}%',
        ));

        if (progress.isComplete) {
          _logger.i('✅ Model $modelName downloaded successfully', category: LogCategory.speech);
          final path = await downloadManager.getModelPath(modelName);
          if (path != null) {
            _modelPath = path;
          }
          return true;
        }

        if (progress.hasFailed) {
          _logger.e('❌ Failed to download model $modelName: ${progress.error}',
              category: LogCategory.speech);
          return false;
        }

        if (progress.isCancelled) {
          _logger.w('⚠️ Model download cancelled', category: LogCategory.speech);
          return false;
        }
      }

      return false;
    } catch (e) {
      _logger.e('❌ Error ensuring model downloaded', error: e, category: LogCategory.speech);
      return false;
    }
  }

  /// Emit event to all streams
  void _emitEvent(NexaAsrEvent event) {
    _nexaEventController.add(event);
    _sttEventController.add(event.toWhisperSTTEvent());
  }
}
