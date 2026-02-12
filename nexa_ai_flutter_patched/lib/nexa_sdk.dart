import 'package:flutter/services.dart';

class NexaSdk {
  static NexaSdk? _instance;
  static const MethodChannel _channel = MethodChannel('nexa_ai_flutter');

  NexaSdk._();

  static NexaSdk getInstance() {
    _instance ??= NexaSdk._();
    return _instance!;
  }

  /// Initialize the Nexa SDK
  /// This must be called before using any model wrappers
  Future<void> init() async {
    try {
      await _channel.invokeMethod('initializeSdk');
    } on PlatformException catch (e) {
      throw Exception('Failed to initialize Nexa SDK: ${e.message}');
    }
  }
}
