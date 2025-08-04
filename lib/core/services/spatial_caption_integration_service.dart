import 'dart:async';
import 'dart:math';
import 'package:vector_math/vector_math_64.dart';
import 'package:spatial_captions/spatial_captions.dart';
import 'package:spatial_captions/cubit/spatial_captions_cubit.dart';
import '../models/speech_result.dart';
import '../models/enhanced_caption.dart';
import 'speech_localizer.dart';
import 'stereo_audio_capture.dart';
import 'gemma_3n_service.dart';
import 'debug_capturing_logger.dart';
import 'hybrid_localization_engine.dart';

/// Service that integrates live captions with spatial positioning in AR
class SpatialCaptionIntegrationService {
  final SpatialCaptionsCubit _spatialCaptionsCubit;
  final SpeechLocalizer _speechLocalizer;
  final Gemma3nService _gemmaService;
  final HybridLocalizationEngine _hybridLocalizationEngine;
  final DebugCapturingLogger _logger = DebugCapturingLogger();

  // Configuration
  static const double defaultCaptionDistance = 2.0; // meters
  static const double captionHeight = 0.0; // eye level
  
  // Track ongoing enhancements
  final Map<String, Timer> _enhancementTimers = {};
  
  // Track last audio frame for direction estimation
  StereoAudioFrame? _lastAudioFrame;
  
  SpatialCaptionIntegrationService({
    required SpatialCaptionsCubit spatialCaptionsCubit,
    required SpeechLocalizer speechLocalizer,
    required Gemma3nService gemmaService,
    required HybridLocalizationEngine hybridLocalizationEngine,
  })  : _spatialCaptionsCubit = spatialCaptionsCubit,
        _speechLocalizer = speechLocalizer,
        _gemmaService = gemmaService,
        _hybridLocalizationEngine = hybridLocalizationEngine;

  /// Initialize the service and set landscape orientation
  Future<void> initialize() async {
    _logger.i('🚀 Initializing spatial caption integration service');
    
    // Lock to landscape mode as requested
    await _spatialCaptionsCubit.setOrientationLock(true);
    
    // Set default caption duration
    _spatialCaptionsCubit.setCaptionDuration(const Duration(seconds: 6));
    
    _logger.i('✅ Spatial caption integration initialized');
  }

  /// Update the last audio frame for direction estimation
  void updateAudioFrame(StereoAudioFrame frame) {
    _lastAudioFrame = frame;
  }

  /// Process a partial speech result
  Future<void> processPartialResult(SpeechResult result) async {
    _logger.d('🎤 Processing partial result: "${result.text}"');
    
    try {
      // Get position from audio direction
      final position = await _calculateCaptionPosition(result);
      
      // Use speaker direction as a simple speaker ID
      final speakerId = result.speakerDirection ?? 'default';
      
      // Add partial caption
      await _spatialCaptionsCubit.addPartialCaption(
        text: result.text,
        position: position,
        speakerId: speakerId,
        confidence: result.confidence,
      );
      
      _logger.d('✅ Partial caption added at position: $position');
    } catch (e) {
      _logger.e('❌ Error processing partial result: $e');
    }
  }

  /// Process a final speech result
  Future<void> processFinalResult(SpeechResult result) async {
    _logger.i('📝 Processing final result: "${result.text}"');
    
    try {
      // Get position from audio direction
      final position = await _calculateCaptionPosition(result);
      
      // Use speaker direction as a simple speaker ID
      final speakerId = result.speakerDirection ?? 'default';
      
      // Add final caption (will replace partial)
      await _spatialCaptionsCubit.finalizeCaption(
        text: result.text,
        position: position,
        speakerId: speakerId,
        confidence: result.confidence,
      );
      
      // Schedule enhancement with Gemma
      _scheduleEnhancement(result, speakerId);
      
      _logger.i('✅ Final caption added and enhancement scheduled');
    } catch (e) {
      _logger.e('❌ Error processing final result: $e');
    }
  }

