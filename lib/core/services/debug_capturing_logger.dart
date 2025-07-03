import 'package:logger/logger.dart';
import 'debug_logger_service.dart';

/// A custom logger that captures logs to the debug logger service for TestFlight builds
class DebugCapturingLogger {
  final Logger _logger;
  final DebugLoggerService _debugService = DebugLoggerService();

  DebugCapturingLogger({String? tag})
      : _logger = Logger(
          printer: PrettyPrinter(
            methodCount: 2,
            errorMethodCount: 8,
            lineLength: 120,
            colors: true,
            printEmojis: true,
            printTime: true,
          ),
        );

  /// Log a trace message
  void t(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.t(message, error: error, stackTrace: stackTrace);
    _debugService.captureLog(Level.trace, message,
        error: error?.toString(), stackTrace: stackTrace?.toString());
  }

  /// Log a debug message
  void d(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.d(message, error: error, stackTrace: stackTrace);
    _debugService.captureLog(Level.debug, message,
        error: error?.toString(), stackTrace: stackTrace?.toString());
  }

  /// Log an info message
  void i(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.i(message, error: error, stackTrace: stackTrace);
    _debugService.captureLog(Level.info, message,
        error: error?.toString(), stackTrace: stackTrace?.toString());
  }

  /// Log a warning message
  void w(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.w(message, error: error, stackTrace: stackTrace);
    _debugService.captureLog(Level.warning, message,
        error: error?.toString(), stackTrace: stackTrace?.toString());
  }

  /// Log an error message
  void e(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
    _debugService.captureLog(Level.error, message,
        error: error?.toString(), stackTrace: stackTrace?.toString());
  }

  /// Log a fatal message
  void f(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.f(message, error: error, stackTrace: stackTrace);
    _debugService.captureLog(Level.fatal, message,
        error: error?.toString(), stackTrace: stackTrace?.toString());
  }

  /// Log a custom level message
  void log(Level level, String message,
      {Object? error, StackTrace? stackTrace}) {
    _logger.log(level, message, error: error, stackTrace: stackTrace);
    _debugService.captureLog(level, message,
        error: error?.toString(), stackTrace: stackTrace?.toString());
  }
}
