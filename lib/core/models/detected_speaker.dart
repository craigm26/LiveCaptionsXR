import 'dart:ui';

/// Represents a tracked face and its inferred speaking state.
class DetectedSpeaker {
  const DetectedSpeaker({
    required this.faceId,
    required this.boundingBox,
    required this.timestamp,
    required this.confidence,
    this.state = SpeakerState.unknown,
    this.landmarks,
    this.worldTransform,
  });

  /// Stable identifier for the tracked face.
  final int faceId;

  /// Axis-aligned bounding box in normalized viewport coordinates.
  final Rect boundingBox;

  /// Optional lip/nose/eye landmarks also normalized to the viewport.
  final List<Offset>? landmarks;

  /// UTC timestamp when the detection was produced.
  final DateTime timestamp;

  /// Confidence (0-1) that the track matches the active speaker.
  final double confidence;

  /// Optional 4x4 transform (row-major) for spatial anchoring.
  final List<double>? worldTransform;

  final SpeakerState state;

  DetectedSpeaker copyWith({
    Rect? boundingBox,
    List<Offset>? landmarks,
    DateTime? timestamp,
    double? confidence,
    List<double>? worldTransform,
    SpeakerState? state,
  }) {
    return DetectedSpeaker(
      faceId: faceId,
      boundingBox: boundingBox ?? this.boundingBox,
      landmarks: landmarks ?? this.landmarks,
      timestamp: timestamp ?? this.timestamp,
      confidence: confidence ?? this.confidence,
      worldTransform: worldTransform ?? this.worldTransform,
      state: state ?? this.state,
    );
  }
}

enum SpeakerState {
  unknown,
  silent,
  speaking,
}
