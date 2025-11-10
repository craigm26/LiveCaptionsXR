import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

// Platform-specific imports
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/speech_config.dart';
import '../models/speech_result.dart';
import 'app_logger.dart';
import 'model_download_manager.dart';

// Only import whisper_ggml on non-web platforms
import 'package:whisper_ggml/whisper_ggml.dart'
    if (dart.library.html) 'whisper_ggml_web_stub.dart';

/// Event class for Whisper STT progress and status
class WhisperSTTEvent {
  final double progress; // 0.0 to 1.0
  final String message;
  final bool isComplete;
  final Object? error;

  const WhisperSTTEvent({
    required this.progress,
    required this.message,
    this.isComplete = false,
    this.error,
  });
}

/// Service for handling Whisper GGML speech-to-text processing
class WhisperService {
  static final AppLogger _logger = AppLogger.instance;

  bool _isInitialized = false;
  bool _isProcessing = false;
  SpeechConfig _config = const SpeechConfig();

  // Whisper GGML instance
  Whisper? _whisper;
  String? _modelPath;
  static const int _maxQueueSize = 24;
  final Queue<_PendingWhisperRequest> _pendingRequests = Queue();
  bool _isQueueDraining = false;
  DateTime? _lastQueueDropWarningAt;

  // Model download manager
  final ModelDownloadManager _modelDownloadManager;

  final StreamController<SpeechResult> _speechResultController =
      StreamController<SpeechResult>.broadcast();

  // New: STT progress event stream for AR session integration
  final StreamController<WhisperSTTEvent> _sttEventController =
      StreamController<WhisperSTTEvent>.broadcast();

  Stream<SpeechResult> get speechResults => _speechResultController.stream;

  // New: Expose STT events stream
  Stream<WhisperSTTEvent> get sttEvents => _sttEventController.stream;

  bool get isInitialized => _isInitialized;
  bool get isProcessing => _isProcessing;

  WhisperService({ModelDownloadManager? modelDownloadManager})
      : _modelDownloadManager = modelDownloadManager ?? ModelDownloadManager();

