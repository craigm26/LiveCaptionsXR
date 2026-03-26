import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:vector_math/vector_math_64.dart';
import 'package:spatial_captions/spatial_captions.dart';
import 'package:spatial_captions/cubit/spatial_captions_cubit.dart';
import '../models/speech_result.dart';
import '../models/speaker_profile.dart';
import 'speech_localizer.dart';
import 'stereo_audio_capture.dart';
import 'gemma_3n_service.dart';
import 'app_logger.dart';
import 'hybrid_localization_engine.dart';
import 'speaker_diarization_service.dart';
import 'glasses_service.dart';

class DirectionUpdate {
  final String direction;
  final double confidence;
  final DateTime timestamp;
  /// Precise angle in radians (negative = left, 0 = center, positive = right).
  /// When available, enables more responsive directional pointer animation.
  final double angle;

  const DirectionUpdate({
    required this.direction,
    required this.confidence,
    required this.timestamp,
    this.angle = 0.0,
  });
}

/// Service that integrates live captions with spatial positioning in AR
/// 
/// Implements 3D/4D spatial intelligence by:
/// - Using speaker diarization to identify unique speakers
/// - Tracking speaker positions in 3D space over time (4D)
/// - Mapping translations to speaker locations
/// - Smoothing position estimates with temporal filtering
class SpatialCaptionIntegrationService {
  final SpatialCaptionsCubit _spatialCaptionsCubit;
  final SpeechLocalizer _speechLocalizer;
  final Gemma3nService _gemmaService;
  final HybridLocalizationEngine _hybridLocalizationEngine;
  final SpeakerDiarizationService _speakerDiarizationService;
  final GlassesService? _glassesService;
  final AppLogger _logger = AppLogger.instance;
  
  // Removed: Method channel for AR session events (no longer needed)

  // Configuration
  static const double defaultCaptionDistance = 2.0; // meters
  static const double captionHeight = 0.0; // eye level
  
  // Track ongoing enhancements
  final Map<String, Timer> _enhancementTimers = {};

  final StreamController<DirectionUpdate> _directionUpdateController =
      StreamController<DirectionUpdate>.broadcast();
  
  // Track last audio frame for direction estimation
  StereoAudioFrame? _lastAudioFrame;
  
  // Speaker diarization enabled flag
  bool _diarizationEnabled = true;
  
  SpatialCaptionIntegrationService({
    required SpatialCaptionsCubit spatialCaptionsCubit,
    required SpeechLocalizer speechLocalizer,
    required Gemma3nService gemmaService,
    required HybridLocalizationEngine hybridLocalizationEngine,
    required SpeakerDiarizationService speakerDiarizationService,
    GlassesService? glassesService,
  })  : _spatialCaptionsCubit = spatialCaptionsCubit,
        _speechLocalizer = speechLocalizer,
        _gemmaService = gemmaService,
        _hybridLocalizationEngine = hybridLocalizationEngine,
        _speakerDiarizationService = speakerDiarizationService,
        _glassesService = glassesService;

