import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_ai_flutter/nexa_ai_flutter_platform_interface.dart';
import 'package:nexa_ai_flutter/nexa_ai_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNexaAiFlutterPlatform
    with MockPlatformInterfaceMixin
    implements NexaAiFlutterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final NexaAiFlutterPlatform initialPlatform = NexaAiFlutterPlatform.instance;

  test('$MethodChannelNexaAiFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNexaAiFlutter>());
  });

  test('getPlatformVersion', () async {
  });
}
