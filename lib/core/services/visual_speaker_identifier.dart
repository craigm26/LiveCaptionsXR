import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/services.dart';

/// Model for detected speaker face info.
class SpeakerFaceInfo {
  final Rect boundingBox; // 2D screen coordinates
  final int faceIndex;    // Index of the detected face
  final double mouthMovementScore;
  // Optionally: final dynamic worldTransform; // For ARKit/ARCore 3D position

  SpeakerFaceInfo({
    required this.boundingBox,
    required this.faceIndex,
    required this.mouthMovementScore,
    // this.worldTransform,
  });
}

/// VisualSpeakerIdentifier: Face detection & speaker identification via native vision frameworks.
///
/// - Accepts camera frames from Flutter.
/// - Emits the bounding box of the active speaker's face (and optionally 3D position).
/// - Integrates with AR/caption UI for spatially-anchored captions.
class VisualSpeakerIdentifier {
  static const MethodChannel _methodChannel = MethodChannel('live_captions_xr/visual_speaker_methods');
  static const EventChannel _eventChannel = EventChannel('live_captions_xr/visual_speaker_events');

  StreamController<SpeakerFaceInfo>? _controller;
  Stream<SpeakerFaceInfo>? _activeSpeakerStream;
  StreamSubscription? _nativeSubscription;

  /// Start the vision pipeline (native side may allocate resources).
  Future<void> start() async {
    await _methodChannel.invokeMethod('start');
    _controller = StreamController<SpeakerFaceInfo>.broadcast();
    _activeSpeakerStream = _controller!.stream;
    _nativeSubscription = _eventChannel.receiveBroadcastStream().listen((event) {
      final info = _parseSpeakerFaceInfo(event);
      if (info != null) _controller?.add(info);
    });
  }

  /// Stop the vision pipeline and release resources.
  Future<void> stop() async {
    await _methodChannel.invokeMethod('stop');
    await _nativeSubscription?.cancel();
    await _controller?.close();
    _controller = null;
    _activeSpeakerStream = null;
  }

  /// Process a camera frame (optionally with speech detection signal).
  Future<void> processFrame(Uint8List image, {bool speechDetected = false}) async {
    await _methodChannel.invokeMethod('processFrame', {
      'image': image,
      'speechDetected': speechDetected,
    });
  }

  /// Stream of active speaker face info (bounding box, index, mouth movement score).
  Stream<SpeakerFaceInfo> get activeSpeakerStream => _activeSpeakerStream ?? const Stream.empty();

  /// Parse native event to SpeakerFaceInfo.
  SpeakerFaceInfo? _parseSpeakerFaceInfo(dynamic event) {
    if (event is Map) {
      final bbox = event['boundingBox'];
      if (bbox is List && bbox.length == 4) {
        return SpeakerFaceInfo(
          boundingBox: Rect.fromLTWH(
            (bbox[0] as num).toDouble(),
            (bbox[1] as num).toDouble(),
            (bbox[2] as num).toDouble(),
            (bbox[3] as num).toDouble(),
          ),
          faceIndex: (event['faceIndex'] as num?)?.toInt() ?? 0,
          mouthMovementScore: (event['mouthMovementScore'] as num?)?.toDouble() ?? 0.0,
          // worldTransform: event['worldTransform'],
        );
      }
    }
    return null;
  }
} 