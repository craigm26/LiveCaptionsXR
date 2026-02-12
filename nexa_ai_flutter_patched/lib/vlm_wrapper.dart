import 'package:flutter/services.dart';
import 'models/models.dart';

class VlmWrapper {
  static const MethodChannel _channel = MethodChannel('nexa_ai_flutter');
  static const EventChannel _streamChannel = EventChannel('nexa_ai_flutter/vlm_stream');

  String? _wrapperId;

  VlmWrapper._();

  /// Create and load a VLM model
  static Future<VlmWrapper> create(VlmCreateInput input) async {
    try {
      final wrapper = VlmWrapper._();
      final result = await _channel.invokeMethod('createVlm', input.toMap());
      wrapper._wrapperId = result as String;
      return wrapper;
    } on PlatformException catch (e) {
      throw Exception('Failed to create VLM: ${e.message}');
    }
  }

  /// Apply chat template to format VLM messages
  Future<ChatTemplateOutput> applyChatTemplate(
    List<VlmChatMessage> messages, {
    String? tools,
    bool enableThinking = false,
  }) async {
    try {
      final result = await _channel.invokeMethod('applyVlmChatTemplate', {
        'wrapperId': _wrapperId,
        'messages': messages.map((m) => m.toMap()).toList(),
        if (tools != null) 'tools': tools,
        'enableThinking': enableThinking,
      });
      return ChatTemplateOutput.fromMap(Map<String, dynamic>.from(result as Map));
    } on PlatformException catch (e) {
      throw Exception('Failed to apply VLM chat template: ${e.message}');
    }
  }

  /// Inject media paths (images/audio) into generation config
  GenerationConfig injectMediaPathsToConfig(
    List<VlmChatMessage> messages,
    GenerationConfig baseConfig,
  ) {
    final imagePaths = <String>[];
    final audioPaths = <String>[];

    for (final message in messages) {
      for (final content in message.contents) {
        if (content.type == 'image') {
          imagePaths.add(content.content);
        } else if (content.type == 'audio') {
          audioPaths.add(content.content);
        }
      }
    }

    return GenerationConfig(
      maxTokens: baseConfig.maxTokens,
      stopWords: baseConfig.stopWords,
      stopCount: baseConfig.stopCount,
      nPast: baseConfig.nPast,
      samplerConfig: baseConfig.samplerConfig,
      imagePaths: imagePaths.isNotEmpty ? imagePaths : baseConfig.imagePaths,
      imageCount: imagePaths.isNotEmpty ? imagePaths.length : baseConfig.imageCount,
      audioPaths: audioPaths.isNotEmpty ? audioPaths : baseConfig.audioPaths,
      audioCount: audioPaths.isNotEmpty ? audioPaths.length : baseConfig.audioCount,
    );
  }

  /// Generate text with streaming support (handles images and audio)
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
