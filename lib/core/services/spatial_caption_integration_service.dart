import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:spatial_captions/spatial_captions.dart';
import 'package:spatial_captions/cubit/spatial_captions_cubit.dart';
import 'package:get_it/get_it.dart';
import '../models/detected_speaker.dart';
import '../models/speech_result.dart';
import 'speech_localizer.dart';
import 'stereo_audio_capture.dart';
import 'gemma_3n_service.dart';
import 'app_logger.dart';
import 'hybrid_localization_engine.dart';
import 'package:live_captions_xr/spatial_intel/streams/predictive_stream_hub.dart';
import 'package:live_captions_xr/spatial_intel/streams/spatial_sensor_stream.dart';
import 'package:live_captions_xr/spatial_intel/placement/spatial_anchor_coordinator.dart';

/// Service that integrates live captions with spatial positioning in AR
class SpatialCaptionIntegrationService {
  final SpatialCaptionsCubit _spatialCaptionsCubit;
  final SpeechLocalizer _speechLocalizer;
  final Gemma3nService _gemmaService;
  final HybridLocalizationEngine _hybridLocalizationEngine;
  final AppLogger _logger = AppLogger.instance;

  bool _isSpatialCaptionsReady = false;

  // Removed: Method channel for AR session events (no longer needed)

  // Configuration
  static const double defaultCaptionDistance = 2.0; // meters
  static const double captionHeight = 0.0; // eye level

  // Track ongoing enhancements
  final Map<String, Timer> _enhancementTimers = {};

  // Track last audio frame for direction estimation
  StereoAudioFrame? _lastAudioFrame;
  DetectedSpeaker? _activeSpeaker;
  DateTime? _activeSpeakerUpdatedAt;
  static const Duration _activeSpeakerFreshFor = Duration(milliseconds: 750);

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
    _logger.i(
        '🚀 ============ SPATIAL CAPTION INTEGRATION SERVICE INIT ============',
        category: LogCategory.captions);
    _logger.i(
        '🚀 NEW APPROACH: Single initialization attempt (no retry mechanism)',
        category: LogCategory.captions);

    // Initialize plugin with AR scene view (iOS only) - single attempt since AR View should be ready
    try {
      _logger.i(
          '🎯 [SPATIAL INTEGRATION] About to call SpatialCaptions.initializeWithSceneView()',
          category: LogCategory.captions);
      _logger.i(
          '🔍 [SPATIAL INTEGRATION] Looking for ARSCNView/SceneView in view hierarchy...',
          category: LogCategory.captions);

      final sceneViewInitialized =
          await SpatialCaptions.initializeWithSceneView();

      _logger.i(
          '📊 [SPATIAL INTEGRATION] SpatialCaptions.initializeWithSceneView() returned: $sceneViewInitialized',
          category: LogCategory.captions);

      if (!sceneViewInitialized) {
        _logger.w(
            '⚠️ [SPATIAL INTEGRATION] AR scene view not yet available. Spatial captions will start once the scene is ready.',
            category: LogCategory.captions);
        _isSpatialCaptionsReady = false;
        return;
      }

      _logger.i(
          '🎉 [SPATIAL INTEGRATION] SUCCESS: Scene view found and plugin initialized!',
          category: LogCategory.captions);
      _logger.i('✅ [SPATIAL INTEGRATION] Spatial captions ready for use',
          category: LogCategory.captions);
      _isSpatialCaptionsReady = true;
    } on MissingPluginException catch (e, stackTrace) {
      _logger.w(
          '⚠️ [SPATIAL INTEGRATION] Spatial captions plugin not found on ${Platform.operatingSystem}.',
          category: LogCategory.captions,
          error: e,
          stackTrace: stackTrace);
      _logger.w(
          '⚠️ [SPATIAL INTEGRATION] Continuing without spatial captions support.',
          category: LogCategory.captions);
      _isSpatialCaptionsReady = false;
      return;
    } catch (e, stackTrace) {
      _logger.e('💥 [SPATIAL INTEGRATION] INITIALIZATION FAILED!',
          category: LogCategory.captions, error: e, stackTrace: stackTrace);
      _logger.e(
          '❌ [SPATIAL INTEGRATION] Will not proceed with AR View presentation',
          category: LogCategory.captions);
      _isSpatialCaptionsReady = false;
      rethrow; // Re-throw to prevent AR View from starting
    }

