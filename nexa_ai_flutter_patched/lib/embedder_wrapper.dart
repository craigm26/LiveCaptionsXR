import 'package:flutter/services.dart';
import 'models/models.dart';

class EmbedderWrapper {
  static const MethodChannel _channel = MethodChannel('nexa_ai_flutter');

  String? _wrapperId;

  EmbedderWrapper._();

  /// Create and load an Embedder model
  static Future<EmbedderWrapper> create(EmbedderCreateInput input) async {
    try {
      final wrapper = EmbedderWrapper._();
      final result = await _channel.invokeMethod('createEmbedder', input.toMap());
      wrapper._wrapperId = result as String;
      return wrapper;
    } on PlatformException catch (e) {
      throw Exception('Failed to create Embedder: ${e.message}');
    }
  }

  /// Generate embeddings for multiple texts
  /// Returns a flat list of embedding values
  /// The dimension is embeddings.length / texts.length
  Future<List<double>> embed(
    List<String> texts,
    EmbeddingConfig config,
  ) async {
    try {
      final result = await _channel.invokeMethod('embed', {
        'wrapperId': _wrapperId,
        'texts': texts,
        'config': config.toMap(),
      });
      return (result as List<dynamic>).cast<double>();
    } on PlatformException catch (e) {
      throw Exception('Failed to generate embeddings: ${e.message}');
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
