import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart' as logger_lib;
import 'debug_logger_service.dart';

/// Logging categories for the LiveCaptionsXR app
enum LogCategory {
  audio('🎵 AUDIO'),
  gemma('🤖 GEMMA'),
  ar('📱 AR'),
  captions('📋 CAPTIONS'),
  camera('📷 CAMERA'),
  speech('🎤 SPEECH'),
  ui('🖥️ UI'),
  system('⚙️ SYSTEM');

  const LogCategory(this.prefix);
  final String prefix;
}

/// Log levels
enum LogLevel {
  trace,
  debug,
  info,
  warning,
  error,
  fatal;

  bool operator >=(LogLevel other) => index >= other.index;
  
  /// Convert to logger_lib.Level for DebugLoggerService
  logger_lib.Level get toLoggerLevel {
    switch (this) {
      case LogLevel.trace:
        return logger_lib.Level.trace;
      case LogLevel.debug:
        return logger_lib.Level.debug;
      case LogLevel.info:
        return logger_lib.Level.info;
      case LogLevel.warning:
        return logger_lib.Level.warning;
      case LogLevel.error:
        return logger_lib.Level.error;
      case LogLevel.fatal:
        return logger_lib.Level.fatal;
    }
  }
}

/// Configuration for app logging
class LogConfig {
  final Map<LogCategory, LogLevel> categoryLevels;
  final LogLevel globalLevel;
  final bool enableConsoleOutput;
  final bool enableFileOutput;

  const LogConfig({
    this.categoryLevels = const {},
    this.globalLevel = LogLevel.info,
    this.enableConsoleOutput = true,
    this.enableFileOutput = false,
  });

  LogConfig copyWith({
    Map<LogCategory, LogLevel>? categoryLevels,
    LogLevel? globalLevel,
    bool? enableConsoleOutput,
    bool? enableFileOutput,
  }) {
    return LogConfig(
      categoryLevels: categoryLevels ?? this.categoryLevels,
      globalLevel: globalLevel ?? this.globalLevel,
      enableConsoleOutput: enableConsoleOutput ?? this.enableConsoleOutput,
      enableFileOutput: enableFileOutput ?? this.enableFileOutput,
    );
  }

  /// Get effective log level for a category
  LogLevel getLevelFor(LogCategory category) {
    return categoryLevels[category] ?? globalLevel;
  }

  /// Check if logging is enabled for category and level
  bool isEnabled(LogCategory category, LogLevel level) {
    return level >= getLevelFor(category);
  }
}

/// Centralized logging service for LiveCaptionsXR
class AppLogger {
  static AppLogger? _instance;
  static AppLogger get instance => _instance ??= AppLogger._();
  
  AppLogger._();

  LogConfig _config = const LogConfig();
  final DebugLoggerService _debugService = DebugLoggerService();

  /// Update logging configuration
  void configure(LogConfig config) {
    _config = config;
  }

  /// Set log level for specific category
  void setCategoryLevel(LogCategory category, LogLevel level) {
    final newCategoryLevels = Map<LogCategory, LogLevel>.from(_config.categoryLevels);
    newCategoryLevels[category] = level;
    _config = _config.copyWith(categoryLevels: newCategoryLevels);
  }

  /// Set global log level
  void setGlobalLevel(LogLevel level) {
    _config = _config.copyWith(globalLevel: level);
  }

  /// Trace log
  void t(String message, {LogCategory category = LogCategory.system, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.trace, category, message, error: error, stackTrace: stackTrace);
  }

  /// Debug log
  void d(String message, {LogCategory category = LogCategory.system, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, category, message, error: error, stackTrace: stackTrace);
  }

  /// Info log
  void i(String message, {LogCategory category = LogCategory.system, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, category, message, error: error, stackTrace: stackTrace);
  }

  /// Warning log
  void w(String message, {LogCategory category = LogCategory.system, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, category, message, error: error, stackTrace: stackTrace);
  }

  /// Error log
  void e(String message, {LogCategory category = LogCategory.system, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, category, message, error: error, stackTrace: stackTrace);
  }

  /// Fatal log
  void f(String message, {LogCategory category = LogCategory.system, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.fatal, category, message, error: error, stackTrace: stackTrace);
  }

  void _log(LogLevel level, LogCategory category, String message, {Object? error, StackTrace? stackTrace}) {
    if (!_config.isEnabled(category, level)) return;

    final prefix = category.prefix;
    final levelStr = level.name.toUpperCase();
    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    
    String logMessage = '[$timestamp] $prefix [$levelStr] $message';
    
    if (error != null) {
      logMessage += '\nError: $error';
    }
    
    if (stackTrace != null) {
      logMessage += '\nStack trace:\n$stackTrace';
    }

    // Send to DebugLoggerService for capture
    _debugService.captureLog(
      level.toLoggerLevel,
      logMessage,
      error: error?.toString(),
      stackTrace: stackTrace?.toString(),
    );

    if (_config.enableConsoleOutput) {
      if (kDebugMode) {
        switch (level) {
          case LogLevel.trace:
            developer.log(logMessage, name: category.name);
            break;
          case LogLevel.debug:
            developer.log(logMessage, name: category.name);
            break;
          case LogLevel.info:
            developer.log(logMessage, name: category.name);
            break;
          case LogLevel.warning:
            developer.log(logMessage, name: category.name, level: 900);
            break;
          case LogLevel.error:
            developer.log(logMessage, name: category.name, level: 1000, error: error, stackTrace: stackTrace);
            break;
          case LogLevel.fatal:
            developer.log(logMessage, name: category.name, level: 1200, error: error, stackTrace: stackTrace);
            break;
        }
      }
    }

    // TODO: Implement file output if needed
    if (_config.enableFileOutput) {
      // File logging implementation
    }
  }

  /// Get current configuration
  LogConfig get config => _config;
}

/// Extension for easy access to logger
extension LoggerExt on Object {
  AppLogger get logger => AppLogger.instance;
}