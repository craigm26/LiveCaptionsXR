import 'dart:typed_data';

/// Lightweight representation of a camera frame emitted by [CameraService].
///
/// The frame stores a single luminance plane (Y) which is sufficient for
/// on-device face detection, along with minimal metadata required for
/// synchronization with audio events.
class CameraFrame {
  const CameraFrame({
    required this.bytes,
    required this.width,
    required this.height,
    required this.timestamp,
    required this.exposureDurationMicros,
    required this.iso,
    this.intrinsics,
    this.projectionMatrix,
  });

  /// Raw pixel buffer in NV21/Y plane format (8-bit).
  final Uint8List bytes;

  final int width;
  final int height;

  /// Monotonic timestamp for sync with audio chunks.
  final DateTime timestamp;

  /// Exposure time in microseconds, useful for low-light heuristics.
  final int exposureDurationMicros;

  /// Sensor ISO gain reported by the camera API.
  final double iso;

  /// Optional intrinsics matrix (row-major, length 9).
  final List<double>? intrinsics;

  /// Optional projection matrix (row-major, length 16).
  final List<double>? projectionMatrix;
}
