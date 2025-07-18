import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional imports to avoid dart:ffi on web
import 'whisper_service_impl.dart' if (dart.library.html) 'whisper_service_web.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:whisper_ggml/whisper_ggml.dart';
import '../models/speech_config.dart';
import '../models/speech_result.dart';
import 'debug_capturing_logger.dart';
import 'model_download_manager.dart';

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
  static final DebugCapturingLogger _logger = DebugCapturingLogger();
  
  bool _isInitialized = false;
  bool _isProcessing = false;
  SpeechConfig _config = const SpeechConfig();
  
  // Whisper GGML instance
  Whisper? _whisper;
  
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
    
    try {
      _config = config ?? const SpeechConfig();
      _logger.i('🔧 Initializing Whisper service with model: ${_config.whisperModel}');
      
      // Emit STT event for initialization start
      _sttEventController.add(const WhisperSTTEvent(
        progress: 0.0,
        message: 'Initializing Whisper service...',
      ));
      
      // Determine the model key based on the config
      final modelKey = 'whisper-${_config.whisperModel}';
      _logger.i('🔍 Looking for model: $modelKey');
      
      // Emit STT event for model checking
      _sttEventController.add(WhisperSTTEvent(
        progress: 0.2,
        message: 'Checking model availability...',
      ));
      
      // Check if model exists and is complete
      final modelExists = await _modelDownloadManager.modelExists(modelKey);
      final modelComplete = await _modelDownloadManager.modelIsComplete(modelKey);
      
      if (!modelExists || !modelComplete) {
        _logger.i('📥 Model not found or incomplete, downloading: $modelKey');
        
        // Emit STT event for model download start
        _sttEventController.add(WhisperSTTEvent(
          progress: 0.3,
          message: 'Downloading Whisper model...',
        ));
        
        // Check if model is currently downloading
        if (_modelDownloadManager.isDownloading(modelKey)) {
          _logger.i('⏳ Model is already downloading, waiting...');
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
          _logger.e('❌ Failed to download model: $error');
          
          // Emit STT event for model download failure
          _sttEventController.add(WhisperSTTEvent(
            progress: 0.0,
            message: 'Failed to download model: $error',
            error: error,
          ));
          
          throw Exception('Failed to download model: $error');
        }
        
        // Emit STT event for model download complete
        _sttEventController.add(WhisperSTTEvent(
          progress: 0.8,
          message: 'Model download complete',
        ));
      }
      
      // Get the model path
      final modelPath = await _modelDownloadManager.getModelPath(modelKey);
      final modelDir = Directory(modelPath).parent.path;
      
      _logger.i('📁 Using model from: $modelPath');
      
      // Emit STT event for model loading
      _sttEventController.add(WhisperSTTEvent(
        progress: 0.9,
        message: 'Loading Whisper model...',
      ));
      
      // Initialize Whisper with the specified model
      _whisper = Whisper(
        model: WhisperModel.values.firstWhere(
          (model) => model.name == _config.whisperModel,
          orElse: () => WhisperModel.base,
        ),
        modelDir: modelDir,
      );
      
      // Test the connection by getting version
      final version = await _whisper!.getVersion();
      _logger.i('📋 Whisper version: $version');
      
      _isInitialized = true;
      _logger.i('✅ Whisper service initialized successfully');
      
      // Emit STT event for initialization complete
      _sttEventController.add(const WhisperSTTEvent(
        progress: 1.0,
        message: 'Whisper service ready',
        isComplete: true,
      ));
      
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to initialize Whisper service', error: e, stackTrace: stackTrace);
      
      // Emit STT event for initialization failure
      _sttEventController.add(WhisperSTTEvent(
        progress: 0.0,
        message: 'Failed to initialize Whisper service',
        error: e,
      ));
      
      return false;
    }
  }
  
  /// Start processing audio data
  Future<bool> startProcessing() async {
    if (!_isInitialized) {
      _logger.w('⚠️ Whisper service not initialized');
      return false;
    }
    
    if (_isProcessing) {
      _logger.i('🔄 Whisper already processing');
      return true;
    }
    
    try {
      _isProcessing = true;
      _logger.i('🎤 Starting Whisper processing');
      
      // Emit STT event for processing start
      _sttEventController.add(const WhisperSTTEvent(
        progress: 0.0,
        message: 'Starting on-device STT...',
      ));
      
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to start Whisper processing', error: e, stackTrace: stackTrace);
      _isProcessing = false;
      
      // Emit STT event for processing start failure
      _sttEventController.add(WhisperSTTEvent(
        progress: 0.0,
        message: 'Failed to start STT processing',
        error: e,
      ));
      
      return false;
    }
  }
  
  /// Process audio buffer and return transcription
  Future<SpeechResult> processAudioBuffer(Uint8List audioData) async {
    if (!_isInitialized || _whisper == null) {
      _logger.w('⚠️ Whisper not initialized, returning fallback result');
      
      // Emit STT event for processing failure
      _sttEventController.add(const WhisperSTTEvent(
        progress: 0.0,
        message: 'Whisper not initialized',
        error: 'Service not initialized',
      ));
      
      return SpeechResult(
        text: "Whisper not initialized",
        confidence: 0.0,
        isFinal: true,
        timestamp: DateTime.now(),
      );
    }
    
    try {
      _logger.d('🎵 Processing audio buffer (${audioData.length} bytes)');
      
      // Emit STT event for processing start
      _sttEventController.add(const WhisperSTTEvent(
        progress: 0.3,
        message: 'Transcribing speech...',
      ));
      
      // Save audio data to a temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/whisper_audio_${DateTime.now().millisecondsSinceEpoch}.wav');
      await tempFile.writeAsBytes(audioData);
      
      // Emit STT event for audio preparation
      _sttEventController.add(const WhisperSTTEvent(
        progress: 0.5,
        message: 'Preparing audio for transcription...',
      ));
      
      // Create transcription request
      final transcribeRequest = TranscribeRequest(
        audio: tempFile.path,
        language: _config.language,
        isTranslate: _config.whisperTranslateToEnglish,
        isSpecialTokens: _config.whisperSuppressNonSpeechTokens,
        threads: 4, // Use 4 threads for processing
        isVerbose: false,
        isNoTimestamps: true, // We don't need timestamps for real-time
        isRealtime: true, // Enable real-time processing
      );
      
      // Emit STT event for transcription start
      _sttEventController.add(const WhisperSTTEvent(
        progress: 0.7,
        message: 'Processing with Whisper GGML...',
      ));
      
      // Process audio with Whisper GGML
      final response = await _whisper!.transcribe(
        transcribeRequest: transcribeRequest,
        modelPath: tempFile.path, // Use the temp file path
      );
      
      // Clean up temp file
      await tempFile.delete();
      
      final speechResult = SpeechResult(
        text: response.text,
        confidence: 0.8, // Whisper doesn't provide confidence, use default
        isFinal: true,
        timestamp: DateTime.now(),
      );
      
      _logger.d('📝 Whisper result: "${speechResult.text}" (confidence: ${speechResult.confidence})');
      
      // Emit STT event for processing complete
      _sttEventController.add(const WhisperSTTEvent(
        progress: 1.0,
        message: 'STT complete',
        isComplete: true,
      ));
      
      // Emit the result
      _speechResultController.add(speechResult);
      
      return speechResult;
    } catch (e, stackTrace) {
      _logger.e('❌ Error processing audio with Whisper', error: e, stackTrace: stackTrace);
      
      // Emit STT event for processing error
      _sttEventController.add(WhisperSTTEvent(
        progress: 0.0,
        message: 'Error processing audio',
        error: e,
      ));
      
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
  
  /// Update configuration
  Future<void> updateConfig(SpeechConfig config) async {
    _config = config;
    _logger.i('⚙️ Updated Whisper configuration');
    
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
      _isProcessing = false;
      _logger.i('🛑 Stopped Whisper processing');
      
      // Emit STT event for processing stop
      _sttEventController.add(const WhisperSTTEvent(
        progress: 0.0,
        message: 'STT processing stopped',
      ));
    } catch (e, stackTrace) {
      _logger.e('❌ Error stopping Whisper processing', error: e, stackTrace: stackTrace);
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
      _logger.i('🗑️ Whisper service disposed');
    } catch (e, stackTrace) {
      _logger.e('❌ Error disposing Whisper service', error: e, stackTrace: stackTrace);
    }
  }
} 