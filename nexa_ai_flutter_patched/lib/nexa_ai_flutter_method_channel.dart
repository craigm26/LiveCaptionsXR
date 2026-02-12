import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'nexa_ai_flutter_platform_interface.dart';

/// An implementation of [NexaAiFlutterPlatform] that uses method channels.
class MethodChannelNexaAiFlutter extends NexaAiFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('nexa_ai_flutter');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
