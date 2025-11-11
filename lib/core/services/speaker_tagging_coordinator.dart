import '../models/detected_speaker.dart';
import 'app_logger.dart';
import 'spatial_caption_integration_service.dart';
import 'speaker_attribution_store.dart';

/// Maintains speaker tracking state and informs the spatial caption system.
class SpeakerTaggingCoordinator {
  SpeakerTaggingCoordinator({
    required SpatialCaptionIntegrationService spatialCaptionIntegrationService,
    required SpeakerAttributionStore attributionStore,
    double speakingConfidenceThreshold = 0.55,
  })  : _spatialCaptionIntegrationService = spatialCaptionIntegrationService,
        _attributionStore = attributionStore,
        _confidenceThreshold = speakingConfidenceThreshold;

  final SpatialCaptionIntegrationService _spatialCaptionIntegrationService;
  final SpeakerAttributionStore _attributionStore;
  final double _confidenceThreshold;
  final AppLogger _logger = AppLogger.instance;

  DetectedSpeaker? _activeSpeaker;

  DetectedSpeaker? get activeSpeaker => _activeSpeaker;

  /// Updates the internal state with the latest detections and returns the
  /// speaker selected as active (if any).
  DetectedSpeaker? updateDetections(List<DetectedSpeaker> detections) {
    if (detections.isEmpty) {
      return _clearActiveSpeaker();
    }

    final nextSpeaker = _selectTopSpeaker(detections);
    if (nextSpeaker == null) {
      return _clearActiveSpeaker();
    }

    final changedFace =
        _activeSpeaker == null || nextSpeaker.faceId != _activeSpeaker!.faceId;
    _activeSpeaker = nextSpeaker;

    _spatialCaptionIntegrationService.updateActiveSpeaker(_activeSpeaker);
    _attributionStore.update(_activeSpeaker);
    if (changedFace) {
      _logger.i(
        'SpeakerTaggingCoordinator selected face ${nextSpeaker.faceId} '
        '(confidence ${nextSpeaker.confidence.toStringAsFixed(2)})',
        category: LogCategory.camera,
      );
    }
    return _activeSpeaker;
  }

  /// Clears any active speaker anchor (e.g., when service stops).
  void reset() {
    _clearActiveSpeaker();
  }

  DetectedSpeaker? _clearActiveSpeaker() {
    if (_activeSpeaker != null) {
      _logger.d(
        'SpeakerTaggingCoordinator clearing active speaker',
        category: LogCategory.camera,
      );
    }
    _activeSpeaker = null;
    _spatialCaptionIntegrationService.updateActiveSpeaker(null);
    _attributionStore.clear();
    return null;
  }

  DetectedSpeaker? _selectTopSpeaker(List<DetectedSpeaker> detections) {
    final sorted = List<DetectedSpeaker>.from(detections)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));

    final speaking = sorted
        .where((d) => d.state == SpeakerState.speaking)
        .toList(growable: false);

    final candidate = speaking.isNotEmpty ? speaking.first : sorted.first;
    if (candidate.confidence < _confidenceThreshold) {
      return null;
    }
    return candidate;
  }
}
