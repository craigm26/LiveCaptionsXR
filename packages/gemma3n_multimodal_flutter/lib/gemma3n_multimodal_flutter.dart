import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

class Gemma3nMultimodalFlutter {
  static const MethodChannel _channel =
      const MethodChannel('gemma3n_multimodal_flutter');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}

/// Represents a Gemma 3n multimodal model loaded via MediaPipe.
class GemmaTaskModel {
  final String assetPath;
  static const MethodChannel _channel =
      const MethodChannel('gemma3n_multimodal_flutter');

  GemmaTaskModel._(this.assetPath);

  /// Creates and initializes a new Gemma 3n model from the given asset path.
  static Future<GemmaTaskModel> create(String assetPath) async {
    await _channel.invokeMethod('create', {'assetPath': assetPath});
    return GemmaTaskModel._(assetPath);
  }

  /// Creates a new inference session for this model.
  Future<Session> createSession({bool supportImage = false}) async {
    await _channel.invokeMethod('createSession');
    return Session._(this);
  }

  Future<void> close() async {
    await _channel.invokeMethod('close', {'assetPath': assetPath});
  }
}

/// Represents an inference session for a Gemma 3n model.
class Session {
  final GemmaTaskModel model;
  final List<Message> _query = [];
  static const MethodChannel _channel =
      const MethodChannel('gemma3n_multimodal_flutter');

  Session._(this.model);

  /// Adds a query chunk (text or image) to the current session.
  Future<void> addQueryChunk(Message message) async {
    _query.add(message);
  }

  /// Gets the generated response from the model.
  Future<String> getResponse() async {
    final queryMessages = _query.map((m) {
      return {
        'isUser': m.isUser,
        'text': m.text,
        'imageBytes': m.imageBytes,
      };
    }).toList();

    final response = await _channel.invokeMethod('getResponse', {
      'assetPath': model.assetPath,
      'query': queryMessages,
    });
    return response;
  }

  /// Closes the session and releases resources.
  Future<void> close() async {
    // No-op in this simplified implementation
  }
}

/// Represents a message chunk, which can be text or an image.
class Message {
  final bool isUser;
  final String? text;
  final Uint8List? imageBytes;

  Message._({this.isUser = false, this.text, this.imageBytes});

  /// Creates a text message.
  factory Message.text({required String text, required bool isUser}) {
    return Message._(text: text, isUser: isUser);
  }

  /// Creates an image-only message.
  factory Message.imageOnly({required Uint8List imageBytes, required bool isUser}) {
    return Message._(imageBytes: imageBytes, isUser: isUser);
  }
}
