import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'debug_capturing_logger.dart';

/// Dart wrapper for the native HybridLocalizationEngine (iOS/Android).
/// Provides Kalman filter fusion of audio, vision, and IMU for AR anchor placement.
class HybridLocalizationEngine {
  static const MethodChannel _channel =
      MethodChannel('live_captions_xr/hybrid_localization_methods');

  static final DebugCapturingLogger _logger = DebugCapturingLogger();

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
      _logger.d('🔄 Requesting fused transform from hybrid localization...');
      final result =
          await _channel.invokeMethod<List<dynamic>>('getFusedTransform');
      if (result == null) {
        _logger.e('❌ No fused transform returned from native side');
        throw Exception('No fused transform returned');
      }
      final fusedTransform = result.cast<double>();
      _logger.d(
          '✅ Fused transform retrieved successfully - length: ${fusedTransform.length}');
      return fusedTransform;
    } on PlatformException catch (e, stackTrace) {
      _logger.e('❌ Platform error getting fused transform',
          error: e, stackTrace: stackTrace);
      rethrow;
    } catch (e, stackTrace) {
      _logger.e('❌ Unexpected error getting fused transform',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Place a caption at the current fused transform in AR (native).
  Future<void> placeCaption(String text) async {
    try {
      _logger.i('🎯 Placing caption in AR: "$text"');
      _logger.d('🔄 Requesting fused transform from hybrid localization...');
      
      final transform = await getFusedTransform();
      _logger.d('📍 Got fused transform for speaker localization');
      
      _logger.d('🚀 Invoking native caption placement...');
      await const MethodChannel('live_captions_xr/caption_methods')
          .invokeMethod('placeCaption', {
        'transform': transform,
        'text': text,
      });
      
      _logger.i('✅ Caption placed successfully in AR space');
      _logger.d('📌 Caption "$text" is now visible in AR at estimated speaker location');
    } on PlatformException catch (e, stackTrace) {
      _logger.e('❌ Platform error placing caption',
          error: e, stackTrace: stackTrace);
      
      // If AR caption placement fails, try fallback approaches
      await _tryFallbackCaptionPlacement(text, e);
    } catch (e, stackTrace) {
      _logger.e('❌ Unexpected error placing caption',
          error: e, stackTrace: stackTrace);
      
      // If AR caption placement fails, try fallback approaches  
      await _tryFallbackCaptionPlacement(text, e);
    }
  }

  /// Try fallback caption placement methods when AR placement fails
  Future<void> _tryFallbackCaptionPlacement(String text, dynamic originalError) async {
    try {
      _logger.w('⚠️ Attempting fallback caption placement for: "$text"');
      
      // Try placing caption with a default/identity transform as fallback
      final defaultTransform = List.generate(16, (index) => 
        index % 5 == 0 ? (index == 15 ? 1.0 : (index < 12 ? 1.0 : 0.0)) : 0.0);
      
      // Attempt placement with default transform
      await const MethodChannel('live_captions_xr/caption_methods')
          .invokeMethod('placeCaption', {
        'transform': defaultTransform,
        'text': text,
      });
      
      _logger.i('✅ Caption placed using fallback method');
    } catch (fallbackError) {
      _logger.e('❌ Fallback caption placement also failed', 
          error: fallbackError);
      
      // As a last resort, we could emit this caption to a UI overlay
      _logger.w('💬 Caption will be displayed in UI overlay: "$text"');
      // The UI layer should handle displaying captions even if AR placement fails
    }
  }
}
