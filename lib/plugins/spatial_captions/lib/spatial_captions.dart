import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart';

class SpatialCaptions {
  static const MethodChannel _channel = MethodChannel('spatial_captions');

  /// Add a new caption at a specific position
  static Future<void> addCaption({
    required String id,
    required String text,
    required Vector3 position,
    CaptionType type = CaptionType.partial,
    String? speakerId,
  }) async {
    await _channel.invokeMethod('addCaption', {
      'id': id,
      'text': text,
      'x': position.x,
      'y': position.y,
      'z': position.z,
      'type': type.toString(),
      'speakerId': speakerId,
    });
  }

  /// Update an existing caption's text or position
  static Future<void> updateCaption({
    required String id,
    String? text,
    Vector3? position,
    CaptionType? type,
  }) async {
    await _channel.invokeMethod('updateCaption', {
      'id': id,
      'text': text,
      'x': position?.x,
      'y': position?.y,
      'z': position?.z,
      'type': type?.toString(),
    });
  }

  /// Replace a caption with a new one (for partial → final transitions)
  static Future<void> replaceCaption({
    required String oldId,
    required String newId,
    required String text,
    CaptionType type = CaptionType.final_,
  }) async {
    await _channel.invokeMethod('replaceCaption', {
      'oldId': oldId,
      'newId': newId,
      'text': text,
      'type': type.toString(),
    });
  }

  /// Remove a caption by ID
  static Future<void> removeCaption(String id) async {
    await _channel.invokeMethod('removeCaption', {'id': id});
  }

  /// Clear all captions
  static Future<void> clearCaptions() async {
    await _channel.invokeMethod('clearCaptions');
  }

  /// Set caption display duration
  static Future<void> setCaptionDuration(Duration duration) async {
    await _channel.invokeMethod('setCaptionDuration', {
      'seconds': duration.inSeconds,
    });
  }

  /// Lock orientation to landscape mode
  static Future<void> setOrientationLock(bool lockLandscape) async {
    await _channel.invokeMethod('setOrientationLock', {
      'lockLandscape': lockLandscape,
    });
  }
}

enum CaptionType {
  partial,    // Real-time partial results
  final_,     // Final transcription result
  enhanced,   // Enhanced by Gemma
} 