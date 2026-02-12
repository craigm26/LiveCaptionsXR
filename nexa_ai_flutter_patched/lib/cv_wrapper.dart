import 'package:flutter/services.dart';
import 'models/models.dart';

class CvWrapper {
  static const MethodChannel _channel = MethodChannel('nexa_ai_flutter');

  String? _wrapperId;

  CvWrapper._();

  /// Create and load a Computer Vision model
  static Future<CvWrapper> create(CVCreateInput input) async {
    try {
      final wrapper = CvWrapper._();
      final result = await _channel.invokeMethod('createCv', input.toMap());
      wrapper._wrapperId = result as String;
      return wrapper;
    } on PlatformException catch (e) {
      throw Exception('Failed to create CV: ${e.message}');
    }
  }

  /// Perform inference on an image
  /// For OCR: returns text recognition results
  /// For detection: returns detected objects
  /// For classification: returns class predictions
  Future<List<CVResult>> infer(String imagePath) async {
    try {
      final result = await _channel.invokeMethod('cvInfer', {
        'wrapperId': _wrapperId,
        'imagePath': imagePath,
      });
      return (result as List<dynamic>)
          .map((e) => CVResult.fromMap(e as Map<String, dynamic>))
          .toList();
    } on PlatformException catch (e) {
      throw Exception('Failed to perform CV inference: ${e.message}');
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
