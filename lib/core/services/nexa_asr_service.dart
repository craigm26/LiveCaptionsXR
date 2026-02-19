import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

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
  String _currentModelName = 'parakeet-tdt-0.6b-v3-npu'; // Download ID, overridden by registry
  String _currentPluginName = 'parakeet'; // Short name for Nexa SDK JNI, overridden by registry
  int _consecutiveFailures = 0;
  static const int _maxConsecutiveFailures = 5;

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
      // Check if Nexa native library is available BEFORE loading the SDK class.
      // On x86_64 emulators, libnpu_jni.so doesn't exist and the static
      // initializer would crash the entire process with UnsatisfiedLinkError.
      final sdkAvailable = await _isNexaSdkNativeAvailable();
      if (!sdkAvailable) {
        _logger.w('⚠️ Nexa SDK native library not available on this device/architecture',
            category: LogCategory.speech);
        return false;
      }

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

  /// Check if the Nexa SDK native library is available on this device.
  /// This prevents a fatal UnsatisfiedLinkError on non-ARM devices.
  static Future<bool> _isNexaSdkNativeAvailable() async {
    try {
      final result = await _deviceChannel.invokeMethod<bool>('isNexaSdkAvailable');
      return result ?? false;
    } catch (e) {
      _logger.w('⚠️ Could not check Nexa SDK availability: $e',
          category: LogCategory.speech);
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
      _currentPluginName = _deviceModelConfig!.asrModel.nexaModelName;

      _logger.i('📱 Device config: ${_deviceModelConfig!.deviceId}',
          category: LogCategory.speech);
      _logger.i('🎤 Selected ASR model: $_currentModelName (plugin: $_currentPluginName, ${_deviceModelConfig!.asrModel.displayName})',
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
              // No valid model path — model is not downloaded yet.
              // Do NOT proceed to ASR create with a nonexistent path.
              _logger.e('❌ No model path available — model not downloaded',
                  category: LogCategory.speech);
              _emitEvent(const NexaAsrEvent(
                progress: 0.0,
                message: 'Model not downloaded yet. Please wait for download to complete.',
                error: 'ASR model not available — download may still be in progress',
              ));
              return false;
            }
          } catch (_) {
            _logger.e('❌ Could not resolve model path — model not downloaded',
                category: LogCategory.speech);
            _emitEvent(const NexaAsrEvent(
              progress: 0.0,
              message: 'Model not downloaded yet. Please wait for download to complete.',
              error: 'ASR model not available — download may still be in progress',
            ));
            return false;
          }
        }
      }

      _emitEvent(NexaAsrEvent(
        progress: 0.6,
        message: 'Loading $_currentModelName model...',
      ));

      // Create ASR wrapper with appropriate plugin
      final pluginId = _inferenceMode == NexaInferenceMode.npu ? 'npu' : 'cpu_gpu';

      _logger.i('📂 ASR model path: $_modelPath', category: LogCategory.speech);
      _logger.i('🔌 Plugin ID: $pluginId, Download ID: $_currentModelName, Plugin name: $_currentPluginName', category: LogCategory.speech);

      // Try both: first the exact path from SDK, then directory path
      String asrModelPath = _modelPath!;
      String? asrDirPath;
      if (asrModelPath.endsWith('.nexa')) {
        // Save directory path as fallback
        final lastSlash = asrModelPath.lastIndexOf('/');
        if (lastSlash > 0) {
          asrDirPath = asrModelPath.substring(0, lastSlash);
        }
      }
      _logger.i('📂 Will try file path first: $asrModelPath', category: LogCategory.speech);
      if (asrDirPath != null) {
        _logger.i('📂 Then directory path: $asrDirPath', category: LogCategory.speech);
      }

      // Try file path first, then directory path, then directory with modelName
      final pathsToTry = <String>[
        asrModelPath,
        if (asrDirPath != null) asrDirPath,
      ];

      Exception? lastError;
      for (final tryPath in pathsToTry) {
        try {
          _logger.i('🔄 Trying ASR create with path: $tryPath, pluginName: $_currentPluginName', category: LogCategory.speech);
          _asrWrapper = await AsrWrapper.create(
            AsrCreateInput(
              modelName: _currentPluginName,
              modelPath: tryPath,
              config: ModelConfig(
                maxTokens: 2048,
              ),
              pluginId: pluginId,
            ),
          );
          _logger.i('✅ ASR create succeeded with path: $tryPath', category: LogCategory.speech);
          break; // Success!
        } catch (e) {
          _logger.w('⚠️ ASR create failed with path $tryPath: $e', category: LogCategory.speech);
          lastError = e is Exception ? e : Exception(e.toString());
          _asrWrapper = null;
        }
      }

      if (_asrWrapper != null) {
        // Validate that the ASR model is truly ready by running a warmup
        // transcription. The Nexa SDK's AsrWrapper.create() can return
        // successfully while the internal config is still null (NPU model
        // not fully loaded). The warmup catches this and retries.
        _emitEvent(NexaAsrEvent(
          progress: 0.8,
          message: 'Validating ASR model...',
        ));

        final warmupOk = await _warmupAsr();
        if (!warmupOk) {
          _logger.w('⚠️ ASR warmup failed — model config not ready, retrying...',
              category: LogCategory.speech);
          // Retry: destroy, wait, re-create
          try { await _asrWrapper!.destroy(); } catch (_) {}
          _asrWrapper = null;

          for (int retry = 1; retry <= 3; retry++) {
            _emitEvent(NexaAsrEvent(
              progress: 0.6 + (retry * 0.1),
              message: 'Retrying ASR init (attempt ${retry + 1})...',
            ));
            _logger.i('🔄 ASR retry $retry: waiting ${retry * 2}s for NPU to settle...',
                category: LogCategory.speech);
            await Future.delayed(Duration(seconds: retry * 2));

            try {
              _asrWrapper = await AsrWrapper.create(
                AsrCreateInput(
                  modelName: _currentPluginName,
                  modelPath: pathsToTry.first,
                  config: ModelConfig(maxTokens: 2048),
                  pluginId: pluginId,
                ),
              );
              final retryWarmup = await _warmupAsr();
              if (retryWarmup) {
                _logger.i('✅ ASR warmup succeeded on retry $retry',
                    category: LogCategory.speech);
                break;
              } else {
                _logger.w('⚠️ ASR warmup failed on retry $retry',
                    category: LogCategory.speech);
                try { await _asrWrapper!.destroy(); } catch (_) {}
                _asrWrapper = null;
              }
            } catch (e) {
              _logger.w('⚠️ ASR create failed on retry $retry: $e',
                  category: LogCategory.speech);
              _asrWrapper = null;
            }
          }

          if (_asrWrapper == null) {
            _logger.e('❌ ASR warmup failed after all retries — config never became ready',
                category: LogCategory.speech);
            // Fall through to fallback logic below
          }
        }
      }

      if (_asrWrapper != null) {
        _isInitialized = true;
        _consecutiveFailures = 0;

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
      } else {
        _logger.w('⚠️ Failed to create ASR wrapper with $pluginId for $_currentModelName, trying fallbacks',
            error: lastError, category: LogCategory.speech);

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
                modelName: fallbackModel.nexaModelName,
                modelPath: await _getDefaultModelPath(),
                config: ModelConfig(maxTokens: 2048),
                pluginId: fallbackPluginId,
              ),
            );

            _currentModelName = fallbackModel.name;
            _currentPluginName = fallbackModel.nexaModelName;
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
                modelName: _currentPluginName,
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
        throw lastError ?? Exception('All ASR create attempts failed');
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

    // Skip processing if too many consecutive failures (config likely null)
    if (_consecutiveFailures >= _maxConsecutiveFailures) {
      // Only log every 10th skip to avoid log spam
      if (_consecutiveFailures % 10 == 0) {
        _logger.w('⚠️ Skipping transcription — $_consecutiveFailures consecutive failures (config likely null)',
            category: LogCategory.speech);
      }
      _consecutiveFailures++;
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

      // Save audio to temporary WAV file for Nexa ASR
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/nexa_audio_${DateTime.now().millisecondsSinceEpoch}.wav');
      final wavBytes = _createWavFile(audioData, sampleRate: 16000, channels: 1, bitsPerSample: 16);
      await tempFile.writeAsBytes(wavBytes);

      try {
        // Transcribe using Nexa ASR
        final result = await _asrWrapper!.transcribe(
          AsrTranscribeInput(
            audioPath: tempFile.path,
            language: _config.language,
          ),
        );

        final transcription = result.result.transcript;
        _consecutiveFailures = 0; // Reset on success

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
      _consecutiveFailures++;
      _logger.e('❌ Error processing audio with Nexa ASR (failure #$_consecutiveFailures)',
          error: e, stackTrace: stackTrace, category: LogCategory.speech);

      if (_consecutiveFailures >= _maxConsecutiveFailures) {
        _logger.e('❌ Reached $_maxConsecutiveFailures consecutive failures — pausing transcription. '
            'SDK config may be null (model not fully loaded on NPU).',
            category: LogCategory.speech);
        _emitEvent(const NexaAsrEvent(
          progress: 0.0,
          message: 'ASR model not responding — waiting for NPU',
          error: 'Too many consecutive transcription failures',
        ));
      }

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

  /// Create a valid WAV file from raw PCM audio data.
  ///
  /// The Nexa SDK transcribe() expects a WAV file with a proper RIFF header.
  /// Without it, the SDK cannot determine the sample rate and fails with
  /// "Sample rate should be over 0".
  Uint8List _createWavFile(Uint8List pcmData, {
    required int sampleRate,
    required int channels,
    required int bitsPerSample,
  }) {
    final byteRate = sampleRate * channels * (bitsPerSample ~/ 8);
    final blockAlign = channels * (bitsPerSample ~/ 8);
    final dataSize = pcmData.length;
    final fileSize = 36 + dataSize; // 44-byte header minus 8 for RIFF chunk header

    final header = ByteData(44);
    // RIFF chunk descriptor
    header.setUint8(0, 0x52); // 'R'
    header.setUint8(1, 0x49); // 'I'
    header.setUint8(2, 0x46); // 'F'
    header.setUint8(3, 0x46); // 'F'
    header.setUint32(4, fileSize, Endian.little);
    header.setUint8(8, 0x57);  // 'W'
    header.setUint8(9, 0x41);  // 'A'
    header.setUint8(10, 0x56); // 'V'
    header.setUint8(11, 0x45); // 'E'
    // fmt sub-chunk
    header.setUint8(12, 0x66); // 'f'
    header.setUint8(13, 0x6D); // 'm'
    header.setUint8(14, 0x74); // 't'
    header.setUint8(15, 0x20); // ' '
    header.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    header.setUint16(20, 1, Endian.little);  // AudioFormat (1 = PCM)
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    // data sub-chunk
    header.setUint8(36, 0x64); // 'd'
    header.setUint8(37, 0x61); // 'a'
    header.setUint8(38, 0x74); // 't'
    header.setUint8(39, 0x61); // 'a'
    header.setUint32(40, dataSize, Endian.little);

    // Combine header + PCM data
    final wavFile = Uint8List(44 + dataSize);
    wavFile.setRange(0, 44, header.buffer.asUint8List());
    wavFile.setRange(44, 44 + dataSize, pcmData);
    return wavFile;
  }

  /// Run a warmup transcription with a short silent WAV file to verify the
  /// ASR model's internal config is ready. Returns true if the SDK processes
  /// the file without a "config is null" / "Sample rate should be over 0" error.
  Future<bool> _warmupAsr() async {
    if (_asrWrapper == null) return false;

    try {
      // Generate 0.1s of silence at 16kHz, 16-bit mono = 3200 bytes of PCM
      final silentPcm = Uint8List(3200); // all zeros = silence
      final wavBytes = _createWavFile(silentPcm,
          sampleRate: 16000, channels: 1, bitsPerSample: 16);

      final tempDir = await getTemporaryDirectory();
      final warmupFile = File('${tempDir.path}/nexa_warmup.wav');
      await warmupFile.writeAsBytes(wavBytes);

      try {
        _logger.d('🔄 Running ASR warmup transcription...', category: LogCategory.speech);
        final result = await _asrWrapper!.transcribe(
          AsrTranscribeInput(
            audioPath: warmupFile.path,
            language: 'en',
          ),
        );
        // If we get here without exception, the config is valid
        _logger.i('✅ ASR warmup succeeded: "${result.result.transcript}"',
            category: LogCategory.speech);
        return true;
      } finally {
        try { await warmupFile.delete(); } catch (_) {}
      }
    } catch (e) {
      _logger.w('⚠️ ASR warmup transcription failed: $e',
          category: LogCategory.speech);
      return false;
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
      // First, check the Nexa SDK's native download status — most reliable check
      // since the SDK tracks its own downloads in SharedPreferences.
      try {
        final nativeInstalled = await ModelDownloader.isModelDownloaded(modelName);
        if (nativeInstalled) {
          final nativePath = await ModelDownloader.getModelPath(modelName);
          if (nativePath != null) {
            _modelPath = nativePath;
            _logger.i('✅ Model $modelName verified via native SDK: $nativePath',
                category: LogCategory.speech);
            return true;
          }
        }
      } catch (e) {
        _logger.d('Native SDK check failed (non-fatal): $e');
      }

      final downloadManager = sl<UnifiedDownloadManager>();

      // Check if model is already installed
      if (await downloadManager.isModelInstalled(modelName)) {
        final path = await downloadManager.getModelPath(modelName);
        if (path != null) {
          // Verify model directory has weight files (not just metadata).
          // Also accept directories with 3+ files in case file names differ.
          final modelDir = path.endsWith('.nexa')
              ? path.substring(0, path.lastIndexOf('/'))
              : path;
          final dir = Directory(modelDir);
          if (await dir.exists()) {
            final files = await dir.list().toList();
            final weightFiles = files.where((f) =>
                f.path.contains('weights') && f.path.endsWith('.nexa')).toList();
            final hasEnoughFiles = files.length >= 3;
            final hasWeightFiles = weightFiles.isNotEmpty;
            if (!hasWeightFiles && !hasEnoughFiles) {
              _logger.w('⚠️ Model $modelName directory exists but has no weight files '
                  'and fewer than 3 total files — re-downloading',
                  category: LogCategory.speech);
            } else {
              _modelPath = path;
              _logger.i('✅ Model $modelName installed with ${weightFiles.length} weight '
                  'file(s), ${files.length} total files',
                  category: LogCategory.speech);
              return true;
            }
          }
        }
        // SharedPrefs says installed but files are missing — fall through to download
        _logger.w('⚠️ Model $modelName marked as installed but files invalid — re-downloading',
            category: LogCategory.speech);
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
