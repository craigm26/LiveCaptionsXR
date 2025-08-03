import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:live_captions_xr/web/app/app_web.dart';
import 'app.dart';
import 'core/services/app_logger.dart';
import 'core/services/debug_logger_service.dart';
import 'core/di/service_locator.dart';

final getIt = GetIt.instance;

// Configure logger for main app initialization
final AppLogger _logger = AppLogger.instance;

void main() async {
  // Configure logging - enable Gemma, AR and frame capture debugging
  AppLogger.instance.configure(const LogConfig(
    globalLevel: LogLevel.info,
    categoryLevels: {
      LogCategory.gemma: LogLevel.debug,      // Enable detailed Gemma logs
      LogCategory.ar: LogLevel.debug,         // Enable detailed AR logs
      LogCategory.audio: LogLevel.warning,    // Reduce audio noise (keep warning+ only)
      LogCategory.captions: LogLevel.debug,   // Enable caption logs
      LogCategory.camera: LogLevel.debug,     // Enable camera/frame capture logs
      LogCategory.speech: LogLevel.debug,     // Enable speech processing logs
      LogCategory.ui: LogLevel.info,          // Keep UI logs at info level
      LogCategory.system: LogLevel.info,      // Keep system logs at info level
    },
    enableConsoleOutput: true,
  ));
  
  _logger.i('🚀 Starting Live Captions XR application...', category: LogCategory.system);

  try {
    WidgetsFlutterBinding.ensureInitialized();
    _logger.d('✅ Flutter widgets binding initialized', category: LogCategory.system);

    // Load environment variables (optional, skip if file not found)
    try {
      await dotenv.load(fileName: ".env");
      _logger.d('🔑 Environment variables loaded', category: LogCategory.system);
    } catch (e) {
      _logger.w('⚠️ .env file not found, skipping dotenv load', category: LogCategory.system);
    }

    // Initialize debug logger service
    DebugLoggerService().initialize();
    _logger.d('🐛 Debug logger service initialized', category: LogCategory.system);

    // Register all services only once here!
    setupServiceLocator();

    if (kIsWeb) {
      _logger.i('🌐 Running web version of Live Captions XR', category: LogCategory.system);
      runApp(const LiveCaptionsXRWebApp());
    } else {
      _logger.i('📱 Running native version of Live Captions XR', category: LogCategory.system);
      runApp(const LiveCaptionsXrApp());
    }

    _logger.i('✅ Live Captions XR application launched successfully', category: LogCategory.system);
  } catch (e, stackTrace) {
    _logger.e('❌ Failed to start LiveCaptionsXR application',
        category: LogCategory.system, error: e, stackTrace: stackTrace);
    rethrow;
  }
}
