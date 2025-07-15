import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter/services.dart';

import '../models/speech_result.dart';
import '../models/speech_config.dart';
import '../models/enhanced_caption.dart';
import 'debug_capturing_logger.dart';
import 'gemma_enhancer.dart';
import 'model_download_manager.dart';

/// Speech processing engine types
enum SpeechEngine {
  native,      // Current native implementation
  speechToText, // New speech_to_text package
  gemma3n,     // Direct Gemma 3n ASR (future)
}

/// Enhanced service for processing speech with multiple engine support and Gemma enhancement
class EnhancedSpeechProcessor {
  static final DebugCapturingLogger _logger = DebugCapturingLogger();

  // Speech engines
  final SpeechToText _speechToText = SpeechToText();
  static const MethodChannel _nativeChannel = MethodChannel('live_captions_xr/speech');
  
  // Gemma enhancer
  final GemmaEnhancer? _gemmaEnhancer;
  
  // State management
  bool _isInitialized = false;
  bool _isProcessing = false;
  SpeechConfig _config = const SpeechConfig();
  SpeechEngine _activeEngine = SpeechEngine.speechToText;
  String? _currentLanguage;
  final List<String> _recentTexts = [];
  
  // Stream controllers
  final StreamController<SpeechResult> _speechResultController =
      StreamController<SpeechResult>.broadcast();
  final StreamController<EnhancedCaption> _enhancedCaptionController =
      StreamController<EnhancedCaption>.broadcast();
  
  // Public streams
  Stream<SpeechResult> get speechResults => _speechResultController.stream;
  Stream<EnhancedCaption> get enhancedCaptions => _enhancedCaptionController.stream;

  EnhancedSpeechProcessor({
    ModelDownloadManager? modelManager,
    SpeechEngine? defaultEngine,
  }) : _activeEngine = defaultEngine ?? SpeechEngine.speechToText,
       _gemmaEnhancer = modelManager != null ? GemmaEnhancer(modelManager: modelManager) : null;

