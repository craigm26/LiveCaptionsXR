import 'package:flutter/services.dart';
import 'models/models.dart';

class RerankerWrapper {
  static const MethodChannel _channel = MethodChannel('nexa_ai_flutter');

  String? _wrapperId;

  RerankerWrapper._();

  /// Create and load a Reranker model
  static Future<RerankerWrapper> create(RerankerCreateInput input) async {
    try {
      final wrapper = RerankerWrapper._();
      final result = await _channel.invokeMethod('createReranker', input.toMap());
      wrapper._wrapperId = result as String;
      return wrapper;
    } on PlatformException catch (e) {
      throw Exception('Failed to create Reranker: ${e.message}');
    }
  }

  /// Rerank documents based on query relevance
  Future<RerankerResult> rerank(
    String query,
    List<String> documents,
    RerankConfig config,
  ) async {
    try {
      final result = await _channel.invokeMethod('rerank', {
        'wrapperId': _wrapperId,
        'query': query,
        'documents': documents,
        'config': config.toMap(),
      });
      return RerankerResult.fromMap(result as Map<String, dynamic>);
    } on PlatformException catch (e) {
      throw Exception('Failed to rerank: ${e.message}');
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