  /// Initialize the service and set landscape orientation
  Future<void> initialize() async {
    _logger.i('🚀 ============ SPATIAL CAPTION INTEGRATION SERVICE INIT ============', category: LogCategory.captions);
    _logger.i('🚀 NEW APPROACH: Single initialization attempt (no retry mechanism)', category: LogCategory.captions);
    
    // Initialize plugin with AR scene view (iOS only) - single attempt since AR View should be ready
    try {
      _logger.i('🎯 [SPATIAL INTEGRATION] About to call SpatialCaptions.initializeWithSceneView()', category: LogCategory.captions);
      _logger.i('🔍 [SPATIAL INTEGRATION] Looking for ARSCNView in view hierarchy...', category: LogCategory.captions);
      
      final sceneViewInitialized = await SpatialCaptions.initializeWithSceneView();
      
      _logger.i('📊 [SPATIAL INTEGRATION] SpatialCaptions.initializeWithSceneView() returned: $sceneViewInitialized', category: LogCategory.captions);
      
      if (!sceneViewInitialized) {
        _logger.e('🚨 [SPATIAL INTEGRATION] CRITICAL: ARSCNView not found in view hierarchy!', category: LogCategory.captions);
        _logger.e('❌ [SPATIAL INTEGRATION] This means AR View is not presented yet or ARSCNView creation failed', category: LogCategory.captions);
        throw Exception('ARSCNView not available for spatial captions initialization');
      }
      
      _logger.i('🎉 [SPATIAL INTEGRATION] SUCCESS: ARSCNView found and plugin initialized!', category: LogCategory.captions);
      _logger.i('✅ [SPATIAL INTEGRATION] Spatial captions ready for use', category: LogCategory.captions);
    } catch (e, stackTrace) {
      _logger.e('💥 [SPATIAL INTEGRATION] INITIALIZATION FAILED!', category: LogCategory.captions, error: e, stackTrace: stackTrace);
      _logger.e('❌ [SPATIAL INTEGRATION] Will not proceed with AR View presentation', category: LogCategory.captions);
      rethrow; // Re-throw to prevent AR View from starting
    }
    
    // Configure spatial captions
    _logger.i('⚙️ [SPATIAL INTEGRATION] Configuring spatial captions settings...', category: LogCategory.captions);
    
    // Lock to landscape mode as requested
    _logger.i('🔒 [SPATIAL INTEGRATION] Setting orientation lock to landscape...', category: LogCategory.captions);
    await _spatialCaptionsCubit.setOrientationLock(true);
    _logger.i('✅ [SPATIAL INTEGRATION] Orientation locked to landscape', category: LogCategory.captions);
    
    // Set default caption duration
    _logger.i('⏱️ [SPATIAL INTEGRATION] Setting caption duration to 6 seconds...', category: LogCategory.captions);
    _spatialCaptionsCubit.setCaptionDuration(const Duration(seconds: 6));
    _logger.i('✅ [SPATIAL INTEGRATION] Caption duration configured', category: LogCategory.captions);
    
    // Test plugin connection
    _logger.i('🔌 [SPATIAL INTEGRATION] Testing plugin connection...', category: LogCategory.captions);
    try {
      await SpatialCaptions.testConnection();
      _logger.i('✅ [SPATIAL INTEGRATION] Plugin connection test PASSED', category: LogCategory.captions);
    } catch (e, stackTrace) {
      _logger.e('❌ [SPATIAL INTEGRATION] Plugin connection test FAILED', category: LogCategory.captions, error: e, stackTrace: stackTrace);
    }
    
    _logger.i('🎆 ============ SPATIAL CAPTION INTEGRATION READY ============', category: LogCategory.captions);
  }

  /// Update the last audio frame for direction estimation
  void updateAudioFrame(StereoAudioFrame frame) {
    _lastAudioFrame = frame;
  }

  Stream<DirectionUpdate> get directionUpdates => _directionUpdateController.stream;