  /// Initialize the Whisper service with configuration
  Future<bool> initialize({SpeechConfig? config}) async {
    if (_isInitialized) return true;

    // Check if we're on web platform
    if (kIsWeb) {
      _logger.w(
        '⚠️ Web platform detected - Whisper service not available',
        category: LogCategory.speech,
      );
      _logger.w(
        '⚠️ Using fallback mode for web builds',
        category: LogCategory.speech,
      );
      _isInitialized = true;
      return true;
    }

    try {
      _config = config ?? const SpeechConfig();
      _logger.i(
        '🔧 Initializing Whisper service with model: ${_config.whisperModel}',
        category: LogCategory.speech,
      );

      // Emit STT event for initialization start
      _sttEventController.add(
        const WhisperSTTEvent(
          progress: 0.0,
          message: 'Initializing Whisper service...',
        ),
      );

      // Determine the model key based on the config
      final modelKey = 'whisper-${_config.whisperModel}';
      _logger.i(
        '🔍 Looking for model: $modelKey',
        category: LogCategory.speech,
      );

      // Emit STT event for model checking
      _sttEventController.add(
        WhisperSTTEvent(
          progress: 0.2,
          message: 'Checking model availability...',
        ),
      );

      // Check if model exists and is complete
      final modelExists = await _modelDownloadManager.modelExists(modelKey);
      final modelComplete = await _modelDownloadManager.modelIsComplete(
        modelKey,
      );

      if (!modelExists || !modelComplete) {
        _logger.i(
          '📥 Model not found or incomplete, downloading: $modelKey',
          category: LogCategory.speech,
        );

        // Emit STT event for model download start
        _sttEventController.add(
          WhisperSTTEvent(
            progress: 0.3,
            message: 'Downloading Whisper model...',
          ),
        );

        // Check if model is currently downloading
        if (_modelDownloadManager.isDownloading(modelKey)) {
          _logger.i(
            '⏳ Model is already downloading, waiting...',
            category: LogCategory.speech,
          );
          // Wait for download to complete
          while (_modelDownloadManager.isDownloading(modelKey)) {
            await Future.delayed(const Duration(seconds: 1));
          }
        } else {
          // Start download
          await _modelDownloadManager.downloadModel(modelKey);
        }

        // Check if download was successful
        if (!await _modelDownloadManager.modelIsComplete(modelKey)) {
          final error = _modelDownloadManager.getError(modelKey);
          _logger.e(
            '❌ Failed to download model: $error',
            category: LogCategory.speech,
          );

          // Emit STT event for model download failure
          _sttEventController.add(
            WhisperSTTEvent(
              progress: 0.0,
              message: 'Failed to download model: $error',
              error: error,
            ),
          );

          throw Exception('Failed to download model: $error');
        }

        // Emit STT event for model download complete
        _sttEventController.add(
          WhisperSTTEvent(progress: 0.8, message: 'Model download complete'),
        );
      }

      // Get the model path
      final modelPath = await _modelDownloadManager.getModelPath(modelKey);
      final modelDir = Directory(modelPath).parent.path;
      _modelPath = modelPath;

      _logger.i(
        '📁 Using model from: $modelPath',
        category: LogCategory.speech,
      );
      _logger.i('📁 Model directory: $modelDir', category: LogCategory.speech);

      // Check if the expected model file exists
      final expectedModelFile = File('$modelDir/ggml-base.bin');
      _logger.i(
        '📁 Expected model file exists: ${await expectedModelFile.exists()}',
        category: LogCategory.speech,
      );

      // Emit STT event for model loading
      _sttEventController.add(
        WhisperSTTEvent(progress: 0.9, message: 'Loading Whisper model...'),
      );

      // Initialize Whisper with the specified model
      try {
        _whisper = Whisper(
          model: WhisperModel.values.firstWhere(
            (model) => model.name == _config.whisperModel,
            orElse: () => WhisperModel.base,
          ),
          modelDir: modelDir,
        );

        // Test the connection by getting version
        final version = await _whisper!.getVersion();
        _logger.i('📋 Whisper version: $version', category: LogCategory.speech);
      } catch (nativeError) {
        _logger.e(
          '❌ Native Whisper GGML initialization failed: $nativeError',
          category: LogCategory.speech,
        );
        _logger.w(
          '⚠️ Whisper service will run in fallback mode',
          category: LogCategory.speech,
        );

        // Set whisper to null but keep _isInitialized as true for fallback mode
        _whisper = null;
        _isInitialized = true;

        // Emit STT event for fallback mode
        _sttEventController.add(
          const WhisperSTTEvent(
            progress: 1.0,
            message: 'Whisper service ready (fallback mode)',
            isComplete: true,
          ),
        );

        return true;
      }

      _isInitialized = true;
      _logger.i(
        '✅ Whisper service initialized successfully',
        category: LogCategory.speech,
      );

      // Emit STT event for initialization complete
      _sttEventController.add(
        const WhisperSTTEvent(
          progress: 1.0,
          message: 'Whisper service ready',
          isComplete: true,
        ),
      );

      return true;
    } catch (e, stackTrace) {
      _logger.e(
        '❌ Failed to initialize Whisper service',
        category: LogCategory.speech,
        error: e,
        stackTrace: stackTrace,
      );

      // Emit STT event for initialization failure
      _sttEventController.add(
        WhisperSTTEvent(
          progress: 0.0,
          message: 'Failed to initialize Whisper service',
          error: e,
        ),
      );

      return false;
    }
  }

  /// Start processing audio data
  Future<bool> startProcessing() async {
    if (!_isInitialized) {
      _logger.w(
        '⚠️ Whisper service not initialized',
        category: LogCategory.speech,
      );
      return false;
    }

    if (_isProcessing) {
      _logger.i('🔄 Whisper already processing', category: LogCategory.speech);
      return true;
    }

    try {
      _isProcessing = true;
      _logger.i('🎤 Starting Whisper processing', category: LogCategory.speech);

      // Emit STT event for processing start
      _sttEventController.add(
        const WhisperSTTEvent(
          progress: 0.0,
          message: 'Starting on-device STT...',
        ),
      );

      return true;
    } catch (e, stackTrace) {
      _logger.e(
        '❌ Failed to start Whisper processing',
        category: LogCategory.speech,
        error: e,
        stackTrace: stackTrace,
      );
      _isProcessing = false;

      // Emit STT event for processing start failure
      _sttEventController.add(
        WhisperSTTEvent(
          progress: 0.0,
          message: 'Failed to start STT processing',
          error: e,
        ),
      );

      return false;
    }
  }