  /// Calculate caption position based on audio direction and hybrid localization
  Future<Vector3> _calculateCaptionPosition(SpeechResult result) async {
    try {
      // First, try to get position from hybrid localization engine
      final fusedTransform = await _hybridLocalizationEngine.getFusedTransform();
      if (fusedTransform.length == 16) {
        // Extract position from 4x4 transform matrix (last column)
        final x = fusedTransform[12];
        final y = fusedTransform[13];
        final z = fusedTransform[14];
        
        _logger.d('🎯 Using hybrid localization position: ($x, $y, $z)');
        return Vector3(x, y, z);
      }
    } catch (e) {
      _logger.w('⚠️ Hybrid localization failed, falling back to audio-only: $e');
    }
    
    // Fallback: Check if we have speaker direction information
    if (result.speakerDirection != null) {
      _logger.d('📍 Using speaker direction: ${result.speakerDirection}');
      
      // Convert direction string to angle
      double angle = 0.0;
      switch (result.speakerDirection) {
        case 'left':
          angle = -pi / 4; // 45 degrees left
          break;
        case 'right':
          angle = pi / 4; // 45 degrees right
          break;
        case 'center':
        default:
          angle = 0.0;
      }
      
      return Vector3(
        defaultCaptionDistance * sin(angle),
        captionHeight,
        -defaultCaptionDistance * cos(angle),
      );
    }
    
    // Try to estimate from audio if we have a recent frame
    if (_lastAudioFrame != null) {
      try {
        final direction = _speechLocalizer.estimateDirectionAdvanced(_lastAudioFrame!);
        _logger.d('🔊 Advanced audio direction estimated: ${direction.toStringAsFixed(3)} radians');
        
        // Feed the audio direction to hybrid localization for future use
        await _hybridLocalizationEngine.feedAudioDirection(
          angle: direction,
          confidence: result.confidence,
        );
        
        return Vector3(
          defaultCaptionDistance * sin(direction),
          captionHeight,
          -defaultCaptionDistance * cos(direction),
        );
      } catch (e) {
        _logger.w('⚠️ Audio direction estimation failed: $e');
      }
    }
    
    // Default: place in front of user
    _logger.d('📍 Using default center position');
    return Vector3(0, captionHeight, -defaultCaptionDistance);
  }

  /// Schedule enhancement of a final caption
  void _scheduleEnhancement(SpeechResult result, String speakerId) {
    // Cancel any existing timer for this speaker
    _enhancementTimers[speakerId]?.cancel();
    
    // Wait a short time to batch multiple utterances
    _enhancementTimers[speakerId] = Timer(
      const Duration(milliseconds: 500),
      () => _enhanceCaption(result, speakerId),
    );
  }

  /// Enhance caption with Gemma
  Future<void> _enhanceCaption(SpeechResult result, String speakerId) async {
    try {
      _logger.i('🤖 Enhancing caption with Gemma: "${result.text}"');
      
      // Get the latest final caption for this speaker
      final latestCaptions = _spatialCaptionsCubit.state.latestCaptionBySpeaker;
      final captionToEnhance = latestCaptions[speakerId];
      
      if (captionToEnhance == null || !captionToEnhance.isFinal) {
        _logger.w('⚠️ No final caption found to enhance');
        return;
      }
      
      // Process with Gemma for enhancement
      final enhancedText = await _gemmaService.enhanceText(
        captionToEnhance.text,
      );
      
      if (enhancedText != null && enhancedText != captionToEnhance.text) {
        // Update with enhanced text
        await _spatialCaptionsCubit.enhanceCaption(
          captionId: captionToEnhance.id,
          enhancedText: enhancedText,
        );
        
        _logger.i('✅ Caption enhanced: "$enhancedText"');
      }
    } catch (e) {
      _logger.e('❌ Error enhancing caption: $e');
    }
  }

  /// Clear all captions
  Future<void> clearAllCaptions() async {
    _logger.i('🧹 Clearing all spatial captions');
    
    // Cancel all enhancement timers
    for (final timer in _enhancementTimers.values) {
      timer.cancel();
    }
    _enhancementTimers.clear();
    
    // Clear captions
    await _spatialCaptionsCubit.clearAll();
  }

  /// Update caption display duration
  void setCaptionDuration(Duration duration) {
    _logger.i('⏱️ Setting caption duration to: ${duration.inSeconds}s');
    _spatialCaptionsCubit.setCaptionDuration(duration);
  }

  /// Dispose of resources
  void dispose() {
    // Cancel all timers
    for (final timer in _enhancementTimers.values) {
      timer.cancel();
    }
    _enhancementTimers.clear();
  }
} 