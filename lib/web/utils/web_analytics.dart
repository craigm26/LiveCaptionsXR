import 'package:flutter/foundation.dart';

/// Web analytics utility for tracking user interactions and performance metrics
class WebAnalytics {
  static final WebAnalytics _instance = WebAnalytics._internal();
  factory WebAnalytics() => _instance;
  WebAnalytics._internal();

  /// Track page view
  static void trackPageView(String pageName) {
    if (kIsWeb) {
      // In a real implementation, this would send data to Google Analytics, Mixpanel, etc.
      debugPrint('📊 Page View: $pageName');
    }
  }

  /// Track user interaction
  static void trackEvent(String eventName, {Map<String, dynamic>? parameters}) {
    if (kIsWeb) {
      debugPrint('📊 Event: $eventName ${parameters ?? {}}');
    }
  }

  /// Track technology demo interaction
  static void trackTechnologyDemo(String technologyName) {
    trackEvent('technology_demo_viewed', parameters: {
      'technology': technologyName,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track feature exploration
  static void trackFeatureExploration(String featureName) {
    trackEvent('feature_explored', parameters: {
      'feature': featureName,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track TestFlight download attempt
  static void trackTestFlightDownload() {
    trackEvent('testflight_download_attempted', parameters: {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track navigation
  static void trackNavigation(String fromPage, String toPage) {
    trackEvent('navigation', parameters: {
      'from': fromPage,
      'to': toPage,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track performance metrics
  static void trackPerformance(String metricName, double value) {
    trackEvent('performance_metric', parameters: {
      'metric': metricName,
      'value': value,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track user engagement
  static void trackEngagement(String engagementType, {int? duration}) {
    trackEvent('user_engagement', parameters: {
      'type': engagementType,
      'duration': duration,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}

/// Mixin for adding analytics to widgets
mixin AnalyticsMixin {
  void trackPageView(String pageName) {
    WebAnalytics.trackPageView(pageName);
  }

  void trackEvent(String eventName, {Map<String, dynamic>? parameters}) {
    WebAnalytics.trackEvent(eventName, parameters: parameters);
  }

  void trackTechnologyDemo(String technologyName) {
    WebAnalytics.trackTechnologyDemo(technologyName);
  }

  void trackFeatureExploration(String featureName) {
    WebAnalytics.trackFeatureExploration(featureName);
  }
} 