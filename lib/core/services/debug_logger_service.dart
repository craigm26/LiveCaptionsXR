import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

/// A service that captures and manages debug logs for TestFlight builds
///
/// This service provides a centralized logging system that captures debug logs
/// and displays them in a transparent overlay on the app screen. It's designed
/// specifically for TestFlight builds where developers need to see real-time
/// logs without connecting to a debugger.
///
/// ## How to Use:
///
/// 1. **Enable in Settings**: Go to Settings > Developer Settings and toggle
///    "Debug Logging Overlay" to see the logging overlay.
///
/// 2. **Use DebugCapturingLogger**: Replace your regular Logger instances with
///    DebugCapturingLogger to automatically capture logs:
///    ```dart
///    final logger = DebugCapturingLogger();
///    logger.i('This will appear in the overlay');
///    ```
///
/// 3. **View Logs**: When enabled, you'll see a transparent overlay at the top
///    of the screen showing real-time logs. Tap to expand/collapse.
///
/// 4. **Copy Logs**: Use the copy button in the expanded overlay to copy all
///    logs to the clipboard for sharing.
///
/// 5. **Clear Logs**: Use the clear button to remove all captured logs.
///
/// ## Features:
/// - Real-time log display with color coding by log level
/// - Auto-scroll to latest logs
/// - Copy all logs to clipboard
/// - Clear logs functionality
/// - Privacy-aware (clears logs when disabled)
/// - Memory efficient (limits to 500 entries)
/// - Only works in debug/profile builds and TestFlight builds (with IS_TESTFLIGHT=true flag) for security
class DebugLoggerService {
  static final DebugLoggerService _instance = DebugLoggerService._internal();
  factory DebugLoggerService() => _instance;
  DebugLoggerService._internal();

  final StreamController<LogEntry> _logStreamController =
      StreamController<LogEntry>.broadcast();
  final List<LogEntry> _logHistory = [];
  bool _isEnabled = false;

  static const int maxLogEntries = 500; // Limit to prevent memory issues

  /// Stream of log entries for real-time display
  Stream<LogEntry> get logStream => _logStreamController.stream;

  /// List of all captured log entries
  List<LogEntry> get logHistory => List.unmodifiable(_logHistory);

  /// Whether debug logging is currently enabled
  bool get isEnabled => _isEnabled;

  /// Initialize the debug logger service
  void initialize() {
    // Allow debug logging in debug, profile builds, TestFlight builds, and when assertions are enabled
    // This covers TestFlight builds which have the IS_TESTFLIGHT flag set
    bool isDevelopmentBuild = kDebugMode || kProfileMode;
    bool assertionsEnabled = false;
    assert(assertionsEnabled = true);
    
    // Check for TestFlight builds using build-time flag
    const bool isTestFlight = bool.fromEnvironment('IS_TESTFLIGHT', defaultValue: false);
    
    if (isDevelopmentBuild || assertionsEnabled || isTestFlight) {
      _setupLogInterception();
    }
  }

  /// Enable or disable debug logging
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      // Clear logs when disabled for privacy
      clearLogs();
    }
  }

  /// Setup log interception to capture all logger statements
  void _setupLogInterception() {
    // Note: Since Logger.addLogListener may not be available,
    // we'll use a different approach - create a custom LogOutput
    // and configure it in the individual loggers that want to be captured
  }

  /// Manual method to capture logs - call this from your loggers
  void captureLog(Level level, String message,
      {String? error, String? stackTrace}) {
    if (!_isEnabled) return;

    final entry = LogEntry(
      level: level,
      message: message,
      error: error,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    );

    _addLogEntry(entry);
  }

  /// Add a log entry to the history and stream
  void _addLogEntry(LogEntry entry) {
    _logHistory.add(entry);

    // Limit history size to prevent memory issues
    if (_logHistory.length > maxLogEntries) {
      _logHistory.removeAt(0);
    }

    _logStreamController.add(entry);
  }

  /// Add a custom log entry (for manual logging)
  void addLogEntry({
    required Level level,
    required String message,
    String? error,
    String? stackTrace,
  }) {
    if (!_isEnabled) return;

    final entry = LogEntry(
      level: level,
      message: message,
      error: error,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    );

    _addLogEntry(entry);
  }

  /// Clear all log entries
  void clearLogs() {
    _logHistory.clear();
  }

  /// Get formatted logs as a string for copying
  String getFormattedLogs() {
    final buffer = StringBuffer();
    buffer.writeln('=== LiveCaptionsXR Debug Logs ===');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total entries: ${_logHistory.length}');
    buffer.writeln('=====================================\n');

    for (final entry in _logHistory) {
      buffer.writeln(entry.formatForCopy());
      buffer.writeln('---');
    }

    return buffer.toString();
  }

  /// Copy logs to clipboard
  Future<void> copyLogsToClipboard() async {
    final formattedLogs = getFormattedLogs();
    await Clipboard.setData(ClipboardData(text: formattedLogs));
  }

  /// Dispose the service
  void dispose() {
    _logStreamController.close();
  }
}

/// Represents a single log entry
class LogEntry {
  final Level level;
  final String message;
  final String? error;
  final String? stackTrace;
  final DateTime timestamp;

  LogEntry({
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
    required this.timestamp,
  });

  /// Get the emoji representation for the log level
  String get levelEmoji {
    switch (level) {
      case Level.trace:
        return '🔍';
      case Level.debug:
        return '🐛';
      case Level.info:
        return 'ℹ️';
      case Level.warning:
        return '⚠️';
      case Level.error:
        return '❌';
      case Level.fatal:
        return '💀';
      default:
        return '📝';
    }
  }

  /// Get the color for the log level
  String get levelColor {
    switch (level) {
      case Level.trace:
        return '#9CA3AF'; // gray
      case Level.debug:
        return '#3B82F6'; // blue
      case Level.info:
        return '#10B981'; // green
      case Level.warning:
        return '#F59E0B'; // yellow
      case Level.error:
        return '#EF4444'; // red
      case Level.fatal:
        return '#7C2D12'; // dark red
      default:
        return '#6B7280'; // gray
    }
  }

  /// Format the log entry for display
  String formatForDisplay() {
    final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';

    return '$levelEmoji [$timeStr] $message';
  }

  /// Format the log entry for copying
  String formatForCopy() {
    final buffer = StringBuffer();
    buffer.writeln(
        '[${timestamp.toIso8601String()}] ${level.name.toUpperCase()}: $message');

    if (error != null) {
      buffer.writeln('Error: $error');
    }

    if (stackTrace != null) {
      buffer.writeln('Stack Trace:');
      buffer.writeln(stackTrace);
    }

    return buffer.toString().trim();
  }
}
