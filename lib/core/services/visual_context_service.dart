import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'debug_capturing_logger.dart';

/// Service for extracting textual context from a visual scene.
class VisualContextService {
  static const MethodChannel _methodChannel = MethodChannel('live_captions_xr/visual_context_methods');
  static final DebugCapturingLogger _logger = DebugCapturingLogger();

  /// Captures a visual snapshot and returns a textual description of the scene.
  Future<String?> getVisualContext() async {
    try {
      _logger.d('📸 Capturing visual context...');
      final String? context = await _methodChannel.invokeMethod('getVisualContext');
      _logger.d('🖼️ Visual context: $context');
      return context;
    } catch (e, stackTrace) {
      _logger.e('❌ Error getting visual context', error: e, stackTrace: stackTrace);
      return null;
    }
  }
} 