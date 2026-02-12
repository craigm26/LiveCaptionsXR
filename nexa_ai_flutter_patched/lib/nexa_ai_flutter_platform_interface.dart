import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'nexa_ai_flutter_method_channel.dart';

abstract class NexaAiFlutterPlatform extends PlatformInterface {
  /// Constructs a NexaAiFlutterPlatform.
  NexaAiFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static NexaAiFlutterPlatform _instance = MethodChannelNexaAiFlutter();

  /// The default instance of [NexaAiFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelNexaAiFlutter].
  static NexaAiFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NexaAiFlutterPlatform] when
  /// they register themselves.
  static set instance(NexaAiFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
