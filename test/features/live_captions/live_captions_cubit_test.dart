import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:live_captions_xr/features/live_captions/cubit/live_captions_cubit.dart';
import 'package:live_captions_xr/core/services/speech_processor.dart';
import 'package:live_captions_xr/core/services/hybrid_localization_engine.dart';
import 'package:live_captions_xr/core/services/contextual_enhancer.dart';
import 'package:live_captions_xr/core/models/speech_result.dart';

import 'live_captions_cubit_test.mocks.dart';

@GenerateMocks([SpeechProcessor, HybridLocalizationEngine, ContextualEnhancer])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSpeechProcessor mockSpeechProcessor;
  late MockHybridLocalizationEngine mockHybridLocalizationEngine;
  late MockContextualEnhancer mockContextualEnhancer;
  late LiveCaptionsCubit cubit;

  setUp(() {
    mockSpeechProcessor = MockSpeechProcessor();
    mockHybridLocalizationEngine = MockHybridLocalizationEngine();
    mockContextualEnhancer = MockContextualEnhancer();
    cubit = LiveCaptionsCubit(
      speechProcessor: mockSpeechProcessor,
      hybridLocalizationEngine: mockHybridLocalizationEngine,
      contextualEnhancer: mockContextualEnhancer,
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
      // Arrange
      final speechResultController = StreamController<SpeechResult>();
      when(mockSpeechProcessor.speechResults).thenAnswer((_) => speechResultController.stream);
      when(mockSpeechProcessor.startProcessing()).thenAnswer((_) async => true);
      when(mockHybridLocalizationEngine.placeRealtimeCaption(any)).thenAnswer((_) async => Future.value());

      // Act
      await cubit.startCaptions();
      speechResultController.add(SpeechResult(text: 'Hello world', confidence: 0.9, isFinal: true, timestamp: DateTime.now()));
      await cubit.close(); // to trigger the stream to close

      // Assert
      verify(mockHybridLocalizationEngine.placeRealtimeCaption('Hello world')).called(1);
    });

    test('should not place caption for interim speech results', () async {
      // Arrange
      final speechResultController = StreamController<SpeechResult>();
      when(mockSpeechProcessor.speechResults).thenAnswer((_) => speechResultController.stream);
      when(mockSpeechProcessor.startProcessing()).thenAnswer((_) async => true);

      // Act
      await cubit.startCaptions();
      speechResultController.add(SpeechResult(text: 'Hello...', confidence: 0.7, isFinal: false, timestamp: DateTime.now()));
      await cubit.close();

      // Assert
      verifyNever(mockHybridLocalizationEngine.placeRealtimeCaption(any));
    });

    test('should not place caption for empty text', () async {
      // Arrange
      final speechResultController = StreamController<SpeechResult>();
      when(mockSpeechProcessor.speechResults).thenAnswer((_) => speechResultController.stream);
      when(mockSpeechProcessor.startProcessing()).thenAnswer((_) async => true);

      // Act
      await cubit.startCaptions();
      speechResultController.add(SpeechResult(text: '   ', confidence: 0.9, isFinal: true, timestamp: DateTime.now()));
      await cubit.close();

      // Assert
      verifyNever(mockHybridLocalizationEngine.placeRealtimeCaption(any));
    });
  });
}
