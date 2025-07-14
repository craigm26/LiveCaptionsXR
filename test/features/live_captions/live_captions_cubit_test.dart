import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:live_captions_xr/features/live_captions/cubit/live_captions_cubit.dart';
import 'package:live_captions_xr/core/services/speech_processor.dart';
import 'package:live_captions_xr/core/services/hybrid_localization_engine.dart';
import 'package:live_captions_xr/core/models/speech_result.dart';

import 'live_captions_cubit_test.mocks.dart';

@GenerateMocks([SpeechProcessor, HybridLocalizationEngine])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSpeechProcessor mockSpeechProcessor;
  late MockHybridLocalizationEngine mockHybridLocalizationEngine;
  late LiveCaptionsCubit cubit;

  setUp(() {
    mockSpeechProcessor = MockSpeechProcessor();
    mockHybridLocalizationEngine = MockHybridLocalizationEngine();
    cubit = LiveCaptionsCubit(
      speechProcessor: mockSpeechProcessor,
      hybridLocalizationEngine: mockHybridLocalizationEngine,
    );
    
    // Set up mock method channels for hybrid localization
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('live_captions_xr/hybrid_localization_methods'),
            (MethodCall methodCall) async {
      if (methodCall.method == 'getFusedTransform') {
        return List<double>.filled(16, 1.0);
      }
      return null;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('live_captions_xr/caption_methods'),
            (MethodCall methodCall) async {
      return null;
    });
  });

  tearDown(() {
    cubit.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('live_captions_xr/hybrid_localization_methods'),
            null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('live_captions_xr/caption_methods'),
            null);
  });

  group('LiveCaptionsCubit Caption Placement', () {
    test('should place caption in AR when final speech result is received', () async {
      List<MethodCall> captionCalls = [];
      
      // Mock the caption method channel to capture calls
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('live_captions_xr/caption_methods'),
              (MethodCall methodCall) async {
        captionCalls.add(methodCall);
        return null;
      });

      // Initialize the cubit (mocking successful initialization)
      when(mockSpeechProcessor.initialize()).thenAnswer((_) async => true);
      when(mockSpeechProcessor.startProcessing()).thenAnswer((_) async => true);
      when(mockSpeechProcessor.speechResults).thenAnswer((_) => const Stream.empty());
      
      await cubit.initialize();
      
      // Simulate receiving a final speech result
      final finalResult = SpeechResult(
        text: 'Hello world',
        confidence: 0.9,
        isFinal: true,
        timestamp: DateTime.now(),
      );

      // Access the private method through reflection or create a public test method
      // For now, we'll test the behavior indirectly by checking if the cubit handles the result
      cubit.handleSpeechResult(finalResult);

      // Allow async operations to complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify that placeCaption was called
      expect(captionCalls.isNotEmpty, true);
      expect(captionCalls.first.method, 'placeCaption');
      expect(captionCalls.first.arguments['text'], 'Hello world');
    });

    test('should not place caption for interim speech results', () async {
      List<MethodCall> captionCalls = [];
      
      // Mock the caption method channel to capture calls
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('live_captions_xr/caption_methods'),
              (MethodCall methodCall) async {
        captionCalls.add(methodCall);
        return null;
      });

      // Initialize the cubit
      when(mockSpeechProcessor.initialize()).thenAnswer((_) async => true);
      when(mockSpeechProcessor.startProcessing()).thenAnswer((_) async => true);
      when(mockSpeechProcessor.speechResults).thenAnswer((_) => const Stream.empty());
      
      await cubit.initialize();
      
      // Simulate receiving an interim speech result
      final interimResult = SpeechResult(
        text: 'Hello...',
        confidence: 0.7,
        isFinal: false,
        timestamp: DateTime.now(),
      );

      cubit.handleSpeechResult(interimResult);

      // Allow async operations to complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify that placeCaption was NOT called for interim results
      expect(captionCalls.isEmpty, true);
    });

    test('should not place caption for empty text', () async {
      List<MethodCall> captionCalls = [];
      
      // Mock the caption method channel to capture calls
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('live_captions_xr/caption_methods'),
              (MethodCall methodCall) async {
        captionCalls.add(methodCall);
        return null;
      });

      // Initialize the cubit
      when(mockSpeechProcessor.initialize()).thenAnswer((_) async => true);
      when(mockSpeechProcessor.startProcessing()).thenAnswer((_) async => true);
      when(mockSpeechProcessor.speechResults).thenAnswer((_) => const Stream.empty());
      
      await cubit.initialize();
      
      // Simulate receiving a final speech result with empty text
      final emptyResult = SpeechResult(
        text: '   ',  // Empty/whitespace text
        confidence: 0.9,
        isFinal: true,
        timestamp: DateTime.now(),
      );

      cubit.handleSpeechResult(emptyResult);

      // Allow async operations to complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify that placeCaption was NOT called for empty text
      expect(captionCalls.isEmpty, true);
    });
  });
}