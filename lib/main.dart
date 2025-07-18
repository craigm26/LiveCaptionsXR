import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:live_captions_xr/web/app/app_web.dart';
import 'app.dart';
import 'core/services/debug_capturing_logger.dart';
import 'core/services/debug_logger_service.dart';
import 'core/di/service_locator.dart';

// Configure logger for main app initialization
final DebugCapturingLogger _logger = DebugCapturingLogger();

void main() async {
  _logger.i('🚀 Starting Live Captions XR application...');

  try {
    WidgetsFlutterBinding.ensureInitialized();
    _logger.d('✅ Flutter widgets binding initialized');

    // Load environment variables (optional, skip if file not found)
    try {
      await dotenv.load(fileName: ".env");
      _logger.d('🔑 Environment variables loaded');
    } catch (e) {
      _logger.w('⚠️ .env file not found, skipping dotenv load');
    }

    // Initialize debug logger service
    DebugLoggerService().initialize();
    _logger.d('🐛 Debug logger service initialized');

    // Register all services only once here!
    setupServiceLocator();

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
