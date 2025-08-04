import 'app_logger.dart';

/// A logger wrapper that captures debug information for development
class DebugCapturingLogger {
  final AppLogger _logger = AppLogger.instance;

  /// Debug log
  void d(String message) {
    _logger.d(message, category: LogCategory.system);
  }

  /// Info log
  void i(String message) {
    _logger.i(message, category: LogCategory.system);
  }

  /// Warning log
  void w(String message) {
    _logger.w(message, category: LogCategory.system);
  }

  /// Error log
  void e(String message) {
    _logger.e(message, category: LogCategory.system);
  }
} 