  /// Core audio processing pipeline (single threaded)
  Future<SpeechResult> _processAudioBufferInternal(Uint8List audioData) async {
    // Handle web platform
    if (kIsWeb) {
      _logger.w(
        '⚠️ Web platform detected - returning demo result',
        category: LogCategory.speech,
      );
      return SpeechResult(
        text: 'Web Demo: Audio processing not available',
        confidence: 0.0,
        isFinal: true,
        timestamp: DateTime.now(),
      );
    }

    if (!_isInitialized) {
      _logger.w(
        '⚠️ Whisper not initialized, returning fallback result',
        category: LogCategory.speech,
      );

      // Emit STT event for processing failure
      _sttEventController.add(
        const WhisperSTTEvent(
          progress: 0.0,
          message: 'Whisper not initialized',
          error: 'Service not initialized',
        ),
      );

      return SpeechResult(
        text: "Whisper not initialized",
        confidence: 0.0,
        isFinal: true,
        timestamp: DateTime.now(),
      );
    }

    // If Whisper GGML native library failed to load, provide a fallback
    if (_whisper == null) {
      _logger.w(
        '⚠️ Whisper GGML native library not available, using fallback',
        category: LogCategory.speech,
      );

      // Emit STT event for fallback processing
      _sttEventController.add(
        const WhisperSTTEvent(
          progress: 0.5,
          message: 'Processing with fallback STT...',
        ),
      );

      // Simple fallback: return placeholder text based on audio length
      final String fallbackText;
      if (audioData.length < 1000) {
        fallbackText = "[Short audio detected]";
      } else if (audioData.length < 5000) {
        fallbackText = "[Speech detected - STT unavailable]";
      } else {
        fallbackText = "[Long speech detected - STT unavailable]";
      }

      final fallbackResult = SpeechResult(
        text: fallbackText,
        confidence: 0.3,
        isFinal: true,
        timestamp: DateTime.now(),
      );

      // Emit STT event for fallback complete
      _sttEventController.add(
        const WhisperSTTEvent(
          progress: 1.0,
          message: 'Fallback STT complete',
          isComplete: true,
        ),
      );

      _speechResultController.add(fallbackResult);
      return fallbackResult;
    }

    try {
      _logger.d(
        '🎵 Processing audio buffer (${audioData.length} bytes)',
        category: LogCategory.speech,
      );

      // Emit STT event for processing start
      _sttEventController.add(
        const WhisperSTTEvent(progress: 0.3, message: 'Transcribing speech...'),
      );

      // Ensure temporary directory exists
      final tempDir = await getTemporaryDirectory();
      final whisperDir = Directory('${tempDir.path}/whisper_cache');
      if (!await whisperDir.exists()) {
        await whisperDir.create(recursive: true);
        _logger.d(
          '📁 Created whisper cache directory: ${whisperDir.path}',
          category: LogCategory.speech,
        );
      }

      // Convert raw PCM16 data to WAV format
      final wavBytes = _wrapPcmAsWav(
        pcmBytes: audioData,
        sampleRate: 16000,
        channels: 1,
        bitsPerSample: 16,
      );

      // Save audio data to a temporary file inside the cache directory
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('${whisperDir.path}/whisper_audio_$timestamp.wav');
      await tempFile.writeAsBytes(wavBytes, flush: true);
      _logger.d(
        '💾 Saved audio to temp file: ${tempFile.path} (${tempFile.lengthSync()} bytes)',
        category: LogCategory.speech,
      );

      // Emit STT event for audio preparation
      _sttEventController.add(
        const WhisperSTTEvent(
          progress: 0.5,
          message: 'Preparing audio for transcription...',
        ),
      );

      // Create transcription request
      final transcribeRequest = TranscribeRequest(
        audio: tempFile.path,
        language: _config.language,
        isTranslate: _config.whisperTranslateToEnglish,
        isSpecialTokens: _config.whisperSuppressNonSpeechTokens,
        threads: 4, // Use 4 threads for processing
        isVerbose: false,
        isNoTimestamps: true, // We don't need timestamps for real-time
      );

      _logger.d(
        '🎤 Sending transcription request to Whisper GGML...',
        category: LogCategory.speech,
      );

      // Emit STT event for transcription start
      _sttEventController.add(
        const WhisperSTTEvent(
          progress: 0.7,
          message: 'Processing with Whisper GGML...',
        ),
      );

      _logger.d(
        '⚙️ Whisper.transcribe starting with audio file: ${tempFile.path}',
        category: LogCategory.speech,
      );
      // Process audio with Whisper GGML
      if (_modelPath == null) {
        _logger.e(
          '❌ Whisper model path not set before transcription',
          category: LogCategory.speech,
        );
        throw StateError('Whisper model path is not initialized');
      }

      final response = await _whisper!.transcribe(
        transcribeRequest: transcribeRequest,
        modelPath: _modelPath!,
      );
      _logger.d(
        '✅ Whisper.transcribe completed for: ${tempFile.path}',
        category: LogCategory.speech,
      );

      _logger.d(
        '📝 Whisper GGML response received: "${response.text}"',
        category: LogCategory.speech,
      );

      // Clean up temp file
      await tempFile.delete();
      _logger.d(
        '🗑️ Cleaned up temp audio file: ${tempFile.path}',
        category: LogCategory.speech,
      );

      final speechResult = SpeechResult(
        text: response.text,
        confidence: 0.8, // Whisper doesn't provide confidence, use default
        isFinal: true,
        timestamp: DateTime.now(),
      );

      _logger.i(
        '📝 Whisper result: "${speechResult.text}" (confidence: ${speechResult.confidence})',
        category: LogCategory.speech,
      );

      // Emit STT event for processing complete
      _sttEventController.add(
        const WhisperSTTEvent(
          progress: 1.0,
          message: 'STT complete',
          isComplete: true,
        ),
      );

      // Emit the result
      _speechResultController.add(speechResult);
      _logger.d(
        '📤 Emitted speech result to stream',
        category: LogCategory.speech,
      );

      return speechResult;
    } catch (e, stackTrace) {
      _logger.e(
        '❌ Error processing audio with Whisper',
        category: LogCategory.speech,
        error: e,
        stackTrace: stackTrace,
      );

      // Emit STT event for processing error
      _sttEventController.add(
        WhisperSTTEvent(
          progress: 0.0,
          message: 'Error processing audio',
          error: e,
        ),
      );

      final fallbackResult = SpeechResult(
        text: "Error processing audio",
        confidence: 0.0,
        isFinal: true,
        timestamp: DateTime.now(),
      );

      _speechResultController.add(fallbackResult);
      return fallbackResult;
    }
  }

