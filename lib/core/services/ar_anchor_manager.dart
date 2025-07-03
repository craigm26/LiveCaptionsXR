import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

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
  static const MethodChannel _methodChannel =
      MethodChannel('live_captions_xr/ar_anchor_methods');
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  /// Create an AR anchor at a given horizontal angle (radians) and distance (meters) from the camera.
  /// Returns the anchor identifier.
  Future<String> createAnchorAtAngle(double angle,
      {double distance = 2.0}) async {
    _logger.i(
        '🎯 Creating AR anchor at angle: ${angle.toStringAsFixed(3)} rad (${(angle * 180 / 3.14159).toStringAsFixed(1)}°), distance: ${distance}m');

    try {
      final id =
          await _methodChannel.invokeMethod<String>('createAnchorAtAngle', {
        'angle': angle,
        'distance': distance,
      });

      final anchorId = id ?? '';
      if (anchorId.isNotEmpty) {
        _logger.i('✅ AR anchor created successfully with ID: $anchorId');
      } else {
        _logger.w('⚠️ AR anchor creation returned empty ID');
      }

      return anchorId;
    } catch (e) {
      _logger.e('❌ Failed to create AR anchor at angle: $e');
      rethrow;
    }
  }

  /// Create an AR anchor at a given 4x4 world transform (from visual localization).
  /// [transform] should be a 16-element list (row-major order).
  Future<String> createAnchorAtWorldTransform(List<double> transform) async {
    _logger.i(
        '🌍 Creating AR anchor at world transform: [${transform.take(4).map((v) => v.toStringAsFixed(3)).join(', ')}...]');

    if (transform.length != 16) {
      _logger.e(
          '❌ Invalid transform matrix length: ${transform.length}, expected 16');
      throw ArgumentError('Transform matrix must have exactly 16 elements');
    }

    try {
      final id = await _methodChannel
          .invokeMethod<String>('createAnchorAtWorldTransform', {
        'transform': transform,
      });

      final anchorId = id ?? '';
      if (anchorId.isNotEmpty) {
        _logger.i('✅ AR anchor created at world transform with ID: $anchorId');
      } else {
        _logger.w('⚠️ AR anchor creation at world transform returned empty ID');
      }

      return anchorId;
    } catch (e) {
      _logger.e('❌ Failed to create AR anchor at world transform: $e');
      rethrow;
    }
  }

  /// Remove an AR anchor by its identifier.
  Future<void> removeAnchor(String identifier) async {
    _logger.i('🗑️ Removing AR anchor with ID: $identifier');

    try {
      await _methodChannel.invokeMethod('removeAnchor', {
        'identifier': identifier,
      });
      _logger.i('✅ AR anchor removed successfully: $identifier');
    } catch (e) {
      _logger.e('❌ Failed to remove AR anchor $identifier: $e');
      rethrow;
    }
  }

  // Optionally: add methods to list anchors, get anchor info, etc.
}
