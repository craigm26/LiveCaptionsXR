import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_captions_xr/core/services/hybrid_localization_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channelName = 'live_captions_xr/hybrid_localization_methods';
  const captionChannelName = 'live_captions_xr/caption_methods';
  final engine = HybridLocalizationEngine();

  setUp(() {
    // No setup needed here, will be handled in each test
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(channelName), null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(captionChannelName), null);
  });

  test('predict calls method channel', () async {
    MethodCall? call;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(channelName),
            (MethodCall methodCall) async {
      call = methodCall;
      return null;
    });
    await engine.predict();
    expect(call?.method, 'predict');
  });

  test('updateWithAudioMeasurement sends correct args', () async {
    MethodCall? call;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(channelName),
            (MethodCall methodCall) async {
      call = methodCall;
      return null;
    });
    await engine.updateWithAudioMeasurement(
        angle: 0.5, confidence: 0.9, deviceTransform: List.filled(16, 1.0));
    expect(call?.method, 'updateWithAudioMeasurement');
    expect(call?.arguments['angle'], 0.5);
    expect(call?.arguments['confidence'], 0.9);
  });

  test('updateWithVisualMeasurement sends correct args', () async {
    MethodCall? call;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(channelName),
            (MethodCall methodCall) async {
      call = methodCall;
      return null;
    });
    await engine.updateWithVisualMeasurement(
        transform: List.filled(16, 2.0), confidence: 0.8);
    expect(call?.method, 'updateWithVisualMeasurement');
    expect(call?.arguments['confidence'], 0.8);
  });

  test('getFusedTransform returns value from channel', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(channelName),
            (MethodCall methodCall) async {
      return List<double>.filled(16, 1.0);
    });
    final result = await engine.getFusedTransform();
    expect(result.length, 16);
    expect(result[0], 1.0);
  });

  test('placeCaption forwards to caption channel', () async {
    MethodCall? captionCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(channelName),
            (MethodCall methodCall) async {
      return List<double>.filled(16, 1.0);
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(captionChannelName),
            (MethodCall methodCall) async {
      captionCall = methodCall;
      return null;
    });
    await engine.placeCaption('hello');
    expect(captionCall?.method, 'placeCaption');
    expect(captionCall?.arguments['text'], 'hello');
  });

  test('placeCaption fallback works when primary placement fails', () async {
    List<MethodCall> captionCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(channelName),
            (MethodCall methodCall) async {
      return List<double>.filled(16, 1.0);
    });

    // Set up the caption channel to fail first call, then succeed on fallback
    bool firstCallMade = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(captionChannelName),
            (MethodCall methodCall) async {
      captionCalls.add(methodCall);
      if (!firstCallMade) {
        firstCallMade = true;
        throw PlatformException(
            code: 'SESSION_NOT_READY', message: 'AR Session not ready');
      }
      return null; // Success on second call
    });

    await engine.placeCaption('test caption');

    // Should have made two calls - first fails, second succeeds with fallback
    expect(captionCalls.length, 2);
    expect(captionCalls[0].method, 'placeCaption');
    expect(captionCalls[0].arguments['text'], 'test caption');
    expect(captionCalls[1].method, 'placeCaption');
    expect(captionCalls[1].arguments['text'], 'test caption');
    // Second call should use default transform (fallback)
    expect(captionCalls[1].arguments['transform'], isA<List<double>>());
    // verify that the default transform is an identity matrix
    final defaultTransform = List.generate(16,
        (index) => index % 5 == 0 ? (index == 15 ? 1.0 : (index < 12 ? 1.0 : 0.0)) : 0.0);
    expect(listEquals(captionCalls[1].arguments['transform'], defaultTransform), isTrue);
  });
}
