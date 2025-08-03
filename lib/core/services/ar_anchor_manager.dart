import 'dart:async';
import 'package:flutter/services.dart';
import 'app_logger.dart';

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
  static final AppLogger _logger = AppLogger.instance;

  /// Create an AR anchor at a given horizontal angle (radians) and distance (meters) from the camera.
  /// Returns the anchor identifier.
  Future<String> createAnchorAtAngle(double angle,
      {double distance = 2.0}) async {
    _logger.i(
        '🎯 Creating AR anchor at angle: ${angle.toStringAsFixed(3)} rad (${(angle * 180 / 3.14159).toStringAsFixed(1)}°), distance: ${distance}m', category: LogCategory.ar);

    try {
      final id =
          await _methodChannel.invokeMethod<String>('createAnchorAtAngle', {
        'angle': angle,
        'distance': distance,
      });

      final anchorId = id ?? '';
      if (anchorId.isNotEmpty) {
        _logger.i('✅ AR anchor created successfully with ID: $anchorId', category: LogCategory.ar);
      } else {
        _logger.w('⚠️ AR anchor creation returned empty ID', category: LogCategory.ar);
      }

      return anchorId;
    } catch (e) {
      _logger.e('❌ Failed to create AR anchor at angle: $e', category: LogCategory.ar);
      rethrow;
    }
  }

  /// Create an AR anchor at a given 4x4 world transform (from visual localization).
  /// [transform] should be a 16-element list (row-major order).
  Future<String> createAnchorAtWorldTransform(List<double> transform) async {
    _logger.i(
        '🌍 Creating AR anchor at world transform: [${transform.take(4).map((v) => v.toStringAsFixed(3)).join(', ')}...]', category: LogCategory.ar);

    if (transform.length != 16) {
      _logger.e(
          '❌ Invalid transform matrix length: ${transform.length}, expected 16', category: LogCategory.ar);
      throw ArgumentError('Transform matrix must have exactly 16 elements');
    }

    try {
      final id = await _methodChannel
          .invokeMethod<String>('createAnchorAtWorldTransform', {
        'transform': transform,
      });

      final anchorId = id ?? '';
      if (anchorId.isNotEmpty) {
        _logger.i('✅ AR anchor created at world transform with ID: $anchorId', category: LogCategory.ar);
      } else {
        _logger.w('⚠️ AR anchor creation at world transform returned empty ID', category: LogCategory.ar);
      }

      return anchorId;
    } catch (e) {
      _logger.e('❌ Failed to create AR anchor at world transform: $e', category: LogCategory.ar);
      rethrow;
    }
  }

  /// Remove an AR anchor by its identifier.
  Future<void> removeAnchor(String identifier) async {
    _logger.i('🗑️ Removing AR anchor with ID: $identifier', category: LogCategory.ar);

    try {
      await _methodChannel.invokeMethod('removeAnchor', {
        'identifier': identifier,
      });
      _logger.i('✅ AR anchor removed successfully: $identifier', category: LogCategory.ar);
    } catch (e) {
      _logger.e('❌ Failed to remove AR anchor $identifier: $e', category: LogCategory.ar);
      rethrow;
    }
  }

  /// Get the current device orientation from the AR session.
  /// This method also validates that the AR session is ready for anchor operations.
  /// Includes retry logic to handle session initialization delays.
  Future<List<double>> getDeviceOrientation({int maxRetries = 3}) async {
    _logger.d('📱 Getting device orientation for AR session validation...', category: LogCategory.ar);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final result = await _methodChannel.invokeMethod<List<dynamic>>('getDeviceOrientation');
        if (result == null) {
          throw Exception('getDeviceOrientation returned null');
        }
        
        final orientation = result.cast<double>();
        if (orientation.length != 16) {
          throw Exception('Invalid device orientation matrix length: ${orientation.length}');
        }
        
        _logger.d('✅ Device orientation retrieved successfully', category: LogCategory.ar);
        return orientation;
      } catch (e) {
        if (attempt < maxRetries && e.toString().contains('NO_SESSION')) {
          _logger.w('⚠️ AR session not ready (attempt $attempt/$maxRetries), retrying in 500ms...', category: LogCategory.ar);
          await Future.delayed(const Duration(milliseconds: 500));
          continue;
        }
        
        _logger.e('❌ Failed to get device orientation (attempt $attempt/$maxRetries): $e', category: LogCategory.ar);
        if (attempt == maxRetries) {
          rethrow;
        }
      }
    }
    
    throw Exception('Failed to get device orientation after $maxRetries attempts');
  }

  // Optionally: add methods to list anchors, get anchor info, etc.
}