  /// Process audio buffer and enqueue it for serialized handling
  Future<SpeechResult> processAudioBuffer(Uint8List audioData) {
    if (!_isProcessing) {
      _logger.w(
        '?? Received audio while Whisper processing is stopped - dropping chunk',
        category: LogCategory.speech,
      );
      return Future.value(
        SpeechResult(
          text: '',
          confidence: 0.0,
          isFinal: false,
          timestamp: DateTime.now(),
        ),
      );
    }

    if (audioData.isEmpty) {
      _logger.w(
        '?? Ignoring empty audio buffer sent to Whisper queue',
        category: LogCategory.speech,
      );
      return Future.value(
        SpeechResult(
          text: '',
          confidence: 0.0,
          isFinal: false,
          timestamp: DateTime.now(),
        ),
      );
    }

    if (_pendingRequests.length >= _maxQueueSize) {
      final dropped = _pendingRequests.removeFirst();
      if (!dropped.completer.isCompleted) {
        dropped.completer.complete(
          SpeechResult(
            text: '',
            confidence: 0.0,
            isFinal: false,
            timestamp: DateTime.now(),
          ),
        );
      }

      final now = DateTime.now();
      final shouldLog = _lastQueueDropWarningAt == null ||
          now.difference(_lastQueueDropWarningAt!) > const Duration(seconds: 5);
      if (shouldLog) {
        _lastQueueDropWarningAt = now;
        _logger.i(
          '⏳ Whisper queue saturated - dropping oldest pending chunk to maintain responsiveness',
          category: LogCategory.speech,
        );
      }
    }

    final completer = Completer<SpeechResult>();
    _pendingRequests.add(
      _PendingWhisperRequest(Uint8List.fromList(audioData), completer),
    );
    _drainAudioQueue();
    return completer.future;
  }

