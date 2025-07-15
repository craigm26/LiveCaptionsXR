import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import '../models/speech_result.dart';
import '../models/speech_config.dart';
import 'debug_capturing_logger.dart';

/// Service for processing speech using a hybrid approach.
class SpeechProcessor {
  static final DebugCapturingLogger _logger = DebugCapturingLogger();

  final SpeechToText _speechToText = SpeechToText();

  bool _isInitialized = false;
  bool _isProcessing = false;
  SpeechConfig _config = const SpeechConfig();
  String? _currentLanguage;
  final List<String> _recentTexts = [];

  final StreamController<SpeechResult> _speechResultController =
      StreamController<SpeechResult>.broadcast();
  Stream<SpeechResult> get speechResults => _speechResultController.stream;

  SpeechProcessor();

  Future<bool> initialize({
    SpeechConfig? config,
  }) async {
    if (_isInitialized) return true;

    try {
      _config = config ?? const SpeechConfig();
      _currentLanguage = _config.language;
      await _speechToText.initialize();
      _isInitialized = true;
      _logger.i('✅ SpeechProcessor initialized successfully.');
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Error initializing SpeechProcessor', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> startProcessing({SpeechConfig? config}) async {
    if (!_isInitialized) {
      _logger.w('⚠️ SpeechProcessor not initialized');
      return false;
    }
    if (_isProcessing) {
      _logger.w('⚠️ SpeechProcessor is already processing');
      return true;
    }

    try {
      if (config != null) {
        await updateConfig(config);
      }
      await _speechToText.listen(
        onResult: _onSpeechResult,
        localeId: _currentLanguage,
      );
      _isProcessing = true;
      _logger.i('✅ Speech processing started.');
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Error starting speech processing', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> stopProcessing() async {
    if (!_isProcessing) return true;
    try {
      await _speechToText.stop();
      _isProcessing = false;
      _logger.i('✅ Speech processing stopped.');
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Error stopping speech processing', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) async {
    final speechResult = SpeechResult(
      text: result.recognizedWords,
      confidence: result.confidence,
      isFinal: result.finalResult,
      timestamp: DateTime.now(),
    );
    _speechResultController.add(speechResult);
  }

  Future<void> dispose() async {
    _logger.i('🗑️ Disposing SpeechProcessor...');
    await stopProcessing();
    await _speechResultController.close();
    _isInitialized = false;
    _logger.d('✅ SpeechProcessor disposed');
  }

  bool get isReady => _isInitialized;
  bool get isProcessing => _isProcessing;
  SpeechConfig get config => _config;
  String? get currentLanguage => _currentLanguage;

  Future<bool> updateConfig(SpeechConfig newConfig) async {
    try {
      _logger.i('📋 Updating speech configuration...');
      _config = newConfig;
      _currentLanguage = newConfig.language;
      _logger.d('✅ Speech configuration updated: $_config');
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Error updating speech configuration', 
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Map<String, dynamic> getStatistics() {
    return {
      'isInitialized': _isInitialized,
      'isProcessing': _isProcessing,
      'currentLanguage': _currentLanguage,
      'recentTextsCount': _recentTexts.length,
      'config': _config.toMap(),
    };
  }
}
