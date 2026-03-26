import 'dart:io';

import 'package:flutter/services.dart';

import 'app_logger.dart';

/// Service for detecting and interacting with Samsung XR AI Glasses
/// via the Jetpack XR SDK projected activity pattern.
///
/// This wraps the native [GlassesPlugin] MethodChannel to provide:
/// - Glasses connection detection (via ProjectedContext)
/// - Glasses capability queries (visual UI, etc.)
/// - Launching the native GlassesActivity with projected context
/// - Forwarding captions to the glasses display
class GlassesService {
  static final AppLogger _logger = AppLogger.instance;

  static const MethodChannel _channel =
      MethodChannel('live_captions_xr/glasses');

  bool _isConnected = false;

  /// Whether glasses are currently known to be connected.
  bool get isConnected => _isConnected;

  /// Check if AI glasses are connected via Jetpack XR SDK.
  /// Returns false on non-Android platforms.
  Future<bool> isGlassesConnected() async {
    if (!Platform.isAndroid) return false;

    try {
      final result = await _channel.invokeMethod<bool>('isGlassesAvailable');
      _isConnected = result ?? false;
      _logger.d('Glasses connected: $_isConnected');
      return _isConnected;
    } catch (e) {
      _logger.e('Failed to check glasses connection', error: e);
      _isConnected = false;
      return false;
    }
  }

  /// Get the capabilities of the connected glasses.
  /// Returns a map with 'visualUi' (bool) and 'capabilities' (List<String>).
  Future<Map<String, dynamic>> getGlassesCapabilities() async {
    if (!Platform.isAndroid) {
      return {'visualUi': false, 'capabilities': <String>[]};
    }

    try {
      final result = await _channel
          .invokeMethod<Map<dynamic, dynamic>>('getGlassesCapabilities');
      if (result != null) {
        return {
          'visualUi': result['visualUi'] as bool? ?? false,
          'capabilities': (result['capabilities'] as List<dynamic>?)
                  ?.cast<String>() ??
              <String>[],
        };
      }
    } catch (e) {
      _logger.e('Failed to get glasses capabilities', error: e);
    }
    return {'visualUi': false, 'capabilities': <String>[]};
  }

  /// Launch the native GlassesActivity with Jetpack XR projected context.
  /// Returns true if launch succeeded.
  Future<bool> launchGlassesUI() async {
    if (!Platform.isAndroid) return false;

    try {
      final result =
          await _channel.invokeMethod<bool>('launchGlassesActivity');
      _logger.d('Glasses activity launch: $result');
      return result ?? false;
    } catch (e) {
      _logger.e('Failed to launch glasses activity', error: e);
      return false;
    }
  }

  /// Forward a caption to the glasses display via CaptionBridge.
  Future<void> sendCaption(String text) async {
    if (!Platform.isAndroid || !_isConnected) return;

    try {
      await _channel.invokeMethod<bool>('sendCaption', {'text': text});
    } catch (e) {
      _logger.e('Failed to send caption to glasses', error: e);
    }
  }

  /// Check if the GlassesActivity is currently running.
  Future<bool> isGlassesActivityActive() async {
    if (!Platform.isAndroid) return false;

    try {
      final result =
          await _channel.invokeMethod<bool>('isGlassesActivityActive');
      return result ?? false;
    } catch (e) {
      _logger.e('Failed to check glasses activity status', error: e);
      return false;
    }
  }

  /// Stop the running GlassesActivity.
  Future<bool> stopGlassesActivity() async {
    if (!Platform.isAndroid) return false;

    try {
      final result =
          await _channel.invokeMethod<bool>('stopGlassesActivity');
      return result ?? false;
    } catch (e) {
      _logger.e('Failed to stop glasses activity', error: e);
      return false;
    }
  }
}
