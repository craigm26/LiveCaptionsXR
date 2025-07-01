import 'package:flutter_test/flutter_test.dart';
import 'package:gemma3n_multimodal/gemma3n_multimodal.dart';
import 'package:gemma3n_multimodal/gemma3n_multimodal_platform_interface.dart';
import 'package:gemma3n_multimodal/gemma3n_multimodal_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockGemma3nMultimodalPlatform
    with MockPlatformInterfaceMixin
    implements Gemma3nMultimodalPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final Gemma3nMultimodalPlatform initialPlatform = Gemma3nMultimodalPlatform.instance;

  test('$MethodChannelGemma3nMultimodal is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelGemma3nMultimodal>());
  });

  test('getPlatformVersion', () async {
    Gemma3nMultimodal gemma3nMultimodalPlugin = Gemma3nMultimodal();
    MockGemma3nMultimodalPlatform fakePlatform = MockGemma3nMultimodalPlatform();
    Gemma3nMultimodalPlatform.instance = fakePlatform;

    expect(await gemma3nMultimodalPlugin.getPlatformVersion(), '42');
  });
}
