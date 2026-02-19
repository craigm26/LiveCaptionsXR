import 'dart:typed_data';

/// Abstract interface for visual frame capture.
///
/// Platform implementations provide camera or AR frame data
/// for multimodal inference (e.g., Gemma 3n vision).
abstract class VisualService {
  /// Capture a snapshot from the current visual source.
  ///
  /// Returns raw image bytes suitable for model inference,
  /// or null if capture is unavailable.
  Future<Uint8List?> captureVisualSnapshot();
}
