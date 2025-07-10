import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemma3n_multimodal/gemma3n_multimodal_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelGemma3nMultimodal platform = MethodChannelGemma3nMultimodal();
  const MethodChannel channel = MethodChannel('gemma3n_multimodal');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
