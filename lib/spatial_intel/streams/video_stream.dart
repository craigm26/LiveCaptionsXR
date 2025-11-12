import 'dart:async';
import 'dart:typed_data';

/// Supported pixel formats for video frames.
enum VideoPixelFormat {
  rgba8888,
  bgra8888,
  yuv420,
  jpeg,
  unknown,
}

VideoPixelFormat pixelFormatFromHint(String? value) {
  switch (value?.toLowerCase()) {
    case 'rgba8888':
    case 'rgba':
      return VideoPixelFormat.rgba8888;
    case 'bgra8888':
    case 'bgra':
      return VideoPixelFormat.bgra8888;
    case 'yuv420':
    case 'yuv':
      return VideoPixelFormat.yuv420;
    case 'jpeg':
    case 'jpg':
      return VideoPixelFormat.jpeg;
    default:
      return VideoPixelFormat.unknown;
  }
}

/// Represents a captured video frame (optionally paired with depth or pose).
class VideoStreamFrame {
  VideoStreamFrame({
    required this.imageData,
    required this.width,
    required this.height,
    this.pixelFormat = VideoPixelFormat.unknown,
    DateTime? timestamp,
    this.poseMatrix,
    this.depthData,
    this.sequenceId,
  }) : timestamp = timestamp ?? DateTime.now();

  final Uint8List imageData;
  final int width;
  final int height;
  final VideoPixelFormat pixelFormat;
  final DateTime timestamp;
  final List<double>? poseMatrix; // 4x4 row-major transform
  final Float32List? depthData; // meters, same resolution as frame
  final int? sequenceId;
}

/// Broadcast hub for video frames powering multimodal captioning & metrics.
class VideoStreamBus {
  final _controller = StreamController<VideoStreamFrame>.broadcast();
  int _sequenceCounter = 0;

  Stream<VideoStreamFrame> get stream => _controller.stream;

  int publish(VideoStreamFrame frame) {
    if (_controller.isClosed) {
      return frame.sequenceId ?? -1;
    }
    final sequence = frame.sequenceId ?? _sequenceCounter++;
    _controller.add(
      VideoStreamFrame(
        imageData: frame.imageData,
        width: frame.width,
        height: frame.height,
        pixelFormat: frame.pixelFormat,
        timestamp: frame.timestamp,
        poseMatrix: frame.poseMatrix,
        depthData: frame.depthData,
        sequenceId: sequence,
      ),
    );
    return sequence;
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

