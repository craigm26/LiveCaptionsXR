import 'dart:async';
import 'package:flutter/services.dart';
import 'app_logger.dart';

/// Service for capturing visual frames from ARKit on iOS
class ARFrameService {
  static const _channel = MethodChannel('live_captions_xr/ar_frames');
  final AppLogger _logger = AppLogger.instance;

  bool _isInitialized = false;

  ARFrameService() {
    _logger.i('🏗️ Initializing ARFrameService...', category: LogCategory.ar);
    _isInitialized = true;
    _logger.i('✅ ARFrameService initialized successfully', category: LogCategory.ar);
  }

  /// Captures a single frame from the current ARKit session
  /// Returns JPEG image data as Uint8List, or null if capture fails
  Future<Uint8List?> captureFrame() async {
    if (!_isInitialized) {
      _logger.e('❌ ARFrameService not initialized', category: LogCategory.ar);
      return null;
    }

    try {
      _logger.d('📸 Requesting ARKit frame capture...', category: LogCategory.ar);
      final Uint8List? result = await _channel.invokeMethod('captureFrame');
      
      if (result != null) {
        _logger.i('✅ ARKit frame captured: ${result.lengthInBytes} bytes', category: LogCategory.ar);
        return result;
      } else {
        _logger.w('⚠️ ARKit frame capture returned null', category: LogCategory.ar);
        return null;
      }
    } on PlatformException catch (e, stackTrace) {
      _logger.e('❌ Platform exception during ARKit frame capture', 
          category: LogCategory.ar, error: e, stackTrace: stackTrace);
      return null;
    } catch (e, stackTrace) {
      _logger.e('❌ Unexpected error during ARKit frame capture', 
          category: LogCategory.ar, error: e, stackTrace: stackTrace);
      return null;
    }
  }

  bool get isInitialized => _isInitialized;

  void dispose() {
    _logger.i('🗑️ Disposing ARFrameService...', category: LogCategory.ar);
    _isInitialized = false;
    _logger.d('✅ ARFrameService disposed successfully', category: LogCategory.ar);
  }
}