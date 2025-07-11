import 'dart:async';
import 'dart:typed_data';
import 'dart:math' show sqrt;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

import '../models/speech_result.dart';
import '../models/speech_config.dart';
import 'language_detection_service.dart';
import 'debug_capturing_logger.dart';
import 'visual_service.dart';

/// Service for processing speech using Gemma 3 multimodal capabilities
class SpeechProcessor {
  /// TODO: Integrate with flutter_gemma for ASR and streaming when available

  static final DebugCapturingLogger _logger = DebugCapturingLogger();

  StreamSubscription? _streamSubscription;
  final StreamController<SpeechResult> _speechResultController =
      StreamController<SpeechResult>.broadcast();

  final VisualService _visualService = VisualService();
  bool _isInitialized = false;
  bool _isProcessing = false;
  SpeechConfig _config = const SpeechConfig();
  String? _currentLanguage;
  final List<String> _recentTexts = [];

  /// Stream of speech recognition results
  Stream<SpeechResult> get speechResults => _speechResultController.stream;

  /// Mock initialize method
  Future<bool> initialize({
    String modelPath = 'assets/models/gemma-3n-E2B-it-int4.task',
    double temperature = 0.7,
    int topK = 40,
    double topP = 0.9,
    int maxTokens = 512,
    SpeechConfig? config,
  }) async {
    await Future.delayed(Duration(milliseconds: 100));
    _isInitialized = true;
    _config = config ?? const SpeechConfig();
    _currentLanguage = _config.language;
    _logger.i('✅ [MOCK] SpeechProcessor initialized');
    return true;
  }

  /// Mock startProcessing method
  Future<bool> startProcessing({SpeechConfig? config}) async {
    if (!_isInitialized) {
      _logger.w('⚠️ [MOCK] SpeechProcessor not initialized');
      return false;
    }
    await Future.delayed(Duration(milliseconds: 100));
    _isProcessing = true;
    _logger.i('✅ [MOCK] Speech processing started');
    // Simulate streaming results
    _streamSubscription = Stream<SpeechResult>.fromIterable([
      SpeechResult(
        text: 'This is a mock interim result.',
        confidence: 0.8,
        isFinal: false,
        timestamp: DateTime.now(),
      ),
      SpeechResult(
        text: 'This is a mock final result.',
        confidence: 0.95,
        isFinal: true,
        timestamp: DateTime.now().add(Duration(seconds: 1)),
      ),
    ]).listen((result) {
      _speechResultController.add(result);
    });
    return true;
  }

  /// Mock stopProcessing method
  Future<bool> stopProcessing() async {
    if (!_isProcessing) return true;
    await Future.delayed(Duration(milliseconds: 50));
    _isProcessing = false;
    await _streamSubscription?.cancel();
    _logger.i('✅ [MOCK] Speech processing stopped');
    return true;
  }

  /// Mock processAudioChunk method
  Future<void> processAudioChunk(Float32List audioData) async {
    if (!_isInitialized || !_isProcessing) {
      _logger.w('⚠️ [MOCK] Cannot process audio chunk - not initialized or not processing');
      return;
    }
    await Future.delayed(Duration(milliseconds: 50));
    _logger.d('✅ [MOCK] Audio chunk processed');
  }

  /// Mock detectLanguage method
  Future<void> detectLanguage(List<double> audioBuffer) async {
    await Future.delayed(Duration(milliseconds: 50));
    _logger.d('✅ [MOCK] Language detection simulated');
  }

