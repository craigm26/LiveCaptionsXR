import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_captions_xr/core/services/speech_processor.dart';
import 'package:live_captions_xr/core/models/speech_result.dart';
import 'dart:typed_data';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Gemma3n Multimodal Speech Processing Integration', () {
    late SpeechProcessor speechProcessor;
    List<MethodCall> methodCalls = [];
    List<dynamic> streamEvents = [];
    
    setUp(() {
      methodCalls.clear();
      streamEvents.clear();
      speechProcessor = SpeechProcessor();

      // Mock the method channel for the plugin
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('gemma3n_multimodal'),
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          
          switch (methodCall.method) {
            case 'loadModel':
              return {
                'success': true,
                'modelPath': methodCall.arguments['path'],
              };
            case 'startAudioCapture':
              return null;
            case 'stopAudioCapture':
              return null;
            case 'processAudioChunk':
              // Simulate that audio chunk processing triggers stream events
              _triggerStreamEvent({
                'type': 'speechResult',
                'text': 'Test transcription result',
                'confidence': 0.85,
                'isFinal': false,
                'timestamp': DateTime.now().millisecondsSinceEpoch,
              });
              return null;
            case 'generateText':
              return {
                'success': true,
                'text': 'Enhanced: ${methodCall.arguments['prompt']}',
              };
            default:
              return null;
          }
        },
      );

      // Mock the event channel for streams
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(
        'gemma3n_multimodal_stream',
        (ByteData? message) async {
          // Decode the stream setup arguments
          final decoded = const StandardMethodCodec().decodeMethodCall(message);
          if (decoded.method == 'listen') {
            // Stream setup should not require audio data
            final args = decoded.arguments as Map<dynamic, dynamic>?;
            if (args != null && args['type'] == 'transcription') {
              // Successful stream setup - no audio data required
              return const StandardMethodCodec().encodeSuccessEnvelope(null);
            }
          }
          return null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('gemma3n_multimodal'), null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('gemma3n_multimodal_stream', null);
    });

    void _triggerStreamEvent(Map<String, dynamic> event) {
      streamEvents.add(event);
    }

    test('should initialize speech processor without errors', () async {
      // Act
      final result = await speechProcessor.initialize();

      // Assert
      expect(result, true);
      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, 'loadModel');
      expect(methodCalls.first.arguments['path'], 'assets/models/gemma-3n-E2B-it-int4.task');
    });

    test('should start audio capture without stream setup errors', () async {
      // Arrange
      await speechProcessor.initialize();
      methodCalls.clear();

      // Act
      final result = await speechProcessor.startProcessing();

      // Assert
      expect(result, true);
      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, 'startAudioCapture');
      expect(methodCalls.first.arguments['sampleRate'], 16000);
      expect(methodCalls.first.arguments['channels'], 1);
      expect(methodCalls.first.arguments['format'], 'pcm16');
    });

    test('should process audio chunks without requiring audio in stream setup', () async {
      // Arrange
      await speechProcessor.initialize();
      await speechProcessor.startProcessing();
      methodCalls.clear();

      final audioData = Float32List.fromList([0.1, 0.2, 0.3, 0.4, 0.5]);

      // Act
      await speechProcessor.processAudioChunk(audioData);

      // Assert
      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, 'processAudioChunk');
      expect(methodCalls.first.arguments['audioData'], audioData);
      expect(methodCalls.first.arguments['sampleRate'], 16000);
    });

    test('should enhance text using Gemma 3', () async {
      // Arrange
      await speechProcessor.initialize();
      methodCalls.clear();

      // Act
      final result = await speechProcessor.enhanceText(
        'hello world how are you',
        context: 'casual conversation',
        speakerDirection: 'front',
      );

      // Assert
      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, 'generateText');
      expect(methodCalls.first.arguments['maxTokens'], 100);
      expect(methodCalls.first.arguments['temperature'], 0.3);
      expect(result, contains('Enhanced:'));
    });

    test('should stop processing cleanly', () async {
      // Arrange
      await speechProcessor.initialize();
      await speechProcessor.startProcessing();
      methodCalls.clear();

      // Act
      final result = await speechProcessor.stopProcessing();

      // Assert
      expect(result, true);
      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, 'stopAudioCapture');
    });

    test('should handle initialization failure gracefully', () async {
      // Arrange - Mock a failing model load
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('gemma3n_multimodal'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'loadModel') {
            return {'success': false, 'error': 'Model not found'};
          }
          return null;
        },
      );

      // Act
      final result = await speechProcessor.initialize();

      // Assert
      expect(result, false);
    });

    test('should validate stream setup does not require audio data', () async {
      // This test validates the core fix from PR #48
      bool streamSetupCalled = false;
      bool audioDataRequired = false;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(
        'gemma3n_multimodal_stream',
        (ByteData? message) async {
          final decoded = const StandardMethodCodec().decodeMethodCall(message);
          if (decoded.method == 'listen') {
            streamSetupCalled = true;
            final args = decoded.arguments as Map<dynamic, dynamic>?;
            // Check if audio data is required in stream setup
            audioDataRequired = args?.containsKey('audio') ?? false;
            return const StandardMethodCodec().encodeSuccessEnvelope(null);
          }
          return null;
        },
      );

      // Act
      await speechProcessor.initialize();

      // Assert
      expect(streamSetupCalled, true);
      expect(audioDataRequired, false, 
        reason: 'Stream setup should not require audio data (PR #48 fix)');
    });
  });
}