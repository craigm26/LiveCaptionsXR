import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'gemma3n_multimodal_flutter_method_channel.dart';

abstract class Gemma3nMultimodalFlutterPlatform extends PlatformInterface {
  /// Constructs a Gemma3nMultimodalFlutterPlatform.
  Gemma3nMultimodalFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static Gemma3nMultimodalFlutterPlatform _instance = MethodChannelGemma3nMultimodalFlutter();

  /// The default instance of [Gemma3nMultimodalFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelGemma3nMultimodalFlutter].
  static Gemma3nMultimodalFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [Gemma3nMultimodalFlutterPlatform] when
  /// they register themselves.
  static set instance(Gemma3nMultimodalFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