  /// Process text with Gemma 3 for enhancement and context
  Future<String> enhanceText(
    String rawText, {
    String? context,
    String? speakerDirection,
  }) async {
    if (!_isInitialized || !_config.enableRealTimeEnhancement) {
      _logger.w('⚠️ SpeechProcessor not initialized or enhancement disabled');
      return rawText;
    }

    try {
      _logger.d('🤖 Enhancing text with Gemma 3: "$rawText"');

      // Detect language from text if language detection is enabled
      if (_config.enableLanguageDetection) {
        final detection = await LanguageDetectionService.detectLanguageFromText(
          rawText,
          _config,
        );
        
        if (detection != null && detection.confidence > 0.8) {
          if (detection.detectedLanguage != _currentLanguage) {
            _currentLanguage = detection.detectedLanguage;
            _logger.d('🌍 Language detected from text: $_currentLanguage');
          }
        }
      }

      // Build context from recent texts
      String recentContext = '';
      if (_recentTexts.isNotEmpty) {
        recentContext = '\nRecent context: ${_recentTexts.take(3).join(' ')}';
      }

      // Create a language-aware prompt for text enhancement
      String prompt = '''
You are an AI assistant helping with live captions for an AR/XR application. 
Please improve the following speech transcription by:
1. Correcting any obvious transcription errors
2. Adding proper punctuation and capitalization
3. Making the text clear and readable for AR captions
4. Keep it concise and natural
5. Maintain the original language (${_currentLanguage ?? _config.language})

Raw transcription: "$rawText"
Language: ${_currentLanguage ?? _config.language}$recentContext
''';

      if (context != null) {
        prompt += '\nAdditional context: $context';
      }

      if (speakerDirection != null) {
        prompt += '\nSpeaker direction: $speakerDirection';
      }

      prompt += '\n\nImproved caption (same language):';

      // Capture a visual snapshot for multimodal context
      final Uint8List? visualSnapshot = await _visualService.captureVisualSnapshot();

      final result = await MethodChannel('gemma3n_multimodal').invokeMethod('generateText', {
        'prompt': prompt,
        'maxTokens': _config.enhancementMaxTokens,
        'temperature': _config.enhancementTemperature,
        'visual_snapshot': visualSnapshot,
      });

      if (result['success'] == true && result['text'] != null) {
        final enhancedText = result['text'] as String;
        _logger.d('✨ Enhanced text: "$enhancedText"');
        
        // Store for context (keep last 5 texts)
        _recentTexts.add(enhancedText);
        if (_recentTexts.length > 5) {
          _recentTexts.removeAt(0);
        }
        
        return enhancedText.trim();
      } else {
        _logger.w('⚠️ Text enhancement failed, returning original');
        return rawText;
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Error enhancing text', error: e, stackTrace: stackTrace);
      return rawText;
    }
  }

  /// Handle incoming stream data from the native plugin
  void _handleStreamData(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        final type = data['type'] as String?;
        _logger.d('📥 Received stream data: $type');

        switch (type) {
          case 'speechResult':
            final text = data['text'] as String? ?? '';
            final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.0;
            final isFinal = data['isFinal'] as bool? ?? false;
            final timestamp = DateTime.fromMillisecondsSinceEpoch(
                data['timestamp'] as int? ??
                    DateTime.now().millisecondsSinceEpoch);

            _logger.i('🎤 Speech result received: "${text.length > 50 ? text.substring(0, 50) + '...' : text}"');
            _logger.d('📊 Confidence: ${confidence.toStringAsFixed(2)}, Final: $isFinal');
            _logger.d('🕐 Timestamp: ${timestamp.toIso8601String()}');

            final result = SpeechResult(
              text: text,
              confidence: confidence,
              isFinal: isFinal,
              timestamp: timestamp,
            );

            _speechResultController.add(result);
            
            if (isFinal) {
              _logger.i('✅ Final speech result: "$text"');
              _logger.d('🎯 Speech recognition completed - sending to UI for caption placement');
            } else {
              _logger.d('🔄 Interim speech result: "$text"');
            }
            break;

          case 'error':
            final message = data['message'] as String? ?? 'Unknown error';
            _logger.e('🚨 Speech processing error: $message');
            break;

          case 'modelStatus':
            final status = data['status'] as String? ?? 'unknown';
            _logger.i('🤖 Model status update: $status');
            break;

          case 'audioProcessingStatus':
            final status = data['status'] as String? ?? 'unknown';
            _logger.d('🎧 Audio processing status: $status');
            break;

          default:
            _logger.d('📊 Received unknown stream data type: $type');
            _logger.d('📋 Data: $data');
        }
      } else {
        _logger.w('⚠️ Received non-map stream data: ${data.runtimeType}');
        _logger.d('📋 Raw data: $data');
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Error handling stream data',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Handle stream errors
  void _handleStreamError(dynamic error) {
    _logger.e('🚨 Speech processing stream error: $error');
  }

  /// Clean up resources
  Future<void> dispose() async {
    _logger.i('🗑️ Disposing SpeechProcessor...');

    await stopProcessing();
    await _streamSubscription?.cancel();
    await _speechResultController.close();
    _visualService.dispose();

    _isInitialized = false;
    _logger.d('✅ SpeechProcessor disposed');
  }

  /// Check if the processor is ready to use
  bool get isReady => _isInitialized;

  /// Check if currently processing audio
  bool get isProcessing => _isProcessing;

  /// Get current speech configuration
  SpeechConfig get config => _config;

  /// Get currently detected language
  String? get currentLanguage => _currentLanguage;

  /// Update speech configuration
  Future<bool> updateConfig(SpeechConfig newConfig) async {
    try {
      _logger.i('📋 Updating speech configuration...');
      _config = newConfig;
      _currentLanguage = newConfig.language;

      // Send updated config to native plugin if processing
      if (_isProcessing) {
        await MethodChannel('gemma3n_multimodal').invokeMethod('updateConfig', {
          'config': _config.toMap(),
        });
      }

      _logger.d('✅ Speech configuration updated: $_config');
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Error updating speech configuration', 
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get speech processing statistics
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
