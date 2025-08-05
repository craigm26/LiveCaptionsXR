import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_captions_xr/core/services/hybrid_localization_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channelName = 'live_captions_xr/hybrid_localization_methods';
  final engine = HybridLocalizationEngine();

  setUp(() {
    // No setup needed here, will be handled in each test
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(channelName), null);
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

  // Note: placeRealtimeCaption method was removed as caption placement 
  // is now handled exclusively by the spatial_captions plugin
}
