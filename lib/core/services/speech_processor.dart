import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

import '../models/speech_result.dart';
import 'debug_capturing_logger.dart';

/// Service for processing speech using Gemma 3 multimodal capabilities
class SpeechProcessor {
  static const _channel = MethodChannel('gemma3n_multimodal');
  static const _stream = EventChannel('gemma3n_multimodal_stream');

  static final DebugCapturingLogger _logger = DebugCapturingLogger();

  StreamSubscription? _streamSubscription;
  final StreamController<SpeechResult> _speechResultController =
      StreamController<SpeechResult>.broadcast();

  bool _isInitialized = false;
  bool _isProcessing = false;

  /// Stream of speech recognition results
  Stream<SpeechResult> get speechResults => _speechResultController.stream;

  /// Initialize the speech processor with Gemma 3 model
  Future<bool> initialize({
    String modelPath = 'assets/models/gemma-3n-E2B-it-int4.task',
    double temperature = 0.7,
    int topK = 40,
    double topP = 0.9,
    int maxTokens = 512,
  }) async {
    try {
      _logger.i('🎤 Initializing SpeechProcessor with Gemma 3...');

      // Load the Gemma 3 model for speech processing
      final result = await _channel.invokeMethod('loadModel', {
        'path': modelPath,
        'temperature': temperature,
        'topK': topK,
        'topP': topP,
        'maxTokens': maxTokens,
        'useANE': true, // Use Apple Neural Engine for better performance
        'useGPU': false,
      });

      if (result['success'] == true) {
        _isInitialized = true;
        _logger.i('✅ SpeechProcessor initialized successfully');
        _logger.d('📁 Model loaded from: ${result['modelPath']}');

        // Set up the stream for real-time results - specify transcription type
        _streamSubscription = _stream.receiveBroadcastStream({
          'type': 'transcription',
        }).listen(
          _handleStreamData,
          onError: _handleStreamError,
        );

        return true;
      } else {
        _logger.e('❌ Failed to initialize SpeechProcessor');
        return false;
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Error initializing SpeechProcessor',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Start processing audio data for speech recognition
  Future<bool> startProcessing() async {
    if (!_isInitialized) {
      _logger.w('⚠️ SpeechProcessor not initialized');
      return false;
    }

    if (_isProcessing) {
      _logger.w('⚠️ SpeechProcessor already processing');
      return true;
    }

    try {
      _logger.i('🎤 Starting speech processing...');

      await _channel.invokeMethod('startAudioCapture', {
        'sampleRate': 16000,
        'channels': 1,
        'format': 'pcm16',
      });

      _isProcessing = true;
      _logger.i('✅ Speech processing started');
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Error starting speech processing',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Stop processing audio data
  Future<bool> stopProcessing() async {
    if (!_isProcessing) {
      return true;
    }

    try {
      _logger.i('🛑 Stopping speech processing...');

      await _channel.invokeMethod('stopAudioCapture');

      _isProcessing = false;
      _logger.i('✅ Speech processing stopped');
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Error stopping speech processing',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Process audio chunk for speech recognition
  Future<void> processAudioChunk(Float32List audioData) async {
    if (!_isInitialized || !_isProcessing) {
      return;
    }

    try {
      await _channel.invokeMethod('processAudioChunk', {
        'audioData': audioData,
        'sampleRate': 16000,
      });
    } catch (e, stackTrace) {
      _logger.e('❌ Error processing audio chunk',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Process text with Gemma 3 for enhancement and context
  Future<String> enhanceText(
    String rawText, {
    String? context,
    String? speakerDirection,
  }) async {
    if (!_isInitialized) {
      _logger.w('⚠️ SpeechProcessor not initialized');
      return rawText;
    }

    try {
      _logger.d('🤖 Enhancing text with Gemma 3: "$rawText"');

      // Create a prompt for text enhancement and contextual understanding
      String prompt = '''
You are an AI assistant helping with live captions for an AR/XR application. 
Please improve the following speech transcription by:
1. Correcting any obvious transcription errors
2. Adding proper punctuation and capitalization
3. Making the text clear and readable for AR captions
4. Keep it concise and natural

Raw transcription: "$rawText"
''';

      if (context != null) {
        prompt += '\nContext: $context';
      }

      if (speakerDirection != null) {
        prompt += '\nSpeaker direction: $speakerDirection';
      }

      prompt += '\n\nImproved caption:';

      final result = await _channel.invokeMethod('generateText', {
        'prompt': prompt,
        'maxTokens': 100,
        'temperature': 0.3, // Lower temperature for more consistent corrections
      });

      if (result['success'] == true && result['text'] != null) {
        final enhancedText = result['text'] as String;
        _logger.d('✨ Enhanced text: "$enhancedText"');
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

        switch (type) {
          case 'speechResult':
            final text = data['text'] as String? ?? '';
            final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.0;
            final isFinal = data['isFinal'] as bool? ?? false;
            final timestamp = DateTime.fromMillisecondsSinceEpoch(
                data['timestamp'] as int? ??
                    DateTime.now().millisecondsSinceEpoch);

            final result = SpeechResult(
              text: text,
              confidence: confidence,
              isFinal: isFinal,
              timestamp: timestamp,
            );

            _speechResultController.add(result);
            break;

          case 'error':
            final message = data['message'] as String? ?? 'Unknown error';
            _logger.e('🚨 Speech processing error: $message');
            break;

          default:
            _logger.d('📊 Received unknown stream data type: $type');
        }
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

    _isInitialized = false;
    _logger.d('✅ SpeechProcessor disposed');
  }

  /// Check if the processor is ready to use
  bool get isReady => _isInitialized;

  /// Check if currently processing audio
  bool get isProcessing => _isProcessing;
}
