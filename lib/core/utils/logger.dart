import 'package:logger/logger.dart';
import '../services/app_logger.dart';

/// Global logger instance configured for LiveCaptionsXR
final Logger appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    printTime: true,
  ),
);

/// Global debug capturing logger for unified logging
final AppLogger debugLogger = AppLogger.instance;

/// Legacy log function for backward compatibility
/// Now uses AppLogger for unified debug overlay
void log(String message) {
  appLogger.i(message);
  debugLogger.i(message, category: LogCategory.system);
}