  /// Initialize the speech processor with optional configuration
  Future<bool> initialize({
    SpeechConfig? config,
    bool enableGemmaEnhancement = true,
  }) async {
    if (_isInitialized) return true;

    try {
      _config = config ?? const SpeechConfig();
      _currentLanguage = _config.language;
      
      // Initialize based on active engine
      switch (_activeEngine) {
        case SpeechEngine.speechToText:
          await _initializeSpeechToText();
          break;
        case SpeechEngine.native:
          await _initializeNativeEngine();
          break;
        case SpeechEngine.gemma3n:
          _logger.w('Gemma 3n ASR not yet implemented, falling back to speech_to_text');
          _activeEngine = SpeechEngine.speechToText;
          await _initializeSpeechToText();
          break;
      }
      
      // Initialize Gemma enhancer if available and enabled
      if (enableGemmaEnhancement && _gemmaEnhancer != null) {
        try {
          await _gemmaEnhancer!.initialize();
          _logger.i('✅ Gemma enhancement enabled');
        } catch (e) {
          _logger.w('⚠️ Failed to initialize Gemma enhancer, continuing without enhancement', error: e);
        }
      }
      
      _isInitialized = true;
      _logger.i('✅ EnhancedSpeechProcessor initialized with engine: $_activeEngine');
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Error initializing EnhancedSpeechProcessor', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Initialize speech_to_text package
  Future<void> _initializeSpeechToText() async {
    final available = await _speechToText.initialize(
      onStatus: (status) => _logger.d('Speech status: $status'),
      onError: (error) => _logger.e('Speech error: $error'),
    );
    
    if (!available) {
      throw Exception('Speech-to-text not available on this device');
    }
    
    _logger.i('✅ speech_to_text package initialized');
  }

  /// Initialize native speech engine
  Future<void> _initializeNativeEngine() async {
    try {
      await _nativeChannel.invokeMethod('initializeSpeech');
      _logger.i('✅ Native speech engine initialized');
    } catch (e) {
      _logger.e('Failed to initialize native speech engine', error: e);
      rethrow;
    }
  }

  /// Start speech processing
  Future<bool> startProcessing({SpeechConfig? config}) async {
    if (!_isInitialized) {
      _logger.w('⚠️ EnhancedSpeechProcessor not initialized');
      return false;
    }
    if (_isProcessing) {
      _logger.w('⚠️ EnhancedSpeechProcessor is already processing');
      return true;
    }

    try {
      if (config != null) {
        await updateConfig(config);
      }
      
      switch (_activeEngine) {
        case SpeechEngine.speechToText:
          await _startSpeechToTextProcessing();
          break;
        case SpeechEngine.native:
          await _startNativeProcessing();
          break;
        case SpeechEngine.gemma3n:
          // Future implementation
          await _startSpeechToTextProcessing();
          break;
      }
      
      _isProcessing = true;
      _logger.i('✅ Speech processing started with engine: $_activeEngine');
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Error starting speech processing', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Start speech_to_text processing
  Future<void> _startSpeechToTextProcessing() async {
    await _speechToText.listen(
      onResult: _onSpeechToTextResult,
      localeId: _currentLanguage,
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        onDevice: true, // Prefer on-device recognition
        listenMode: ListenMode.dictation,
      ),
    );
  }

  /// Start native processing
  Future<void> _startNativeProcessing() async {
    _nativeChannel.setMethodCallHandler(_handleNativeMethodCall);
    await _nativeChannel.invokeMethod('startListening', {
      'language': _currentLanguage,
    });
  }

  /// Handle native method calls
  Future<dynamic> _handleNativeMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onSpeechResult':
        final text = call.arguments['text'] as String;
        final confidence = call.arguments['confidence'] as double;
        final isFinal = call.arguments['isFinal'] as bool;
        
        _processSpeechResult(SpeechResult(
          text: text,
          confidence: confidence,
          isFinal: isFinal,
          timestamp: DateTime.now(),
        ));
        break;
    }
  }

  /// Handle speech_to_text results
  void _onSpeechToTextResult(SpeechRecognitionResult result) {
    _processSpeechResult(SpeechResult(
      text: result.recognizedWords,
      confidence: result.confidence,
      isFinal: result.finalResult,
      timestamp: DateTime.now(),
    ));
  }

  /// Process speech results and optionally enhance with Gemma
  void _processSpeechResult(SpeechResult result) async {
    // Always emit the raw result
    _speechResultController.add(result);
    
    // Track recent texts
    if (result.isFinal) {
      _recentTexts.add(result.text);
      if (_recentTexts.length > 10) {
        _recentTexts.removeAt(0);
      }
    }
    
    // Process enhancement if available and enabled
    if (_gemmaEnhancer != null && _gemmaEnhancer!.isReady) {
      try {
        if (result.isFinal) {
          // Only enhance final results to avoid too many API calls
          final enhanced = await _gemmaEnhancer!.enhance(result.text);
          _enhancedCaptionController.add(enhanced);
        } else {
          // For partial results, emit without enhancement
          _enhancedCaptionController.add(EnhancedCaption.partial(result.text));
        }
      } catch (e) {
        _logger.e('Failed to enhance caption', error: e);
        // Fallback to raw text
        _enhancedCaptionController.add(EnhancedCaption.fallback(result.text));
      }
    } else {
      // No enhancement available, emit raw as enhanced
      _enhancedCaptionController.add(
        result.isFinal 
          ? EnhancedCaption(raw: result.text, enhanced: result.text, isFinal: true, isEnhanced: false)
          : EnhancedCaption.partial(result.text)
      );
    }
  }

  /// Stop speech processing
  Future<bool> stopProcessing() async {
    if (!_isProcessing) return true;
    
    try {
      switch (_activeEngine) {
        case SpeechEngine.speechToText:
          await _speechToText.stop();
          break;
        case SpeechEngine.native:
          await _nativeChannel.invokeMethod('stopListening');
          break;
        case SpeechEngine.gemma3n:
          await _speechToText.stop();
          break;
      }
      
      _isProcessing = false;
      _logger.i('✅ Speech processing stopped');
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Error stopping speech processing', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Switch speech engine
  Future<bool> switchEngine(SpeechEngine engine) async {
    if (_isProcessing) {
      await stopProcessing();
    }
    
    _activeEngine = engine;
    _logger.i('🔄 Switched to speech engine: $engine');
    
    // Re-initialize with new engine
    _isInitialized = false;
    return await initialize(config: _config);
  }

  /// Update configuration
  Future<bool> updateConfig(SpeechConfig newConfig) async {
    try {
      _logger.i('📋 Updating speech configuration...');
      _config = newConfig;
      _currentLanguage = newConfig.language;
      _logger.d('✅ Speech configuration updated: $_config');
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Error updating speech configuration', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Clean up resources
  Future<void> dispose() async {
    _logger.i('🗑️ Disposing EnhancedSpeechProcessor...');
    await stopProcessing();
    await _speechResultController.close();
    await _enhancedCaptionController.close();
    
    if (_gemmaEnhancer != null) {
      await _gemmaEnhancer!.dispose();
    }
    
    _isInitialized = false;
    _logger.d('✅ EnhancedSpeechProcessor disposed');
  }

  // Getters
  bool get isReady => _isInitialized;
  bool get isProcessing => _isProcessing;
  SpeechConfig get config => _config;
  String? get currentLanguage => _currentLanguage;
  SpeechEngine get activeEngine => _activeEngine;
  bool get hasGemmaEnhancement => _gemmaEnhancer?.isReady ?? false;

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    return {
      'isInitialized': _isInitialized,
      'isProcessing': _isProcessing,
      'activeEngine': _activeEngine.toString(),
      'currentLanguage': _currentLanguage,
      'recentTextsCount': _recentTexts.length,
      'hasGemmaEnhancement': hasGemmaEnhancement,
      'config': _config.toMap(),
      if (_gemmaEnhancer != null) 'gemmaStats': _gemmaEnhancer!.getCacheStats(),
    };
  }
} 