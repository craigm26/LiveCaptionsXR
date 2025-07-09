import 'package:flutter/foundation.dart';

/// Configuration class for web-specific performance optimizations
class WebPerformanceConfig {
  // Reduce logging verbosity on web to prevent console spam
  static bool get enableVerboseLogging => !kIsWeb;

  // Optimize animation durations for web
  static Duration get fastAnimationDuration => kIsWeb
      ? const Duration(milliseconds: 200)
      : const Duration(milliseconds: 400);

  static Duration get normalAnimationDuration => kIsWeb
      ? const Duration(milliseconds: 400)
      : const Duration(milliseconds: 800);

  static Duration get slowAnimationDuration => kIsWeb
      ? const Duration(milliseconds: 600)
      : const Duration(milliseconds: 1200);

  // Network timeout configurations
  static Duration get networkTimeout => const Duration(seconds: 5);

  // Reduce widget rebuild frequency on web
  static bool get enableHeavyAnimations => !kIsWeb;

  // Debounce delay for user interactions
  static Duration get interactionDebounceDelay => kIsWeb
      ? const Duration(milliseconds: 100)
      : const Duration(milliseconds: 50);
}
