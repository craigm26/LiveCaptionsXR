import 'dart:async';

/// Represents contextual hints that bias decoding (speaker IDs, topics, etc.).
class CaptionContextFrame {
  CaptionContextFrame({
    required this.speakerId,
    required this.confidence,
    this.metadata = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Stable identifier for the current speaker (face id, diarization label).
  final String speakerId;

  /// Confidence in the speaker attribution (0‒1).
  final double confidence;

  /// Additional metadata (phrase lists, environment tags, noise profile ids).
  final Map<String, dynamic> metadata;

  final DateTime timestamp;
}

/// Broadcast hub for contextual hints referenced by predictive decoding.
class CaptionContextBus {
  final _controller = StreamController<CaptionContextFrame>.broadcast();

  Stream<CaptionContextFrame> get stream => _controller.stream;

  void publish(CaptionContextFrame frame) {
    if (!_controller.isClosed) {
      _controller.add(frame);
    }
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

