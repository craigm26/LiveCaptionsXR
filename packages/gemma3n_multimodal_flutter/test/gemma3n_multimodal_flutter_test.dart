import 'package:flutter/services.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemma3n_multimodal_flutter/gemma3n_multimodal_flutter.dart';
import 'package:gemma3n_multimodal_flutter/gemma3n_multimodal_flutter_platform_interface.dart';
import 'package:gemma3n_multimodal_flutter/gemma3n_multimodal_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockGemma3nMultimodalFlutterPlatform
    with MockPlatformInterfaceMixin
    implements Gemma3nMultimodalFlutterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final Gemma3nMultimodalFlutterPlatform initialPlatform = Gemma3nMultimodalFlutterPlatform.instance;

  test('$MethodChannelGemma3nMultimodalFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelGemma3nMultimodalFlutter>());
  });

  test('getPlatformVersion', () async {
    MockGemma3nMultimodalFlutterPlatform fakePlatform = MockGemma3nMultimodalFlutterPlatform();
    Gemma3nMultimodalFlutterPlatform.instance = fakePlatform;

    expect(await Gemma3nMultimodalFlutter.platformVersion, '42');
  });
}
