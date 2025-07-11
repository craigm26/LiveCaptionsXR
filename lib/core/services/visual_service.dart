import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'debug_capturing_logger.dart';

/// A service for capturing visual snapshots from the device's camera.
///
/// This service interfaces with native code (Swift/Kotlin) to capture
/// a single frame from the camera feed.
class VisualService {
  static const _channel = MethodChannel('com.craig.livecaptions/visual');

  static final DebugCapturingLogger _logger = DebugCapturingLogger();

  VisualService() {
    _logger.i('🏗️ Initializing VisualService...');
    _logger.d('✅ VisualService initialized successfully');
  }

  /// Captures a single visual snapshot from the device's camera.
  ///
  /// This will activate the camera, capture a single frame, and return it
  /// as a byte array (Uint8List). It will then release the camera.
  /// Returns null if the capture fails.
  Future<Uint8List?> captureVisualSnapshot() async {
    try {
      _logger.i('📸 Capturing visual snapshot...');
      final Uint8List? result =
          await _channel.invokeMethod('captureVisualSnapshot');
      if (result != null) {
        _logger.i(
            '✅ Visual snapshot captured successfully (${result.lengthInBytes} bytes)');
      } else {
        _logger.w('⚠️ Visual snapshot capture returned null.');
      }
      return result;
    } on PlatformException catch (e, stackTrace) {
      _logger.e('❌ Failed to capture visual snapshot',
          error: e, stackTrace: stackTrace);
      return null;
    } catch (e, stackTrace) {
      _logger.e('❌ Unexpected error capturing visual snapshot',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  void dispose() {
    _logger.i('🗑️ Disposing VisualService...');
    // No resources to dispose in this version.
    _logger.d('✅ VisualService disposed successfully');
  }
}
