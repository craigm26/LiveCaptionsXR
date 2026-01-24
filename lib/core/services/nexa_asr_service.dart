import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';

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
/// For the Qualcomm x Nexa On-Device AI Bounty Program.
class NexaAsrService {
  static final AppLogger _logger = AppLogger.instance;

  static const MethodChannel _methodChannel =
      MethodChannel('live_captions_xr/nexa_asr');
  static const EventChannel _eventChannel =
      EventChannel('live_captions_xr/nexa_asr_events');

  bool _isInitialized = false;
  bool _isProcessing = false;
  SpeechConfig _config = const SpeechConfig();
  NexaInferenceMode _inferenceMode = NexaInferenceMode.cpu;
  NexaDeviceInfo? _deviceInfo;

  StreamSubscription? _eventSubscription;

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
      final result = await _methodChannel.invokeMethod<bool>('isNpuAvailable');
      return result ?? false;
    } catch (e) {
      _logger.e('Failed to check NPU availability', error: e);
      return false;
    }
  }

  /// Get device information
  Future<NexaDeviceInfo?> getDeviceInfo() async {
    if (!Platform.isAndroid) return null;

    try {
      final result =
          await _methodChannel.invokeMethod<Map<dynamic, dynamic>>('getDeviceInfo');
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

      // Start listening to native events
      _startEventListening();

      _logger.i('🚀 Initializing Nexa ASR service (preferNpu: $preferNpu)');

      final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'initialize',
        {
          'modelPath': modelPath,
          'preferNpu': preferNpu,
        },
      );

      if (result != null && result['success'] == true) {
        _isInitialized = true;
        _inferenceMode = _parseInferenceMode(result['inferenceMode'] as String?);

        _logger.i(
            '✅ Nexa ASR initialized with ${_inferenceMode.name.toUpperCase()} acceleration');

        _emitEvent(NexaAsrEvent(
          progress: 1.0,
          message: 'Nexa ASR ready (${_inferenceMode.name.toUpperCase()})',
          isComplete: true,
        ));

        // Get device info for analytics
        await getDeviceInfo();

        return true;
      } else {
        throw Exception('Initialization returned failure');
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to initialize Nexa ASR',
          error: e, stackTrace: stackTrace);

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
    if (!_isInitialized) {
      _logger.w('Nexa ASR not initialized');
      return false;
    }

    if (_isProcessing) {
      _logger.i('Nexa ASR already processing');
      return true;
    }

    try {
      _emitEvent(const NexaAsrEvent(
        progress: 0.0,
        message: 'Starting Nexa ASR streaming...',
      ));

      final result = await _methodChannel
          .invokeMethod<Map<dynamic, dynamic>>('startStreaming');

      if (result != null && result['success'] == true) {
        _isProcessing = true;
        _logger.i('🎤 Nexa ASR streaming started');
        return true;
      } else {
        throw Exception('Failed to start streaming');
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to start Nexa ASR processing',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Process audio buffer and return transcription
  Future<SpeechResult> processAudioBuffer(Uint8List audioData) async {
    if (!_isInitialized) {
      _logger.w('Nexa ASR not initialized, returning fallback result');

      _emitEvent(const NexaAsrEvent(
        progress: 0.0,
        message: 'Nexa ASR not initialized',
        error: 'Service not initialized',
      ));

      return SpeechResult(
        text: 'Nexa ASR not initialized',
        confidence: 0.0,
        isFinal: true,
        timestamp: DateTime.now(),
      );
    }

    try {
      _logger.d('🎵 Processing audio buffer (${audioData.length} bytes) with Nexa ASR');

      _emitEvent(const NexaAsrEvent(
        progress: 0.3,
        message: 'Transcribing with Nexa ASR...',
      ));

      final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'transcribe',
        {
          'audioData': audioData,
          'sampleRate': 16000,
        },
      );

      if (result != null) {
        final speechResult = SpeechResult(
          text: result['text'] as String? ?? '',
          confidence: (result['confidence'] as num?)?.toDouble() ?? 0.0,
          isFinal: true,
          timestamp: DateTime.now(),
        );

        _logger.d(
            '📝 Nexa ASR result: "${speechResult.text}" (confidence: ${speechResult.confidence})');

        _emitEvent(NexaAsrEvent(
          progress: 1.0,
          message: 'Transcription complete',
          isComplete: true,
          transcription: speechResult.text,
        ));

        _speechResultController.add(speechResult);
        return speechResult;
      } else {
        throw Exception('Transcription returned null');
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Error processing audio with Nexa ASR',
          error: e, stackTrace: stackTrace);

      _emitEvent(NexaAsrEvent(
        progress: 0.0,
        message: 'Error processing audio',
        error: e,
      ));

      final fallbackResult = SpeechResult(
        text: 'Error processing audio with Nexa ASR',
        confidence: 0.0,
        isFinal: true,
        timestamp: DateTime.now(),
      );

      _speechResultController.add(fallbackResult);
      return fallbackResult;
    }
  }

  /// Process audio chunk during streaming mode
  Future<SpeechResult?> processAudioChunk(Uint8List audioData) async {
    if (!_isProcessing) {
      _logger.w('Nexa ASR not in streaming mode');
      return null;
    }

    try {
      final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'processAudioChunk',
        {'audioData': audioData},
      );

      if (result != null && (result['text'] as String?)?.isNotEmpty == true) {
        final speechResult = SpeechResult(
          text: result['text'] as String,
          confidence: (result['confidence'] as num?)?.toDouble() ?? 0.0,
          isFinal: result['isFinal'] as bool? ?? false,
          timestamp: DateTime.now(),
        );

        _speechResultController.add(speechResult);
        return speechResult;
      }

      return null;
    } catch (e) {
      _logger.e('Error processing audio chunk', error: e);
      return null;
    }
  }

  /// Stop processing
  Future<void> stopProcessing() async {
    if (!_isProcessing) return;

    try {
      await _methodChannel.invokeMethod('stopStreaming');
      _isProcessing = false;
      _logger.i('🛑 Stopped Nexa ASR processing');

      _emitEvent(const NexaAsrEvent(
        progress: 0.0,
        message: 'Nexa ASR processing stopped',
      ));
    } catch (e, stackTrace) {
      _logger.e('Error stopping Nexa ASR processing',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      await stopProcessing();
      await _eventSubscription?.cancel();

      if (Platform.isAndroid) {
        await _methodChannel.invokeMethod('dispose');
      }

      await _speechResultController.close();
      await _sttEventController.close();
      await _nexaEventController.close();

      _isInitialized = false;
      _logger.i('🗑️ Nexa ASR service disposed');
    } catch (e, stackTrace) {
      _logger.e('Error disposing Nexa ASR service',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Start listening to native events
  void _startEventListening() {
    _eventSubscription = _eventChannel
        .receiveBroadcastStream()
        .listen(_handleNativeEvent, onError: _handleNativeError);
  }

  /// Handle native events from Nexa SDK
  void _handleNativeEvent(dynamic event) {
    if (event is Map) {
      final type = event['type'] as String?;
      final data = event['data'] as Map<dynamic, dynamic>?;

      _logger.d('Nexa ASR event: $type');

      switch (type) {
        case 'status':
          _emitEvent(NexaAsrEvent(
            progress: (data?['progress'] as num?)?.toDouble() ?? 0.0,
            message: data?['message'] as String? ?? '',
            isComplete: data?['isComplete'] as bool? ?? false,
          ));
          break;

        case 'transcription':
          final text = data?['text'] as String? ?? '';
          final confidence = (data?['confidence'] as num?)?.toDouble() ?? 0.0;

          final speechResult = SpeechResult(
            text: text,
            confidence: confidence,
            isFinal: true,
            timestamp: DateTime.now(),
          );

          _speechResultController.add(speechResult);
          _emitEvent(NexaAsrEvent(
            progress: 1.0,
            message: 'Transcription received',
            isComplete: true,
            transcription: text,
          ));
          break;

        case 'partialResult':
          final text = data?['text'] as String? ?? '';
          if (text.isNotEmpty) {
            final speechResult = SpeechResult(
              text: text,
              confidence: (data?['confidence'] as num?)?.toDouble() ?? 0.0,
              isFinal: data?['isFinal'] as bool? ?? false,
              timestamp: DateTime.now(),
            );
            _speechResultController.add(speechResult);
          }
          break;

        case 'error':
          _emitEvent(NexaAsrEvent(
            progress: 0.0,
            message: data?['message'] as String? ?? 'Unknown error',
            error: data?['message'],
          ));
          break;
      }
    }
  }

  /// Handle native errors
  void _handleNativeError(dynamic error) {
    _logger.e('Nexa ASR native error', error: error);
    _emitEvent(NexaAsrEvent(
      progress: 0.0,
      message: 'Native error occurred',
      error: error,
    ));
  }

  /// Emit event to all streams
  void _emitEvent(NexaAsrEvent event) {
    _nexaEventController.add(event);
    _sttEventController.add(event.toWhisperSTTEvent());
  }

  /// Parse inference mode from string
  NexaInferenceMode _parseInferenceMode(String? mode) {
    switch (mode?.toUpperCase()) {
      case 'NPU':
        return NexaInferenceMode.npu;
      case 'GPU':
        return NexaInferenceMode.gpu;
      default:
        return NexaInferenceMode.cpu;
    }
  }
}
