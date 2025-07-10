import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'gemma3n_multimodal_platform_interface.dart';

/// An implementation of [Gemma3nMultimodalPlatform] that uses method channels.
class MethodChannelGemma3nMultimodal extends Gemma3nMultimodalPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('gemma3n_multimodal');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
