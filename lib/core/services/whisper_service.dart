import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/speech_config.dart';
import '../models/speech_result.dart';
import 'debug_capturing_logger.dart';

/// Service for handling Whisper GGML speech-to-text processing
/// 
/// On web platforms, this provides demo functionality since whisper_ggml
/// uses dart:ffi which is not available on web.
class WhisperService {
  static final DebugCapturingLogger _logger = DebugCapturingLogger();
  
  bool _isInitialized = false;
  bool _isProcessing = false;
  SpeechConfig _config = const SpeechConfig();
  
  final StreamController<SpeechResult> _speechResultController =
      StreamController<SpeechResult>.broadcast();
  
  Stream<SpeechResult> get speechResults => _speechResultController.stream;
  
  bool get isInitialized => _isInitialized;
  bool get isProcessing => _isProcessing;
  
  /// Initialize the Whisper service with configuration
  Future<bool> initialize({SpeechConfig? config}) async {
    if (_isInitialized) return true;
    
    try {
      _config = config ?? const SpeechConfig();
      
      if (kIsWeb) {
        // Web demo mode
        _logger.i('🔧 Initializing Whisper service (Web Demo Mode)');
        await Future.delayed(const Duration(milliseconds: 100));
        _isInitialized = true;
        _logger.i('✅ Whisper service initialized (Web Demo Mode)');
        return true;
      } else {
        // Native implementation - this will be handled by conditional compilation
        _logger.i('🔧 Initializing Whisper service with model: ${_config.whisperModel}');
        _logger.w('⚠️ Native Whisper implementation not available in this build');
        _isInitialized = true;
        _logger.i('✅ Whisper service initialized (Demo Mode)');
        return true;
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to initialize Whisper service', error: e, stackTrace: stackTrace);
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
      if (kIsWeb) {
        _logger.i('🎤 Starting Whisper processing (Web Demo Mode)');
      } else {
        _logger.i('🎤 Starting Whisper processing (Demo Mode)');
      }
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to start Whisper processing', error: e, stackTrace: stackTrace);
      _isProcessing = false;
      return false;
    }
  }
  
  /// Process audio buffer and return transcription
  Future<SpeechResult> processAudioBuffer(Uint8List audioData) async {
    if (!_isInitialized) {
      _logger.w('⚠️ Whisper not initialized, returning fallback result');
      return SpeechResult(
        text: kIsWeb ? "Whisper not initialized (Web Demo)" : "Whisper not initialized (Demo)",
        confidence: 0.0,
        isFinal: true,
        timestamp: DateTime.now(),
      );
    }
    
    try {
      _logger.d('🎵 Processing audio buffer (${audioData.length} bytes)${kIsWeb ? ' - Web Demo Mode' : ' - Demo Mode'}');
      
      // Simulate processing delay
      await Future.delayed(const Duration(milliseconds: 500));
      
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
      
      // Emit the result
      _speechResultController.add(speechResult);
      
      return speechResult;
    } catch (e, stackTrace) {
      _logger.e('❌ Error processing audio with Whisper', error: e, stackTrace: stackTrace);
      
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
    } catch (e, stackTrace) {
      _logger.e('❌ Error stopping Whisper processing', error: e, stackTrace: stackTrace);
    }
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    try {
      await stopProcessing();
      await _speechResultController.close();
      _isInitialized = false;
      _logger.i('🗑️ Whisper service disposed${kIsWeb ? ' (Web Demo Mode)' : ' (Demo Mode)'}');
    } catch (e, stackTrace) {
      _logger.e('❌ Error disposing Whisper service', error: e, stackTrace: stackTrace);
    }
  }
} 