    // Configure spatial captions
    _logger.i(
        '⚙️ [SPATIAL INTEGRATION] Configuring spatial captions settings...',
        category: LogCategory.captions);

    // Lock to landscape mode as requested
    _logger.i(
        '🔒 [SPATIAL INTEGRATION] Setting orientation lock to landscape...',
        category: LogCategory.captions);
    await _spatialCaptionsCubit.setOrientationLock(true);
    _logger.i('✅ [SPATIAL INTEGRATION] Orientation locked to landscape',
        category: LogCategory.captions);

    // Set default caption duration
    _logger.i(
        '⏱️ [SPATIAL INTEGRATION] Setting caption duration to 6 seconds...',
        category: LogCategory.captions);
    _spatialCaptionsCubit.setCaptionDuration(const Duration(seconds: 6));
    _logger.i('✅ [SPATIAL INTEGRATION] Caption duration configured',
        category: LogCategory.captions);

    // Test plugin connection
    _logger.i('🔌 [SPATIAL INTEGRATION] Testing plugin connection...',
        category: LogCategory.captions);
    try {
      await SpatialCaptions.testConnection();
      _logger.i('✅ [SPATIAL INTEGRATION] Plugin connection test PASSED',
          category: LogCategory.captions);
    } catch (e, stackTrace) {
      _logger.e('❌ [SPATIAL INTEGRATION] Plugin connection test FAILED',
          category: LogCategory.captions, error: e, stackTrace: stackTrace);
    }

