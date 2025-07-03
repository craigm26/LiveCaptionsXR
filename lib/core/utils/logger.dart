import 'package:logger/logger.dart';

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

/// Legacy log function for backward compatibility
void log(String message) {
  appLogger.i(message);
}
