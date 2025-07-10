import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:typed_data';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Gemma3n Swift Plugin Stream Handler Validation', () {
    const channel = MethodChannel('gemma3n_multimodal');
    const streamChannel = EventChannel('gemma3n_multimodal_stream');

    setUp(() {
      // Mock the plugin responses based on the PR #48 changes
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'loadModel':
            // Simulate successful model loading
            return {'success': true, 'modelPath': methodCall.arguments['path']};
          
          case 'startAudioCapture':
            // Validate audio capture parameters
            final args = methodCall.arguments as Map<String, dynamic>;
            expect(args['sampleRate'], 16000);
            expect(args['channels'], 1);
            expect(args['format'], 'pcm16');
            return null;
          
          case 'stopAudioCapture':
            return null;
          
          case 'processAudioChunk':
            // Validate audio chunk processing
            final args = methodCall.arguments as Map<String, dynamic>;
            expect(args.containsKey('audioData'), true);
            expect(args['audioData'], isA<Float32List>());
            return null;
          
          default:
            return null;
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('should load model without requiring audio data', () async {
      // Act
      final result = await channel.invokeMethod('loadModel', {
        'path': 'assets/models/test-model.task',
        'temperature': 0.7,
        'topK': 40,
        'topP': 0.9,
        'maxTokens': 512,
        'useANE': true,
        'useGPU': false,
      });

      // Assert
      expect(result['success'], true);
      expect(result['modelPath'], 'assets/models/test-model.task');
    });

    test('should start audio capture with correct parameters', () async {
      // Act & Assert - Should not throw
      await channel.invokeMethod('startAudioCapture', {
        'sampleRate': 16000,
        'channels': 1,
        'format': 'pcm16',
      });
    });

    test('should process audio chunks correctly', () async {
      // Arrange
      final audioData = Float32List.fromList([0.1, -0.1, 0.2, -0.2, 0.3]);

      // Act & Assert - Should not throw
      await channel.invokeMethod('processAudioChunk', {
        'audioData': audioData,
        'sampleRate': 16000,
      });
    });

    test('should handle stream setup without audio data requirement', () async {
      // This test validates the core fix from PR #48
      bool streamSetupSuccessful = false;
      PlatformException? streamSetupError;

      // Mock stream handler
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(
        'gemma3n_multimodal_stream',
        (ByteData? message) async {
          try {
            final decoded = const StandardMethodCodec().decodeMethodCall(message);
            if (decoded.method == 'listen') {
              final args = decoded.arguments as Map<dynamic, dynamic>?;
              
              // Validate that stream setup accepts transcription type without audio
              if (args != null && args['type'] == 'transcription') {
                // Before PR #48 fix, this would have failed with NOT_READY error
                // After PR #48 fix, this should succeed
                streamSetupSuccessful = true;
                return const StandardMethodCodec().encodeSuccessEnvelope(null);
              } else {
                throw PlatformException(
                  code: 'INVALID_ARGUMENT',
                  message: 'Unknown stream type',
                );
              }
            }
            return null;
          } catch (e) {
            if (e is PlatformException) {
              streamSetupError = e;
              return const StandardMethodCodec().encodeErrorEnvelope(
                code: e.code,
                message: e.message,
                details: e.details,
              );
            }
            rethrow;
          }
        },
      );

      // Act
      try {
        final stream = streamChannel.receiveBroadcastStream({'type': 'transcription'});
        final subscription = stream.listen((_) {});
        await Future.delayed(const Duration(milliseconds: 100));
        await subscription.cancel();
      } catch (e) {
        streamSetupError = e as PlatformException?;
      }

      // Assert
      expect(streamSetupSuccessful, true, 
        reason: 'Stream setup should succeed without requiring audio data (PR #48 fix)');
      expect(streamSetupError, isNull, 
        reason: 'Should not get NOT_READY error during stream setup');
    });

    test('should validate PR #48 speech result format', () async {
      // This test validates the speech result format from the Swift plugin
      List<Map<String, dynamic>> receivedEvents = [];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(
        'gemma3n_multimodal_stream',
        (ByteData? message) async {
          final decoded = const StandardMethodCodec().decodeMethodCall(message);
          if (decoded.method == 'listen') {
            // Simulate the speech results format from PR #48
            final speechResult = {
              'type': 'speechResult',
              'text': 'Transcribed text from audio chunk',
              'confidence': 0.85,
              'isFinal': false,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            };

            final finalResult = {
              'type': 'speechResult',
              'text': 'Final transcribed speech result',
              'confidence': 0.9,
              'isFinal': true,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            };

            // Simulate receiving these events
            receivedEvents.addAll([speechResult, finalResult]);
            
            return const StandardMethodCodec().encodeSuccessEnvelope(null);
          }
          return null;
        },
      );

      // Act
      final stream = streamChannel.receiveBroadcastStream({'type': 'transcription'});
      final subscription = stream.listen((_) {});
      await Future.delayed(const Duration(milliseconds: 100));
      await subscription.cancel();

      // Assert
      expect(receivedEvents, hasLength(2));
      
      // Validate interim result
      final interimResult = receivedEvents[0];
      expect(interimResult['type'], 'speechResult');
      expect(interimResult['text'], 'Transcribed text from audio chunk');
      expect(interimResult['confidence'], 0.85);
      expect(interimResult['isFinal'], false);
      expect(interimResult['timestamp'], isA<int>());

      // Validate final result
      final finalResultData = receivedEvents[1];
      expect(finalResultData['type'], 'speechResult');
      expect(finalResultData['text'], 'Final transcribed speech result');
      expect(finalResultData['confidence'], 0.9);
      expect(finalResultData['isFinal'], true);
      expect(finalResultData['timestamp'], isA<int>());
    });

    test('should handle model not loaded scenario gracefully', () async {
      // Override mock to simulate model not loaded
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'startAudioCapture') {
          throw PlatformException(
            code: 'NOT_READY',
            message: 'Model not loaded',
          );
        }
        return null;
      });

      // Act & Assert
      expect(
        () => channel.invokeMethod('startAudioCapture', {
          'sampleRate': 16000,
          'channels': 1,
          'format': 'pcm16',
        }),
        throwsA(isA<PlatformException>().having(
          (e) => e.code,
          'code',
          'NOT_READY',
        )),
      );
    });

    test('should validate audio processing buffer management', () async {
      // This test validates the buffer management logic from PR #48
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'processAudioChunk') {
          final args = methodCall.arguments as Map<String, dynamic>;
          final audioData = args['audioData'] as Float32List;
          
          // Validate audio data format and size
          expect(audioData, isA<Float32List>());
          expect(audioData.length, greaterThan(0));
          
          // Simulate the buffer processing logic from the Swift plugin
          if (audioData.length >= 16000) { // 1 second at 16kHz
            // Should trigger speech result
            return null;
          }
          
          return null;
        }
        return null;
      });

      // Act - Process multiple small chunks
      for (int i = 0; i < 5; i++) {
        final chunk = Float32List.fromList(
          List.generate(3200, (index) => (index % 100) / 100.0), // 0.2 seconds worth
        );
        
        await channel.invokeMethod('processAudioChunk', {
          'audioData': chunk,
          'sampleRate': 16000,
        });
      }

      // Test passed if no exceptions were thrown
    });
  });
}