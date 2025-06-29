import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'gemma3n_multimodal_flutter_platform_interface.dart';

/// An implementation of [Gemma3nMultimodalFlutterPlatform] that uses method channels.
class MethodChannelGemma3nMultimodalFlutter extends Gemma3nMultimodalFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('gemma3n_multimodal_flutter');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
