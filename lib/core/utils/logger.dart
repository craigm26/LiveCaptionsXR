import 'package:logger/logger.dart';
import '../services/debug_capturing_logger.dart';

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
final DebugCapturingLogger debugLogger = DebugCapturingLogger();

/// Legacy log function for backward compatibility
/// Now uses DebugCapturingLogger for unified debug overlay
void log(String message) {
  appLogger.i(message);
  debugLogger.i(message);
}
