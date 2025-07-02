import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_captions_xr/core/services/ar_anchor_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channelName = 'live_captions_xr/ar_anchor_methods';
  final manager = ARAnchorManager();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(channelName), null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(channelName), null);
  });

  test('createAnchorAtAngle sends angle and distance', () async {
    MethodCall? call;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(channelName),
            (MethodCall methodCall) async {
      call = methodCall;
      return 'id1';
    });
    final id = await manager.createAnchorAtAngle(1.0, distance: 3.0);
    expect(id, 'id1');
    expect(call?.method, 'createAnchorAtAngle');
    expect(call?.arguments['angle'], 1.0);
    expect(call?.arguments['distance'], 3.0);
  });

  test('createAnchorAtWorldTransform sends transform', () async {
    MethodCall? call;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(channelName),
            (MethodCall methodCall) async {
      call = methodCall;
      return 'id2';
    });
    final id = await manager.createAnchorAtWorldTransform(List.filled(16, 1.0));
    expect(id, 'id2');
    expect(call?.method, 'createAnchorAtWorldTransform');
  });

  test('removeAnchor sends identifier', () async {
    MethodCall? call;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(channelName),
            (MethodCall methodCall) async {
      call = methodCall;
      return null;
    });
    await manager.removeAnchor('abc');
    expect(call?.method, 'removeAnchor');
    expect(call?.arguments['identifier'], 'abc');
  });
}
