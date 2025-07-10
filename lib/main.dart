import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:live_captions_xr/web/app/app_web.dart';
import 'app.dart';
import 'core/services/debug_capturing_logger.dart';
import 'core/services/debug_logger_service.dart';

// Configure logger for main app initialization
final DebugCapturingLogger _logger = DebugCapturingLogger();

void main() async {
  _logger.i('🚀 Starting Live Captions XR application...');

  try {
    WidgetsFlutterBinding.ensureInitialized();
    _logger.d('✅ Flutter widgets binding initialized');

    // Initialize debug logger service
    DebugLoggerService().initialize();
    _logger.d('🐛 Debug logger service initialized');

    if (kIsWeb) {
      _logger.i('🌐 Running web version of Live Captions XR');
      runApp(const LiveCaptionsXRWebApp());
    } else {
      _logger.i('📱 Running native version of Live Captions XR');
      runApp(const LiveCaptionsXrApp());
    }

    _logger.i('✅ Live Captions XR application launched successfully');
  } catch (e, stackTrace) {
    _logger.e('❌ Failed to start LiveCaptionsXR application',
        error: e, stackTrace: stackTrace);
    rethrow;
  }
}
