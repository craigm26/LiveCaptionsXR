import 'package:flutter/services.dart';
import 'debug_capturing_logger.dart';

/// Service for localizing and tracking sound sources in 3D space.
///
/// This service acts as a Dart wrapper for the native HybridLocalizationEngine,
/// facilitating communication between the Flutter app and the Swift/Kotlin
/// localization logic.
class LocalizationService {
  static final DebugCapturingLogger _logger = DebugCapturingLogger();
  static const MethodChannel _channel =
      MethodChannel('live_captions_xr/hybrid_localization_methods');

  bool _isInitialized = false;

  /// Initialize the localization service.
  Future<void> initialize() async {
    _logger.i('🏗️ Initializing LocalizationService...');
    // Initialization logic can be added here if needed, e.g., telling
    // the native side to prepare.
    _isInitialized = true;
    _logger.i('✅ LocalizationService initialized successfully');
  }

  /// Updates the localization engine with an audio measurement.
  Future<void> updateWithAudioMeasurement({
    required double angle,
    required double confidence,
    required List<double> deviceTransform,
  }) async {
    if (!_isInitialized) return;
    try {
      await _channel.invokeMethod('updateWithAudioMeasurement', {
        'angle': angle,
        'confidence': confidence,
        'deviceTransform': deviceTransform,
      });
    } on PlatformException catch (e) {
      _logger.e('Failed to update with audio measurement: ${e.message}');
    }
  }

  /// Updates the localization engine with a visual measurement.
  Future<void> updateWithVisualMeasurement({
    required List<double> transform,
    required double confidence,
  }) async {
    if (!_isInitialized) return;
    try {
      await _channel.invokeMethod('updateWithVisualMeasurement', {
        'transform': transform,
        'confidence': confidence,
      });
    } on PlatformException catch (e) {
      _logger.e('Failed to update with visual measurement: ${e.message}');
    }
  }

  /// Retrieves the fused transform from the native localization engine.
  Future<List<double>?> getFusedTransform() async {
    if (!_isInitialized) return null;
    try {
      final List<dynamic>? result = await _channel.invokeMethod('fusedTransform');
      return result?.cast<double>();
    } on PlatformException catch (e) {
      _logger.e('Failed to get fused transform: ${e.message}');
      return null;
    }
  }

  /// Dispose of localization resources.
  void dispose() {
    _logger.i('🧹 Disposing LocalizationService...');
    _isInitialized = false;
    _logger.i('✅ LocalizationService disposed successfully');
  }
} 