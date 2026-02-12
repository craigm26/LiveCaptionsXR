import 'package:flutter/services.dart';
import 'models/models.dart';

class AsrWrapper {
  static const MethodChannel _channel = MethodChannel('nexa_ai_flutter');

  String? _wrapperId;

  AsrWrapper._();

  /// Create and load an ASR model
  static Future<AsrWrapper> create(AsrCreateInput input) async {
    try {
      final wrapper = AsrWrapper._();
      final result = await _channel.invokeMethod('createAsr', input.toMap());
      wrapper._wrapperId = result as String;
      return wrapper;
    } on PlatformException catch (e) {
      throw Exception('Failed to create ASR: ${e.message}');
    }
  }

  /// Transcribe audio file to text
  Future<AsrTranscriptionResult> transcribe(AsrTranscribeInput input) async {
    try {
      final result = await _channel.invokeMethod('transcribe', {
        'wrapperId': _wrapperId,
        ...input.toMap(),
      });
      return AsrTranscriptionResult.fromMap(result as Map<String, dynamic>);
    } on PlatformException catch (e) {
      throw Exception('Failed to transcribe: ${e.message}');
    }
  }

  /// Destroy the model and free resources
  Future<void> destroy() async {
    try {
      await _channel.invokeMethod('destroy', {'wrapperId': _wrapperId});
      _wrapperId = null;
    } on PlatformException catch (e) {
      throw Exception('Failed to destroy: ${e.message}');
    }
  }
}
