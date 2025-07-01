import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';

/// Model for AR anchor info.
class ARAnchorInfo {
  final String identifier;
  final List<double> transform; // 4x4 matrix as 16 doubles (row-major)

  ARAnchorInfo({required this.identifier, required this.transform});
}

/// ARAnchorManager: Handles ARKit anchor creation and management via platform channels.
///
/// - Creates anchors from audio direction or visual 3D position.
/// - Removes anchors when no longer needed.
/// - Integrates with AR/caption UI for spatially-anchored captions.
class ARAnchorManager {
  static const MethodChannel _methodChannel = MethodChannel('live_captions_xr/ar_anchor_methods');

  /// Create an AR anchor at a given horizontal angle (radians) and distance (meters) from the camera.
  /// Returns the anchor identifier.
  Future<String> createAnchorAtAngle(double angle, {double distance = 2.0}) async {
    final id = await _methodChannel.invokeMethod<String>('createAnchorAtAngle', {
      'angle': angle,
      'distance': distance,
    });
    return id ?? '';
  }

  /// Create an AR anchor at a given 4x4 world transform (from visual localization).
  /// [transform] should be a 16-element list (row-major order).
  Future<String> createAnchorAtWorldTransform(List<double> transform) async {
    final id = await _methodChannel.invokeMethod<String>('createAnchorAtWorldTransform', {
      'transform': transform,
    });
    return id ?? '';
  }

  /// Remove an AR anchor by its identifier.
  Future<void> removeAnchor(String identifier) async {
    await _methodChannel.invokeMethod('removeAnchor', {
      'identifier': identifier,
    });
  }

  // Optionally: add methods to list anchors, get anchor info, etc.
}
