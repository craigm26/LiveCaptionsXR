import 'package:flutter/foundation.dart';
import 'dart:async';

/// Utility class to handle web-specific interactions and prevent UI freezing
class InteractionHandler {
  static Timer? _debounceTimer;

  /// Debounced function execution to prevent rapid-fire calls that can freeze the UI
  static void debounce({
    required Function() action,
    Duration delay = const Duration(milliseconds: 300),
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, action);
  }

  /// Safe async execution with timeout to prevent hanging
  static Future<T?> safeAsyncExecution<T>({
    required Future<T> Function() action,
    Duration timeout = const Duration(seconds: 5),
    T? defaultValue,
  }) async {
    try {
      return await action().timeout(timeout);
    } catch (e) {
      if (kDebugMode) {
        print('SafeAsyncExecution failed: $e');
      }
      return defaultValue;
    }
  }

  /// Prevents multiple rapid button presses
  static bool _isProcessing = false;

  static Future<void> safeButtonPress(Future<void> Function() action) async {
    if (_isProcessing) return;

    _isProcessing = true;
    try {
      await action();
    } finally {
      _isProcessing = false;
    }
  }

  /// Cleanup function to cancel any pending operations
  static void cleanup() {
    _debounceTimer?.cancel();
    _isProcessing = false;
  }
}
