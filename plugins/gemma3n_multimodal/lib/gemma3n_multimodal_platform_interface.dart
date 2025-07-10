import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'gemma3n_multimodal_method_channel.dart';

abstract class Gemma3nMultimodalPlatform extends PlatformInterface {
  /// Constructs a Gemma3nMultimodalPlatform.
  Gemma3nMultimodalPlatform() : super(token: _token);

  static final Object _token = Object();

  static Gemma3nMultimodalPlatform _instance = MethodChannelGemma3nMultimodal();

  /// The default instance of [Gemma3nMultimodalPlatform] to use.
  ///
  /// Defaults to [MethodChannelGemma3nMultimodal].
  static Gemma3nMultimodalPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [Gemma3nMultimodalPlatform] when
  /// they register themselves.
  static set instance(Gemma3nMultimodalPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
