import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
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
/// 
/// On web platforms, this provides demo functionality since whisper_ggml
/// uses dart:ffi which is not available on web.
class WhisperService {
  static final DebugCapturingLogger _logger = DebugCapturingLogger();
  
  bool _isInitialized = false;
  bool _isProcessing = false;
  SpeechConfig _config = const SpeechConfig();
  
  // Model download manager (optional for demo mode)
  final ModelDownloadManager? _modelDownloadManager;
  
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
      : _modelDownloadManager = modelDownloadManager;
  
  /// Initialize the Whisper service with configuration
  Future<bool> initialize({SpeechConfig? config}) async {
    if (_isInitialized) return true;
    
    try {
      _config = config ?? const SpeechConfig();
      
      // Emit STT event for initialization start
      _sttEventController.add(const WhisperSTTEvent(
        progress: 0.0,
        message: 'Initializing Whisper service...',
      ));
      
      if (kIsWeb) {
        // Web demo mode
        _logger.i('🔧 Initializing Whisper service (Web Demo Mode)');
        await Future.delayed(const Duration(milliseconds: 100));
        _isInitialized = true;
        _logger.i('✅ Whisper service initialized (Web Demo Mode)');
        
        // Emit STT event for initialization complete
        _sttEventController.add(const WhisperSTTEvent(
          progress: 1.0,
          message: 'Whisper service ready (Web Demo Mode)',
          isComplete: true,
        ));
        
        return true;
      } else {
        // Native implementation - check for model download manager
        _logger.i('🔧 Initializing Whisper service with model: ${_config.whisperModel}');
        
        if (_modelDownloadManager != null) {
          // Use model download manager if available
          final modelKey = 'whisper-${_config.whisperModel}';
          _logger.i('🔍 Checking model availability: $modelKey');
          
          // Emit STT event for model checking
          _sttEventController.add(WhisperSTTEvent(
            progress: 0.2,
            message: 'Checking model availability...',
          ));
          
          final modelExists = await _modelDownloadManager!.modelExists(modelKey);
          final modelComplete = await _modelDownloadManager!.modelIsComplete(modelKey);
          
          if (!modelExists || !modelComplete) {
            _logger.i('📥 Model not found or incomplete, downloading: $modelKey');
            
            // Emit STT event for model download start
            _sttEventController.add(WhisperSTTEvent(
              progress: 0.3,
              message: 'Downloading Whisper model...',
            ));
            
            if (_modelDownloadManager!.isDownloading(modelKey)) {
              _logger.i('⏳ Model is already downloading, waiting...');
              while (_modelDownloadManager!.isDownloading(modelKey)) {
                await Future.delayed(const Duration(seconds: 1));
              }
            } else {
              await _modelDownloadManager!.downloadModel(modelKey);
            }
            
            if (!await _modelDownloadManager!.modelIsComplete(modelKey)) {
              final error = _modelDownloadManager!.getError(modelKey);
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
          
          _logger.i('✅ Model ready: $modelKey');
        } else {
          _logger.w('⚠️ Model download manager not available, using demo mode');
        }
        
        _isInitialized = true;
        _logger.i('✅ Whisper service initialized (Demo Mode with Model Download)');
        
        // Emit STT event for initialization complete
        _sttEventController.add(const WhisperSTTEvent(
          progress: 1.0,
          message: 'Whisper service ready',
          isComplete: true,
        ));
        
        return true;
      }
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
      
      // Emit STT event for processing start
      _sttEventController.add(const WhisperSTTEvent(
        progress: 0.0,
        message: 'Starting on-device STT...',
      ));
      
      if (kIsWeb) {
        _logger.i('🎤 Starting Whisper processing (Web Demo Mode)');
      } else {
        _logger.i('🎤 Starting Whisper processing (Demo Mode)');
      }
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
    if (!_isInitialized) {
      _logger.w('⚠️ Whisper not initialized, returning fallback result');
      
      // Emit STT event for processing failure
      _sttEventController.add(const WhisperSTTEvent(
        progress: 0.0,
        message: 'Whisper not initialized',
        error: 'Service not initialized',
      ));
      
      return SpeechResult(
        text: kIsWeb ? "Whisper not initialized (Web Demo)" : "Whisper not initialized (Demo)",
        confidence: 0.0,
        isFinal: true,
        timestamp: DateTime.now(),
      );
    }
    
    try {
      _logger.d('🎵 Processing audio buffer (${audioData.length} bytes)${kIsWeb ? ' - Web Demo Mode' : ' - Demo Mode'}');
      
      // Emit STT event for processing start
      _sttEventController.add(const WhisperSTTEvent(
        progress: 0.3,
        message: 'Transcribing speech...',
      ));
      
      // Simulate processing delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Emit STT event for processing progress
      _sttEventController.add(const WhisperSTTEvent(
        progress: 0.7,
        message: 'Processing audio...',
      ));
      
      // Return demo transcription based on audio buffer size
      String demoText;
      if (audioData.length > 1000) {
        if (kIsWeb) {
          demoText = "Hello, this is a web demo of LiveCaptionsXR. Whisper GGML is not available on web platforms.";
        } else {
          demoText = "Hello, this is a demo of LiveCaptionsXR. Whisper GGML is available on native platforms.";
        }
      } else if (audioData.length > 500) {
        demoText = kIsWeb ? "Web demo mode - speech recognition simulated." : "Demo mode - speech recognition simulated.";
      } else {
        demoText = "Listening...";
      }
      
      final speechResult = SpeechResult(
        text: demoText,
        confidence: 0.9, // High confidence for demo
        isFinal: true,
        timestamp: DateTime.now(),
      );
      
      _logger.d('📝 Whisper result${kIsWeb ? ' (Web Demo)' : ' (Demo)'}: "${speechResult.text}" (confidence: ${speechResult.confidence})');
      
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
        text: kIsWeb ? "Error processing audio (Web Demo)" : "Error processing audio (Demo)",
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
    _logger.i('⚙️ Updated Whisper configuration${kIsWeb ? ' (Web Demo Mode)' : ' (Demo Mode)'}');
    
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
      _logger.i('🛑 Stopped Whisper processing${kIsWeb ? ' (Web Demo Mode)' : ' (Demo Mode)'}');
      
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
      await _speechResultController.close();
      await _sttEventController.close();
      _isInitialized = false;
      _logger.i('🗑️ Whisper service disposed${kIsWeb ? ' (Web Demo Mode)' : ' (Demo Mode)'}');
    } catch (e, stackTrace) {
      _logger.e('❌ Error disposing Whisper service', error: e, stackTrace: stackTrace);
    }
  }
} 