  /// Update configuration
  Future<void> updateConfig(SpeechConfig config) async {
    _config = config;
    _logger.i('⚙️ Updated Whisper configuration', category: LogCategory.speech);

    // Reinitialize if already initialized
    if (_isInitialized) {
      await dispose();
      await initialize(config: config);
    }
  }

  /// Stop processing
  Future<void> stopProcessing() async {
    if (!_isProcessing) return;

    try {
      while (_pendingRequests.isNotEmpty) {
        final pending = _pendingRequests.removeFirst();
        if (!pending.completer.isCompleted) {
          pending.completer.completeError(
            StateError('Whisper processing stopped before completion'),
          );
        }
      }
      _isQueueDraining = false;
      _isProcessing = false;
      _logger.i('?? Stopped Whisper processing', category: LogCategory.speech);

      // Emit STT event for processing stop
      _sttEventController.add(
        const WhisperSTTEvent(progress: 0.0, message: 'STT processing stopped'),
      );
    } catch (e, stackTrace) {
      _logger.e(
        '? Error stopping Whisper processing',
        category: LogCategory.speech,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      await stopProcessing();
      _whisper = null;
      await _speechResultController.close();
      await _sttEventController.close();
      _isInitialized = false;
      _logger.i('🗑️ Whisper service disposed', category: LogCategory.speech);
    } catch (e, stackTrace) {
      _logger.e(
        '❌ Error disposing Whisper service',
        category: LogCategory.speech,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _drainAudioQueue() {
    if (_isQueueDraining || _pendingRequests.isEmpty) {
      return;
    }
    _isQueueDraining = true;
    Future<void>(() async {
      while (true) {
        _PendingWhisperRequest? request;
        if (_pendingRequests.isEmpty) {
          _isQueueDraining = false;
          if (_pendingRequests.isEmpty) {
            break;
          }
          _isQueueDraining = true;
          continue;
        } else {
          request = _pendingRequests.removeFirst();
        }

        try {
          final result = await _processAudioBufferInternal(request.audioData);
          if (!request.completer.isCompleted) {
            request.completer.complete(result);
          }
        } catch (e, stackTrace) {
          if (!request.completer.isCompleted) {
            request.completer.completeError(e, stackTrace);
          }
        }
      }
      _isQueueDraining = false;
    });
  }

  Uint8List _wrapPcmAsWav({
    required Uint8List pcmBytes,
    required int sampleRate,
    required int channels,
    required int bitsPerSample,
  }) {
    final byteRate = sampleRate * channels * (bitsPerSample ~/ 8);
    final blockAlign = channels * (bitsPerSample ~/ 8);
    final dataSize = pcmBytes.lengthInBytes;
    final totalSize = 36 + dataSize;

    final buffer = BytesBuilder();
    buffer.add(ascii.encode('RIFF'));
    buffer.add(_intToBytes(totalSize, 4));
    buffer.add(ascii.encode('WAVE'));
    buffer.add(ascii.encode('fmt '));
    buffer.add(_intToBytes(16, 4)); // PCM chunk size
    buffer.add(_intToBytes(1, 2)); // Audio format (1 = PCM)
    buffer.add(_intToBytes(channels, 2));
    buffer.add(_intToBytes(sampleRate, 4));
    buffer.add(_intToBytes(byteRate, 4));
    buffer.add(_intToBytes(blockAlign, 2));
    buffer.add(_intToBytes(bitsPerSample, 2));
    buffer.add(ascii.encode('data'));
    buffer.add(_intToBytes(dataSize, 4));
    buffer.add(pcmBytes);

    return buffer.toBytes();
  }

  Uint8List _intToBytes(int value, int byteCount) {
    final bytes = ByteData(byteCount);
    if (byteCount == 2) {
      bytes.setInt16(0, value, Endian.little);
    } else if (byteCount == 4) {
      bytes.setInt32(0, value, Endian.little);
    } else {
      throw ArgumentError('Unsupported byteCount: $byteCount');
    }
    return bytes.buffer.asUint8List();
  }
}

class _PendingWhisperRequest {
  final Uint8List audioData;
  final Completer<SpeechResult> completer;

  _PendingWhisperRequest(this.audioData, this.completer);
}
