import 'package:flutter/services.dart';
import 'models/models.dart';

class LlmWrapper {
  static const MethodChannel _channel = MethodChannel('nexa_ai_flutter');
  static const EventChannel _streamChannel = EventChannel('nexa_ai_flutter/llm_stream');

  String? _wrapperId;

  LlmWrapper._();

  /// Create and load an LLM model
  static Future<LlmWrapper> create(LlmCreateInput input) async {
    try {
      final wrapper = LlmWrapper._();
      final result = await _channel.invokeMethod('createLlm', input.toMap());
      wrapper._wrapperId = result as String;
      return wrapper;
    } on PlatformException catch (e) {
      throw Exception('Failed to create LLM: ${e.message}');
    }
  }

  /// Apply chat template to format messages
  Future<ChatTemplateOutput> applyChatTemplate(
    List<ChatMessage> messages, {
    String? tools,
    bool enableThinking = false,
  }) async {
    try {
      final result = await _channel.invokeMethod('applyChatTemplate', {
        'wrapperId': _wrapperId,
        'messages': messages.map((m) => m.toMap()).toList(),
        if (tools != null) 'tools': tools,
        'enableThinking': enableThinking,
      });
      return ChatTemplateOutput.fromMap(Map<String, dynamic>.from(result as Map));
    } on PlatformException catch (e) {
      throw Exception('Failed to apply chat template: ${e.message}');
    }
  }

  /// Generate text with streaming support
  /// Returns a stream of LlmStreamResult events
  Stream<LlmStreamResult> generateStream(
    String prompt,
    GenerationConfig config,
  ) {
    return _streamChannel.receiveBroadcastStream({
      'wrapperId': _wrapperId,
      'prompt': prompt,
      'config': config.toMap(),
    }).map((event) {
      final map = event as Map<dynamic, dynamic>;
      final type = map['type'] as String;

      switch (type) {
        case 'token':
          return LlmStreamToken(map['text'] as String);
        case 'completed':
          return LlmStreamCompleted(
            GenerationProfile.fromMap(
              Map<String, dynamic>.from(map['profile'] as Map),
            ),
          );
        case 'error':
          return LlmStreamError(map['message'] as String);
        default:
          return LlmStreamError('Unknown stream event type: $type');
      }
    });
  }

  /// Stop the current stream generation
  Future<void> stopStream() async {
    try {
      await _channel.invokeMethod('stopStream', {'wrapperId': _wrapperId});
    } on PlatformException catch (e) {
      throw Exception('Failed to stop stream: ${e.message}');
    }
  }

  /// Reset the conversation history
  Future<void> reset() async {
    try {
      await _channel.invokeMethod('reset', {'wrapperId': _wrapperId});
    } on PlatformException catch (e) {
      throw Exception('Failed to reset: ${e.message}');
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