  /// Process a partial speech result with speaker diarization
  Future<SpeechResult> processPartialResult(SpeechResult result) async {
    _logger.i('🎤 [SPATIAL INTEGRATION] Processing partial result: "${result.text}" (confidence: ${result.confidence})', category: LogCategory.captions);
    
    try {
      SpeakerIdentificationResult? speakerResult;
      Vector3 position;
      String speakerId;
      
      // Try speaker diarization if audio frame is available
      if (_diarizationEnabled && _lastAudioFrame != null) {
        try {
          speakerResult = await _speakerDiarizationService.identifySpeaker(_lastAudioFrame!);
          position = speakerResult.estimatedPosition;
          speakerId = speakerResult.speakerId;
          
          _logger.i('👤 [DIARIZATION] Speaker identified: ${speakerResult.profile.displayName ?? speakerId} '
              '(confidence: ${speakerResult.confidence.toStringAsFixed(2)}, '
              'new: ${speakerResult.isNewSpeaker})', category: LogCategory.captions);
        } catch (e) {
          _logger.w('⚠️ [DIARIZATION] Failed, falling back to direction: $e', category: LogCategory.captions);
          position = await _calculateCaptionPosition(result);
          speakerId = result.speakerDirection ?? 'default';
        }
      } else {
        // Fall back to audio direction
        position = await _calculateCaptionPosition(result);
        speakerId = result.speakerDirection ?? 'default';
      }
      
      _logger.d('📍 [SPATIAL INTEGRATION] Position: $position, Speaker: $speakerId', category: LogCategory.captions);

      final partialDirection = _deriveDirection(result, position);
      _directionUpdateController.add(
        DirectionUpdate(
          direction: partialDirection,
          confidence: result.confidence,
          timestamp: DateTime.now(),
          angle: _deriveAngle(position),
        ),
      );
      
      // Add partial caption through spatial plugin
      await _spatialCaptionsCubit.addPartialCaption(
        text: result.text,
        position: position,
        speakerId: speakerId,
        confidence: result.confidence,
      );
      
      _logger.i('✅ [SPATIAL INTEGRATION] Partial caption added at position: $position', category: LogCategory.captions);
      
      // Return enriched result with speaker data
      return result.copyWith(
        speakerId: speakerId,
        speakerDisplayName: speakerResult?.profile.displayName,
        speakerColor: speakerResult?.profile.colorValue,
        speakerPosition: position,
        speakerConfidence: speakerResult?.confidence,
      );
    } catch (e, stackTrace) {
      _logger.e('❌ [SPATIAL INTEGRATION] Error processing partial result: $e', category: LogCategory.captions, error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Process a final speech result with speaker diarization
  Future<SpeechResult> processFinalResult(SpeechResult result) async {
    _logger.i('📝 [SPATIAL INTEGRATION] Processing final result: "${result.text}" (confidence: ${result.confidence})', category: LogCategory.captions);
    
    try {
      SpeakerIdentificationResult? speakerResult;
      Vector3 position;
      String speakerId;
      
      // Try speaker diarization if audio frame is available
      if (_diarizationEnabled && _lastAudioFrame != null) {
        try {
          speakerResult = await _speakerDiarizationService.identifySpeaker(_lastAudioFrame!);
          position = speakerResult.estimatedPosition;
          speakerId = speakerResult.speakerId;
          
          _logger.i('👤 [DIARIZATION] Final caption speaker: ${speakerResult.profile.displayName ?? speakerId} '
              'at ${position.toString()}', category: LogCategory.captions);
        } catch (e) {
          _logger.w('⚠️ [DIARIZATION] Failed, falling back to direction: $e', category: LogCategory.captions);
          position = await _calculateCaptionPosition(result);
          speakerId = result.speakerDirection ?? 'default';
        }
      } else {
        position = await _calculateCaptionPosition(result);
        speakerId = result.speakerDirection ?? 'default';
      }
      
      // Add final caption (will replace partial)
      await _spatialCaptionsCubit.finalizeCaption(
        text: result.text,
        position: position,
        speakerId: speakerId,
        confidence: result.confidence,
      );

      final finalDirection = _deriveDirection(result, position);
      _directionUpdateController.add(
        DirectionUpdate(
          direction: finalDirection,
          confidence: result.confidence,
          timestamp: DateTime.now(),
          angle: _deriveAngle(position),
        ),
      );
      
      // Forward caption to AI glasses if connected
      _glassesService?.sendCaption(result.text);

      // Schedule enhancement with Gemma
      _scheduleEnhancement(result, speakerId);

      _logger.i('✅ Final caption added and enhancement scheduled', category: LogCategory.captions);
      
      // Return enriched result with speaker data
      return result.copyWith(
        speakerId: speakerId,
        speakerDisplayName: speakerResult?.profile.displayName,
        speakerColor: speakerResult?.profile.colorValue,
        speakerPosition: position,
        speakerConfidence: speakerResult?.confidence,
      );
    } catch (e, stackTrace) {
      _logger.e('❌ Error processing final result: $e', category: LogCategory.captions, error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Calculate caption position based on audio direction and hybrid localization
  Future<Vector3> _calculateCaptionPosition(SpeechResult result) async {
    _logger.i('🎯 [POSITION] ===== CALCULATING CAPTION POSITION =====', category: LogCategory.captions);
    _logger.i('🎯 [POSITION] Text: "${result.text}"', category: LogCategory.captions);
    _logger.i('🎯 [POSITION] Speaker direction in result: ${result.speakerDirection ?? "NULL"}', category: LogCategory.captions);
    _logger.i('🎯 [POSITION] Has audio frame: ${_lastAudioFrame != null}', category: LogCategory.captions);
    if (_lastAudioFrame != null) {
      _logger.i('🎯 [POSITION] Audio frame channels: L=${_lastAudioFrame!.left.length} samples, R=${_lastAudioFrame!.right.length} samples', category: LogCategory.captions);
    }
    
    try {
      // First, try to get position from hybrid localization engine
      _logger.i('🎯 [POSITION] Attempting HYBRID localization...', category: LogCategory.captions);
      final fusedTransform = await _hybridLocalizationEngine.getFusedTransform();
      _logger.i('🎯 [POSITION] Hybrid transform length: ${fusedTransform.length}', category: LogCategory.captions);
      
      if (fusedTransform.length == 16) {
        // Extract position from 4x4 transform matrix (last column)
        final x = fusedTransform[12];
        final y = fusedTransform[13];
        final z = fusedTransform[14];
        
        _logger.i('🎯 [POSITION] USING HYBRID LOCALIZATION', category: LogCategory.captions);
        _logger.i('🎯 [POSITION] Position: x=$x, y=$y, z=$z', category: LogCategory.captions);
        return Vector3(x, y, z);
      } else {
        _logger.w('⚠️ [POSITION] Hybrid transform invalid (expected 16, got ${fusedTransform.length})', category: LogCategory.captions);
      }
    } catch (e) {
      _logger.w('⚠️ [POSITION] Hybrid localization error: $e', category: LogCategory.captions);
    }
    
    // Fallback: Check if we have speaker direction information
    if (result.speakerDirection != null) {
      _logger.i('📍 [POSITION] USING SPEAKER DIRECTION: ${result.speakerDirection}', category: LogCategory.captions);
      
      // Convert direction string to angle
      double angle = 0.0;
      switch (result.speakerDirection) {
        case 'left':
          angle = -pi / 4; // 45 degrees left
          _logger.i('📍 [POSITION] Left → -45° (-π/4 rad)', category: LogCategory.captions);
          break;
        case 'right':
          angle = pi / 4; // 45 degrees right
          _logger.i('📍 [POSITION] Right → +45° (π/4 rad)', category: LogCategory.captions);
          break;
        case 'center':
        default:
          angle = 0.0;
          _logger.i('📍 [POSITION] Center → 0°', category: LogCategory.captions);
      }
      
      final pos = Vector3(
        defaultCaptionDistance * sin(angle),
        captionHeight,
        -defaultCaptionDistance * cos(angle),
      );
      _logger.i('📍 [POSITION] Final position: (${pos.x.toStringAsFixed(2)}, ${pos.y.toStringAsFixed(2)}, ${pos.z.toStringAsFixed(2)})', category: LogCategory.captions);
      return pos;
    } else {
      _logger.w('⚠️ [POSITION] No speaker direction in result', category: LogCategory.captions);
    }
    
    // Try to estimate from audio if we have a recent frame
    if (_lastAudioFrame != null) {
      _logger.i('🔊 [POSITION] ATTEMPTING AUDIO DIRECTION ESTIMATION', category: LogCategory.captions);
      _logger.i('🔊 [POSITION] Frame timestamp: ${DateTime.now()}', category: LogCategory.captions);
      
      try {
        // Log RMS values
        final leftRms = _calculateRMS(_lastAudioFrame!.left);
        final rightRms = _calculateRMS(_lastAudioFrame!.right);
        _logger.i('🔊 [POSITION] RMS values: L=${leftRms.toStringAsFixed(4)}, R=${rightRms.toStringAsFixed(4)}', category: LogCategory.captions);
        
        final direction = _speechLocalizer.estimateDirectionAdvanced(_lastAudioFrame!);
        _logger.i('🔊 [POSITION] Direction result: ${direction.toStringAsFixed(3)} rad (${(direction * 180 / pi).toStringAsFixed(1)}°)', category: LogCategory.captions);
        
        // Feed the audio direction to hybrid localization for future use
        await _hybridLocalizationEngine.feedAudioDirection(
          angle: direction,
          confidence: result.confidence,
        );
        
        final pos = Vector3(
          defaultCaptionDistance * sin(direction),
          captionHeight,
          -defaultCaptionDistance * cos(direction),
        );
        _logger.i('🔊 [POSITION] USING AUDIO DIRECTION', category: LogCategory.captions);
        _logger.i('🔊 [POSITION] Final position: (${pos.x.toStringAsFixed(2)}, ${pos.y.toStringAsFixed(2)}, ${pos.z.toStringAsFixed(2)})', category: LogCategory.captions);
        return pos;
      } catch (e, stackTrace) {
        _logger.e('❌ [POSITION] Audio direction estimation failed', category: LogCategory.captions, error: e, stackTrace: stackTrace);
      }
    } else {
      _logger.w('⚠️ [POSITION] NO AUDIO FRAME AVAILABLE - updateAudioFrame() may not be called', category: LogCategory.captions);
      _logger.w('⚠️ [POSITION] Need to check where audio frames should be provided', category: LogCategory.captions);
    }
    
    // Default: place in front of user
    _logger.i('📍 [POSITION] USING DEFAULT CENTER POSITION', category: LogCategory.captions);
    _logger.i('📍 [POSITION] Position: (0, $captionHeight, -$defaultCaptionDistance)', category: LogCategory.captions);
    return Vector3(0, captionHeight, -defaultCaptionDistance);
  }
  
  /// Helper method to calculate RMS for logging
  double _calculateRMS(Float32List samples) {
    double sum = 0.0;
    for (var sample in samples) {
      sum += sample * sample;
    }
    return sqrt(sum / samples.length);
  }

  String _deriveDirection(SpeechResult result, Vector3 position) {
    if (result.speakerDirection != null && result.speakerDirection!.isNotEmpty) {
      return result.speakerDirection!;
    }

    if (position.x < -0.25) return 'left';
    if (position.x > 0.25) return 'right';
    return 'center';
  }

  /// Compute horizontal angle (radians) from a 3D speaker position.
  /// Returns value in (-π/2, π/2): negative = left, 0 = center, positive = right.
  double _deriveAngle(Vector3 position) {
    final denom = position.x.abs() + position.z.abs().clamp(0.1, double.infinity);
    return position.x.sign * (position.x.abs() / denom) * (pi / 2);
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
      if (!_gemmaService.isReady) {
        _logger.w('⚠️ Gemma not ready - keeping basic caption without enhancement', category: LogCategory.captions);
        return;
      }

      _logger.i('🤖 Enhancing caption with Gemma: "${result.text}"', category: LogCategory.captions);
      
      // Get the latest final caption for this speaker
      final latestCaptions = _spatialCaptionsCubit.state.latestCaptionBySpeaker;
      final captionToEnhance = latestCaptions[speakerId];
      
      if (captionToEnhance == null || !captionToEnhance.isFinal) {
        _logger.w('⚠️ No final caption found to enhance', category: LogCategory.captions);
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
        
        _logger.i('✅ Caption enhanced: "$enhancedText"', category: LogCategory.captions);
      }
    } catch (e) {
      _logger.w('⚠️ Skipping enhancement due to Gemma error: $e', category: LogCategory.captions);
    }
  }

  // Removed: Event-driven retry mechanism (no longer needed)

  /// Clear all captions
  Future<void> clearAllCaptions() async {
    _logger.i('🧹 Clearing all spatial captions', category: LogCategory.captions);
    
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
    _logger.i('⏱️ Setting caption duration to: ${duration.inSeconds}s', category: LogCategory.captions);
    _spatialCaptionsCubit.setCaptionDuration(duration);
  }

  /// Enable or disable speaker diarization
  void setDiarizationEnabled(bool enabled) {
    _diarizationEnabled = enabled;
    _logger.i('🎙️ Speaker diarization ${enabled ? "enabled" : "disabled"}', category: LogCategory.captions);
  }
  
  /// Check if speaker diarization is enabled
  bool get isDiarizationEnabled => _diarizationEnabled;
  
  /// Get all tracked speakers
  List<SpeakerProfile> get speakers => _speakerDiarizationService.speakers;
  
  /// Get currently active speaker
  SpeakerProfile? get currentSpeaker => _speakerDiarizationService.currentSpeaker;
  
  /// Get speaker by ID
  SpeakerProfile? getSpeaker(String id) => _speakerDiarizationService.getSpeaker(id);
  
  /// Name a speaker for display
  void nameSpeaker(String speakerId, String name) {
    _speakerDiarizationService.nameSpeaker(speakerId, name);
  }
  
  /// Update speaker position from external source (e.g., visual tracking)
  void updateSpeakerPosition(String speakerId, Vector3 position, {double confidence = 1.0}) {
    _speakerDiarizationService.updateSpeakerPosition(speakerId, position, confidence: confidence);
  }
  
  /// Clear all speaker profiles
  void clearSpeakers() {
    _speakerDiarizationService.clearSpeakers();
  }
  
  /// Stream of speaker changes
  Stream<SpeakerIdentificationResult> get speakerChanges => _speakerDiarizationService.speakerChanges;
  
  /// Export speaker profiles for persistence
  List<Map<String, dynamic>> exportSpeakerProfiles() {
    return _speakerDiarizationService.exportProfiles();
  }
  
  /// Import speaker profiles from persistence
  void importSpeakerProfiles(List<Map<String, dynamic>> profiles) {
    _speakerDiarizationService.importProfiles(profiles);
  }
  
  /// Predict future position for a speaker (useful for smooth animation)
  Vector3? predictSpeakerPosition(String speakerId, Duration ahead) {
    final speaker = _speakerDiarizationService.getSpeaker(speakerId);
    return speaker?.predictPosition(ahead);
  }
  
  /// Dispose of resources
  void dispose() {
    // Cancel all timers
    for (final timer in _enhancementTimers.values) {
      timer.cancel();
    }
    _enhancementTimers.clear();
    if (!_directionUpdateController.isClosed) {
      _directionUpdateController.close();
    }
    _speakerDiarizationService.dispose();
  }
} 