    _logger.i('🎆 ============ SPATIAL CAPTION INTEGRATION READY ============',
        category: LogCategory.captions);
  }

  /// Update the last audio frame for direction estimation
  void updateAudioFrame(StereoAudioFrame frame) {
    _lastAudioFrame = frame;
  }

  /// Estimate the current speaker direction based on the last audio frame.
  String get currentDirection {
    if (_lastAudioFrame == null) {
      _logger.d('🔊 [DIRECTION] No audio frame, defaulting to center.',
          category: LogCategory.speech);
      return 'center';
    }
    try {
      final angle =
          _speechLocalizer.estimateDirectionAdvanced(_lastAudioFrame!);
      _logger.d(
          '🔊 [DIRECTION] Estimated angle: ${angle.toStringAsFixed(2)} rad',
          category: LogCategory.speech);

      // Simple thresholding to convert angle to a direction string.
      if (angle < -0.4) return 'left'; // > ~23 degrees left
      if (angle > 0.4) return 'right'; // > ~23 degrees right
      return 'center';
    } catch (e) {
      _logger.w('⚠️ [DIRECTION] Error estimating direction: $e',
          category: LogCategory.speech);
      return 'center';
    }
  }

  /// Process a partial speech result
  Future<void> processPartialResult(SpeechResult result) async {
    _logger.i(
        '🎤 [SPATIAL INTEGRATION] Processing partial result: "${result.text}" (confidence: ${result.confidence})',
        category: LogCategory.captions);

    if (!_isSpatialCaptionsReady) {
      _logger.w(
          '⚠️ [SPATIAL INTEGRATION] Spatial captions not ready - skipping partial caption push to native layer',
          category: LogCategory.captions);
      return;
    }

    try {
      // Get position from audio direction
      final position = await _calculateCaptionPosition(result);
      _logger.d(
          '📍 [SPATIAL INTEGRATION] Calculated position for partial caption: $position',
          category: LogCategory.captions);

      // Use speaker direction as a simple speaker ID
      final speakerId = _resolveSpeakerId(result);
      _logger.d(
          '👤 [SPATIAL INTEGRATION] Using speaker ID: $speakerId for partial caption',
          category: LogCategory.captions);

      // Add partial caption through spatial plugin
      await _spatialCaptionsCubit.addPartialCaption(
        text: result.text,
        position: position,
        speakerId: speakerId,
        confidence: result.confidence,
      );

      _logger.i(
          '✅ [SPATIAL INTEGRATION] Partial caption added successfully at position: $position',
          category: LogCategory.captions);
    } catch (e, stackTrace) {
      _logger.e('❌ [SPATIAL INTEGRATION] Error processing partial result: $e',
          category: LogCategory.captions, error: e, stackTrace: stackTrace);
      rethrow; // Re-throw to allow fallback in LiveCaptionsCubit
    }
  }

  /// Process a final speech result
  Future<void> processFinalResult(SpeechResult result) async {
    _logger.i(
        '📝 [SPATIAL INTEGRATION] Processing final result: "${result.text}" (confidence: ${result.confidence})',
        category: LogCategory.captions);

    if (!_isSpatialCaptionsReady) {
      _logger.w(
          '⚠️ [SPATIAL INTEGRATION] Spatial captions not ready - skipping final caption push to native layer',
          category: LogCategory.captions);
      return;
    }

    try {
      // Get position from audio direction or active face anchor
      final position = await _calculateCaptionPosition(result);

      // Resolve the active speaker ID if available
      final speakerId = _resolveSpeakerId(result);

      // Add final caption (will replace partial)
      await _spatialCaptionsCubit.finalizeCaption(
        text: result.text,
        position: position,
        speakerId: speakerId,
        confidence: result.confidence,
      );

      // Schedule enhancement with Gemma
      _scheduleEnhancement(result, speakerId);

      _logger.i('✅ Final caption added and enhancement scheduled',
          category: LogCategory.captions);
    } catch (e) {
      _logger.e('❌ Error processing final result: $e',
          category: LogCategory.captions);
    }
  }

  /// Calculate caption position based on audio direction and hybrid localization
  Future<Vector3> _calculateCaptionPosition(SpeechResult result) async {
    final coordinator = GetIt.I.isRegistered<SpatialAnchorCoordinator>()
        ? GetIt.I<SpatialAnchorCoordinator>()
        : null;
    final speakerMetadata = result.metadata;
    final spatialConfidence = result.confidence;

    final anchorPosition = _activeSpeakerPositionIfFresh();
    if (anchorPosition != null) {
      _logger.i(
          '?? [POSITION] Using active speaker anchor position: $anchorPosition',
          category: LogCategory.captions);
      if (coordinator != null) {
        final decision = coordinator.chooseAnchor(
          fusedTransformPosition: anchorPosition,
          speakerMetadata: speakerMetadata,
          spatialConfidence: spatialConfidence,
        );
        return decision.position;
      }
      return anchorPosition;
    }
    _logger.i('🎯 [POSITION] ===== CALCULATING CAPTION POSITION =====',
        category: LogCategory.captions);
    _logger.i('🎯 [POSITION] Text: "${result.text}"',
        category: LogCategory.captions);
    _logger.i(
        '🎯 [POSITION] Speaker direction in result: ${result.speakerDirection ?? "NULL"}',
        category: LogCategory.captions);
    _logger.i('🎯 [POSITION] Has audio frame: ${_lastAudioFrame != null}',
        category: LogCategory.captions);
    if (_lastAudioFrame != null) {
      _logger.i(
          '🎯 [POSITION] Audio frame channels: L=${_lastAudioFrame!.left.length} samples, R=${_lastAudioFrame!.right.length} samples',
          category: LogCategory.captions);
    }

    try {
      // First, try to get position from hybrid localization engine
      _logger.i('🎯 [POSITION] Attempting HYBRID localization...',
          category: LogCategory.captions);
      final fusedTransform =
          await _hybridLocalizationEngine.getFusedTransform();
      _logger.i(
          '🎯 [POSITION] Hybrid transform length: ${fusedTransform.length}',
          category: LogCategory.captions);

      if (fusedTransform.length == 16) {
        // Extract position from 4x4 transform matrix (last column)
        final x = fusedTransform[12];
        final y = fusedTransform[13];
        final z = fusedTransform[14];

        _logger.i('🎯 [POSITION] USING HYBRID LOCALIZATION',
            category: LogCategory.captions);
        _logger.i('🎯 [POSITION] Position: x=$x, y=$y, z=$z',
            category: LogCategory.captions);
        final fusedPosition = Vector3(x, y, z);
        if (coordinator != null) {
          final decision = coordinator.chooseAnchor(
            fusedTransformPosition: fusedPosition,
            speakerMetadata: speakerMetadata,
            spatialConfidence: spatialConfidence,
          );
          return decision.position;
        }
        return fusedPosition;
      } else {
        _logger.w(
            '⚠️ [POSITION] Hybrid transform invalid (expected 16, got ${fusedTransform.length})',
            category: LogCategory.captions);
      }
    } catch (e) {
      _logger.w('⚠️ [POSITION] Hybrid localization error: $e',
          category: LogCategory.captions);
    }

    final metadataPosition =
        _positionFromSpeakerMetadata(speakerMetadata, spatialConfidence);
    if (metadataPosition != null) {
      _logger.i(
        '🎯 [POSITION] Using metadata-derived position $metadataPosition',
        category: LogCategory.captions,
      );
      if (coordinator != null) {
        final decision = coordinator.chooseAnchor(
          fusedTransformPosition: metadataPosition,
          speakerMetadata: speakerMetadata,
          spatialConfidence: spatialConfidence,
        );
        return decision.position;
      }
      return metadataPosition;
    }

    // Fallback: Check if we have speaker direction information
    if (result.speakerDirection != null) {
      _logger.i(
          '📍 [POSITION] USING SPEAKER DIRECTION: ${result.speakerDirection}',
          category: LogCategory.captions);

      // Convert direction string to angle
      double angle = 0.0;
      switch (result.speakerDirection) {
        case 'left':
          angle = -pi / 4; // 45 degrees left
          _logger.i('📍 [POSITION] Left → -45° (-π/4 rad)',
              category: LogCategory.captions);
          break;
        case 'right':
          angle = pi / 4; // 45 degrees right
          _logger.i('📍 [POSITION] Right → +45° (π/4 rad)',
              category: LogCategory.captions);
          break;
        case 'center':
        default:
          angle = 0.0;
          _logger.i('📍 [POSITION] Center → 0°',
              category: LogCategory.captions);
      }

      final pos = Vector3(
        defaultCaptionDistance * sin(angle),
        captionHeight,
        -defaultCaptionDistance * cos(angle),
      );
      _publishDoaEstimate(angle, result.confidence);
      if (coordinator != null) {
        final decision = coordinator.chooseAnchor(
          fusedTransformPosition: null,
          speakerMetadata: speakerMetadata,
          spatialConfidence: spatialConfidence,
        );
        return decision.position;
      }
      _logger.i(
          '📍 [POSITION] Final position: (${pos.x.toStringAsFixed(2)}, ${pos.y.toStringAsFixed(2)}, ${pos.z.toStringAsFixed(2)})',
          category: LogCategory.captions);
      return pos;
    } else {
      _logger.w('⚠️ [POSITION] No speaker direction in result',
          category: LogCategory.captions);
    }

    // Try to estimate from audio if we have a recent frame
    if (_lastAudioFrame != null) {
      _logger.i('🔊 [POSITION] ATTEMPTING AUDIO DIRECTION ESTIMATION',
          category: LogCategory.captions);
      _logger.i('🔊 [POSITION] Frame timestamp: ${DateTime.now()}',
          category: LogCategory.captions);

      try {
        // Log RMS values
        final leftRms = _calculateRMS(_lastAudioFrame!.left);
        final rightRms = _calculateRMS(_lastAudioFrame!.right);
        _logger.i(
            '🔊 [POSITION] RMS values: L=${leftRms.toStringAsFixed(4)}, R=${rightRms.toStringAsFixed(4)}',
            category: LogCategory.captions);

        final direction =
            _speechLocalizer.estimateDirectionAdvanced(_lastAudioFrame!);
        _logger.i(
            '🔊 [POSITION] Direction result: ${direction.toStringAsFixed(3)} rad (${(direction * 180 / pi).toStringAsFixed(1)}°)',
            category: LogCategory.captions);

        // Feed the audio direction to hybrid localization for future use
        await _hybridLocalizationEngine.feedAudioDirection(
          angle: direction,
          confidence: result.confidence,
        );
        _publishDoaEstimate(direction, result.confidence);

        final pos = Vector3(
          defaultCaptionDistance * sin(direction),
          captionHeight,
          -defaultCaptionDistance * cos(direction),
        );
        if (coordinator != null) {
          final decision = coordinator.chooseAnchor(
            fusedTransformPosition: null,
            speakerMetadata: speakerMetadata,
            spatialConfidence: spatialConfidence,
          );
          return decision.position;
        }
        _logger.i('🔊 [POSITION] USING AUDIO DIRECTION',
            category: LogCategory.captions);
        _logger.i(
            '🔊 [POSITION] Final position: (${pos.x.toStringAsFixed(2)}, ${pos.y.toStringAsFixed(2)}, ${pos.z.toStringAsFixed(2)})',
            category: LogCategory.captions);
        return pos;
      } catch (e, stackTrace) {
        _logger.e('❌ [POSITION] Audio direction estimation failed',
            category: LogCategory.captions, error: e, stackTrace: stackTrace);
      }
    } else {
      _logger.w(
          '⚠️ [POSITION] NO AUDIO FRAME AVAILABLE - updateAudioFrame() may not be called',
          category: LogCategory.captions);
      _logger.w(
          '⚠️ [POSITION] Need to check where audio frames should be provided',
          category: LogCategory.captions);
    }

    // Default: place in front of user
    _logger.i('📍 [POSITION] USING DEFAULT CENTER POSITION',
        category: LogCategory.captions);
    _logger.i(
        '📍 [POSITION] Position: (0, $captionHeight, -$defaultCaptionDistance)',
        category: LogCategory.captions);
    final defaultPosition = Vector3(0, captionHeight, -defaultCaptionDistance);
    if (coordinator != null) {
      final decision = coordinator.chooseAnchor(
        fusedTransformPosition: null,
        speakerMetadata: speakerMetadata,
        spatialConfidence: spatialConfidence,
      );
      return decision.position;
    }
    return defaultPosition;
  }

  /// Helper method to calculate RMS for logging
  double _calculateRMS(Float32List samples) {
    double sum = 0.0;
    for (var sample in samples) {
      sum += sample * sample;
    }
    return sqrt(sum / samples.length);
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
      _logger.i('🤖 Enhancing caption with Gemma: "${result.text}"',
          category: LogCategory.captions);

      // Get the latest final caption for this speaker
      final latestCaptions = _spatialCaptionsCubit.state.latestCaptionBySpeaker;
      final captionToEnhance = latestCaptions[speakerId];

      if (captionToEnhance == null || !captionToEnhance.isFinal) {
        _logger.w('⚠️ No final caption found to enhance',
            category: LogCategory.captions);
        return;
      }

      // Process with Gemma for enhancement
      final enhancedText = await _gemmaService.enhanceText(
        captionToEnhance.text,
      );

      if (enhancedText != captionToEnhance.text) {
        // Update with enhanced text
        await _spatialCaptionsCubit.enhanceCaption(
          captionId: captionToEnhance.id,
          enhancedText: enhancedText,
        );

        _logger.i('✅ Caption enhanced: "$enhancedText"',
            category: LogCategory.captions);
      }
    } catch (e) {
      _logger.e('❌ Error enhancing caption: $e',
          category: LogCategory.captions);
    }
  }

  // Removed: Event-driven retry mechanism (no longer needed)

  /// Clear all captions
  Future<void> clearAllCaptions() async {
    _logger.i('🧹 Clearing all spatial captions',
        category: LogCategory.captions);

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
    _logger.i('⏱️ Setting caption duration to: ${duration.inSeconds}s',
        category: LogCategory.captions);
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

  String _resolveSpeakerId(SpeechResult result) {
    final metadata = result.metadata;
    final faceIdFromMetadata = metadata?['speakerFaceId'];
    if (faceIdFromMetadata is int) {
      return 'face_$faceIdFromMetadata';
    }
    if (_activeSpeaker != null && _activeSpeakerUpdatedAt != null) {
      final age = DateTime.now().difference(_activeSpeakerUpdatedAt!);
      if (age <= _activeSpeakerFreshFor) {
        return 'face_${_activeSpeaker!.faceId}';
      }
    }
    return result.speakerDirection ?? 'default';
  }

  Vector3? _activeSpeakerPositionIfFresh() {
    final speaker = _activeSpeaker;
    if (speaker == null || _activeSpeakerUpdatedAt == null) {
      return null;
    }
    if (DateTime.now().difference(_activeSpeakerUpdatedAt!) >
        _activeSpeakerFreshFor) {
      return null;
    }
    final transform = speaker.worldTransform;
    if (transform == null || transform.length != 16) {
      return null;
    }
    return Vector3(transform[12], transform[13], transform[14]);
  }

  Vector3? _positionFromSpeakerMetadata(
    Map<String, dynamic>? metadata,
    double spatialConfidence,
  ) {
    if (metadata == null) {
      return null;
    }
    final worldTransform =
        (metadata['speakerWorldTransform'] as List<dynamic>?)?.cast<double>();
    if (worldTransform != null && worldTransform.length == 16) {
      final position =
          Vector3(worldTransform[12], worldTransform[13], worldTransform[14]);
      _logger.d(
        '🎯 [POSITION] Using speakerWorldTransform from metadata: $position',
        category: LogCategory.captions,
      );
      return position;
    }

    final bboxMap = metadata['speakerBoundingBox'];
    if (bboxMap is Map) {
      final left = (bboxMap['left'] as num?)?.toDouble();
      final top = (bboxMap['top'] as num?)?.toDouble();
      final width = (bboxMap['width'] as num?)?.toDouble();
      final height = (bboxMap['height'] as num?)?.toDouble();
      if (left != null && top != null && width != null && height != null) {
        final centerX = (left + width / 2).clamp(0.0, 1.0);
        final centerY = (top + height / 2).clamp(0.0, 1.0);
        final horizontalSpread = 1.6;
        final verticalSpread = 0.8;
        final position = Vector3(
          (centerX - 0.5) * horizontalSpread,
          captionHeight + (0.5 - centerY) * verticalSpread,
          -defaultCaptionDistance,
        );
        _logger.d(
          '🧭 [POSITION] Derived position from bounding box center=($centerX,$centerY) => $position',
          category: LogCategory.captions,
        );
        _publishDoaEstimate(
          (centerX - 0.5) * pi / 2,
          spatialConfidence,
        );
        return position;
      }
    }
    return null;
  }

  void _publishDoaEstimate(double azimuth, double confidence) {
    if (!GetIt.I.isRegistered<PredictiveStreamHub>()) {
      return;
    }
    try {
      GetIt.I<PredictiveStreamHub>().sensors.publishDoa(
            DoaEstimate(
              azimuth: azimuth,
              elevation: 0.0,
              confidence: confidence.clamp(0.0, 1.0).toDouble(),
            ),
          );
    } catch (e, stackTrace) {
      _logger.w(
        '⚠️ [SPATIAL] Failed to publish DOA estimate',
        category: LogCategory.captions,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void updateActiveSpeaker(DetectedSpeaker? speaker) {
    _activeSpeaker = speaker;
    _activeSpeakerUpdatedAt = speaker == null ? null : DateTime.now();
    if (speaker?.worldTransform != null &&
        speaker!.worldTransform!.length == 16) {
      unawaited(
        _hybridLocalizationEngine.updateWithVisualMeasurement(
          transform: speaker.worldTransform!,
          confidence: speaker.confidence,
        ),
      );
    }
  }
}
