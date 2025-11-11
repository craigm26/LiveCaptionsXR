import 'dart:async';

import '../models/detected_speaker.dart';

/// Holds the freshest visual speaker attribution so other services can query it.
class SpeakerAttributionStore {
  SpeakerAttributionStore({Duration freshness = const Duration(milliseconds: 600)})
      : _freshness = freshness;

  final Duration _freshness;
  DetectedSpeaker? _activeSpeaker;
  DateTime? _lastUpdatedAt;

  final StreamController<DetectedSpeaker?> _controller =
      StreamController<DetectedSpeaker?>.broadcast();

  Stream<DetectedSpeaker?> get changes => _controller.stream;

  DetectedSpeaker? get activeSpeaker {
    if (_activeSpeaker == null || _lastUpdatedAt == null) {
      return null;
    }
    if (DateTime.now().difference(_lastUpdatedAt!) > _freshness) {
      return null;
    }
    return _activeSpeaker;
  }

  void update(DetectedSpeaker? speaker) {
    _activeSpeaker = speaker;
    _lastUpdatedAt = speaker == null ? null : DateTime.now();
    if (!_controller.isClosed) {
      _controller.add(_activeSpeaker);
    }
  }

  void clear() => update(null);

  void dispose() {
    _controller.close();
  }
}
