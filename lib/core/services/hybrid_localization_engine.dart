import 'package:flutter/services.dart';
import 'app_logger.dart';

/// Dart wrapper for the native HybridLocalizationEngine (iOS/Android).
/// Provides Kalman filter fusion of audio, vision, and IMU for AR anchor placement.
class HybridLocalizationEngine {
  static const MethodChannel _channel =
      MethodChannel('live_captions_xr/hybrid_localization_methods');

  static final AppLogger _logger = AppLogger.instance;

  /// Predict step (advances state based on elapsed time).
  Future<void> predict() async {
    try {
      _logger.d('🔮 Executing prediction step for hybrid localization...');
      await _channel.invokeMethod('predict');
      _logger.d('✅ Prediction step completed successfully');
    } on PlatformException catch (e, stackTrace) {
      _logger.e('❌ Platform error during prediction step',
          error: e, stackTrace: stackTrace);
      rethrow;
    } catch (e, stackTrace) {
      _logger.e('❌ Unexpected error during prediction step',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Update with audio measurement (angle in radians, confidence 0-1, deviceTransform as 16 doubles, row-major).
  Future<void> updateWithAudioMeasurement({
    required double angle,
    required double confidence,
    required List<double> deviceTransform,
  }) async {
    try {
      _logger.d(
          '🎙️ Updating with audio measurement - angle: ${angle.toStringAsFixed(3)} rad, confidence: ${confidence.toStringAsFixed(3)}');
      await _channel.invokeMethod('updateWithAudioMeasurement', {
        'angle': angle,
        'confidence': confidence,
        'deviceTransform': deviceTransform,
      });
      _logger.d('✅ Audio measurement update completed successfully');
    } on PlatformException catch (e, stackTrace) {
      _logger.e('❌ Platform error updating audio measurement',
          error: e, stackTrace: stackTrace);
      rethrow;
    } catch (e, stackTrace) {
      _logger.e('❌ Unexpected error updating audio measurement',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Update with visual measurement (transform as 16 doubles, row-major, confidence 0-1).
  Future<void> updateWithVisualMeasurement({
    required List<double> transform,
    required double confidence,
  }) async {
    try {
      _logger.d(
          '👁️ Updating with visual measurement - confidence: ${confidence.toStringAsFixed(3)}, transform length: ${transform.length}');
      await _channel.invokeMethod('updateWithVisualMeasurement', {
        'transform': transform,
        'confidence': confidence,
      });
      _logger.d('✅ Visual measurement update completed successfully');
    } on PlatformException catch (e, stackTrace) {
      _logger.e('❌ Platform error updating visual measurement',
          error: e, stackTrace: stackTrace);
      rethrow;
    } catch (e, stackTrace) {
      _logger.e('❌ Unexpected error updating visual measurement',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get the fused world transform (returns 16 doubles, row-major 4x4 matrix).
  Future<List<double>> getFusedTransform() async {
    try {
      final result =
          await _channel.invokeMethod<List<dynamic>>('getFusedTransform');
      if (result == null) {
        _logger.e('❌ No fused transform returned from native side', category: LogCategory.ar);
        // Return default transform: identity matrix with 2m forward offset
        _logger.w('⚠️ Using default transform (2m in front of camera)', category: LogCategory.ar);
        final defaultTransform = List<double>.generate(16, (i) => (i % 5 == 0) ? 1.0 : 0.0);
        defaultTransform[14] = -0.5; // 0.5 meters in front (closer for better visibility)
        return defaultTransform;
      }
      final fusedTransform = result.cast<double>();
      return fusedTransform;
    } on PlatformException catch (e, stackTrace) {
      _logger.e('❌ Platform error getting fused transform: ${e.code} - ${e.message}',
          category: LogCategory.ar, error: e, stackTrace: stackTrace);
      // Return default transform on error
      _logger.w('⚠️ Using default transform due to error (2m in front of camera)', category: LogCategory.ar);
      final defaultTransform = List<double>.generate(16, (i) => (i % 5 == 0) ? 1.0 : 0.0);
      defaultTransform[14] = -2.0; // 2 meters in front
      return defaultTransform;
    } catch (e, stackTrace) {
      _logger.e('❌ Unexpected error getting fused transform',
          category: LogCategory.ar, error: e, stackTrace: stackTrace);
      // Return default transform on error
      _logger.w('⚠️ Using default transform due to error (2m in front of camera)', category: LogCategory.ar);
      final defaultTransform = List<double>.generate(16, (i) => (i % 5 == 0) ? 1.0 : 0.0);
      defaultTransform[14] = -2.0; // 2 meters in front
      return defaultTransform;
    }
  }

  /// Place a real-time caption at the current fused transform in AR.
  Future<void> placeRealtimeCaption(String text) async {
    try {
      _logger.i('🎯 [CAPTION PLACEMENT] Starting to place real-time caption in AR: "$text"', category: LogCategory.captions);
      
      // For debugging, use the SAME position as the red sphere
      // final transform = await getFusedTransform();
      final transform = [
        1.0, 0.0, 0.0, 0.0,  // Column 1 
        0.0, 1.0, 0.0, 0.0,  // Column 2
        0.0, 0.0, 1.0, 0.0,  // Column 3
        0.0, 0.3, -1.0, 1.0  // Column 4 (same as sphere but 0.3m above)
      ];
      _logger.i('🧮 [CAPTION PLACEMENT] Using fixed transform for testing: ${transform.take(4).join(", ")}...', category: LogCategory.captions);
      
      _logger.i('📞 [CAPTION PLACEMENT] About to call native method channel...', category: LogCategory.captions);
      _logger.i('📞 [CAPTION PLACEMENT] Channel: live_captions_xr/caption_methods, Method: placeCaption', category: LogCategory.captions);
      _logger.i('📞 [CAPTION PLACEMENT] Arguments: transform length=${transform.length}, text="$text"', category: LogCategory.captions);
      
      final result = await const MethodChannel('live_captions_xr/caption_methods')
          .invokeMethod('placeCaption', {
        'transform': transform,
        'text': text,
        'isSummary': false,
      });
      
      _logger.i('📱 [CAPTION PLACEMENT] Native method returned: $result', category: LogCategory.captions);
      _logger.i('✅ [CAPTION PLACEMENT] Real-time caption placed successfully in AR view', category: LogCategory.captions);
    } on PlatformException catch (e) {
      _logger.e('❌ [CAPTION PLACEMENT] Platform error placing real-time caption: ${e.message}', category: LogCategory.captions);
      _logger.e('❌ [CAPTION PLACEMENT] Error code: ${e.code}, details: ${e.details}', category: LogCategory.captions);
      throw Exception('Failed to place real-time caption: ${e.message}');
    } catch (e, stackTrace) {
      _logger.e('❌ [CAPTION PLACEMENT] Unexpected error placing caption', category: LogCategory.captions, error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Place a contextual summary at a stable, centered position.
  Future<void> placeContextualSummary(String text) async {
    try {
      _logger.i('✨ Placing contextual summary in AR: "$text"');
      
      // For summaries, we might use a default, stable transform 
      // (e.g., 2 meters in front of the user) instead of the dynamic fused transform.
      final stableTransform = List.generate(16, (i) => (i % 5 == 0) ? 1.0 : 0.0);
      stableTransform[14] = -2.0; // 2 meters in front

      await const MethodChannel('live_captions_xr/caption_methods')
          .invokeMethod('placeCaption', {
        'transform': stableTransform,
        'text': text,
        'isSummary': true,
      });
      
      _logger.i('✅ Contextual summary placed successfully.');
    } on PlatformException catch (e) {
      _logger.e('❌ Platform error placing contextual summary: ${e.message}');
      throw Exception('Failed to place contextual summary: ${e.message}');
    }
  }
}
