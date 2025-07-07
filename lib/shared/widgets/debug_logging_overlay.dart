import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import '../../core/services/debug_logger_service.dart';

/// An overlay widget that displays debug logs over the app content
class DebugLoggingOverlay extends StatefulWidget {
  final Widget child;
  final bool isEnabled;

  const DebugLoggingOverlay({
    super.key,
    required this.child,
    required this.isEnabled,
  });

  @override
  State<DebugLoggingOverlay> createState() => _DebugLoggingOverlayState();
}

class _DebugLoggingOverlayState extends State<DebugLoggingOverlay> {
  final DebugLoggerService _debugLogger = DebugLoggerService();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<LogEntry>? _logSubscription;
  bool _isExpanded = false;
  bool _autoScroll = true;

  // Regular expression to match ANSI escape sequences
  static final RegExp _ansiRegex =
      RegExp(r'\x1B\[[0-9;]*[A-Za-z]|\^?\[\[?[0-9;]*[A-Za-z]');

  /// Strips ANSI escape sequences from text to clean up log display
  String _stripAnsiCodes(String text) {
    return text.replaceAll(_ansiRegex, '');
  }

  @override
  void initState() {
    super.initState();
    _setupLogStream();
  }

  @override
  void didUpdateWidget(DebugLoggingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEnabled != oldWidget.isEnabled) {
      if (widget.isEnabled) {
        _setupLogStream();
      } else {
        _logSubscription?.cancel();
      }
    }
  }

  void _setupLogStream() {
    if (!widget.isEnabled) return;

    _logSubscription?.cancel();
    _logSubscription = _debugLogger.logStream.listen((_) {
      if (_autoScroll && _scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _logSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main app content
        widget.child,

        // Debug overlay
        if (widget.isEnabled && _debugLogger.isEnabled)
          _buildDebugOverlay(context),
      ],
    );
  }

  Widget _buildDebugOverlay(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 2,
      left: 10,
      right: 10,
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: _isExpanded ? 700 : 50,
          decoration: BoxDecoration(
            color: Colors.black.withAlpha((255 * 0.85).round()),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue.withAlpha((255 * 0.3).round()),
              width: 1,
            ),
          ),
          child: _isExpanded
              ? Column(
                  children: [
                    _buildHeader(context),
                    const Divider(
                      height: 1,
                      color: Colors.white24,
                    ),
                    Expanded(child: _buildLogsList()),
                    _buildFooter(context),
                  ],
                )
              : _buildHeader(context),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final logCount = _debugLogger.logHistory.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(
            Icons.bug_report,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isExpanded ? 'Debug Logs ($logCount)' : 'Debug: $logCount logs',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_isExpanded) ...[
            // Auto-scroll toggle
            InkWell(
              onTap: () => setState(() => _autoScroll = !_autoScroll),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _autoScroll
                      ? Colors.blue.withAlpha((255 * 0.3).round())
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.arrow_downward,
                  color: _autoScroll ? Colors.blue[300] : Colors.white60,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Copy logs button
            InkWell(
              onTap: _copyLogs,
              child: Container(
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.copy,
                  color: Colors.white60,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Clear logs button
            InkWell(
              onTap: _clearLogs,
              child: Container(
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.clear_all,
                  color: Colors.white60,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Expand/collapse button
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.white60,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList() {
    final logs = _debugLogger.logHistory;

    if (logs.isEmpty) {
      return const Center(
        child: Text(
          'No logs captured yet',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return _buildLogItem(log);
      },
    );
  }

  Widget _buildLogItem(LogEntry log) {
    // Clean the log message by stripping ANSI escape sequences
    final cleanMessage = _stripAnsiCodes(log.formatForDisplay());

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: _getLogBackgroundColor(log.level),
        borderRadius: BorderRadius.circular(4),
        border: log.level == Level.error || log.level == Level.fatal
            ? Border.all(color: Colors.red.withAlpha((255 * 0.3).round()), width: 1)
            : null,
      ),
      child: SelectableText(
        cleanMessage,
        style: TextStyle(
          color: _getLogTextColor(log.level),
          fontSize: 11,
          fontFamily: 'monospace',
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_debugLogger.logHistory.length}/${DebugLoggerService.maxLogEntries} logs',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Color _getLogBackgroundColor(Level level) {
    switch (level) {
      case Level.error:
      case Level.fatal:
        return Colors.red.withAlpha((255 * 0.2).round());
      case Level.warning:
        return Colors.orange.withAlpha((255 * 0.2).round());
      case Level.info:
        return Colors.blue.withAlpha((255 * 0.1).round());
      default:
        return Colors.transparent;
    }
  }

  Color _getLogTextColor(Level level) {
    switch (level) {
      case Level.error:
      case Level.fatal:
        return Colors.red[300]!;
      case Level.warning:
        return Colors.orange[300]!;
      case Level.info:
        return Colors.blue[300]!;
      case Level.debug:
        return Colors.green[300]!;
      default:
        return Colors.white70;
    }
  }

  Future<void> _copyLogs() async {
    try {
      // Get formatted logs and strip ANSI codes
      final formattedLogs = _getFormattedLogsWithoutAnsi();
      await Clipboard.setData(ClipboardData(text: formattedLogs));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Debug logs copied to clipboard (ANSI codes stripped)'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy logs: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Get formatted logs with ANSI escape sequences stripped
  String _getFormattedLogsWithoutAnsi() {
    final buffer = StringBuffer();
    buffer.writeln('=== LiveCaptionsXR Debug Logs (Clean) ===');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total entries: ${_debugLogger.logHistory.length}');
    buffer.writeln('==========================================\n');

    for (final entry in _debugLogger.logHistory) {
      // Format each log entry and strip ANSI codes
      final cleanEntry = _formatLogEntryForCopy(entry);
      buffer.writeln(cleanEntry);
      buffer.writeln('---');
    }

    return buffer.toString();
  }

  /// Format a single log entry for copying with ANSI codes stripped
  String _formatLogEntryForCopy(LogEntry entry) {
    final buffer = StringBuffer();

    // Strip ANSI codes from message
    final cleanMessage = _stripAnsiCodes(entry.message);

    buffer.writeln(
        '[${entry.timestamp.toIso8601String()}] ${entry.level.name.toUpperCase()}: $cleanMessage');

    if (entry.error != null) {
      final cleanError = _stripAnsiCodes(entry.error!);
      buffer.writeln('Error: $cleanError');
    }

    if (entry.stackTrace != null) {
      final cleanStackTrace = _stripAnsiCodes(entry.stackTrace!);
      buffer.writeln('Stack Trace:');
      buffer.writeln(cleanStackTrace);
    }

    return buffer.toString().trim();
  }

  void _clearLogs() {
    _debugLogger.clearLogs();
    setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debug logs cleared'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
}
