import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';

import '../utils/logger.dart';

/// Represents the location and state of an identified speaker.
class SpeakerInfo {
  /// The bounding box of the speaker's face in screen coordinates.
  final Rect boundingBox;

  /// A confidence score indicating how likely this person is the speaker.
  final double confidence;

  SpeakerInfo({required this.boundingBox, required this.confidence});
}

/// A service for visual speaker identification using the device's camera.
///
/// Implements the API defined in `prd/06_face_detection_speaker_identification.md`.
/// This service interfaces with native code (Swift/Vision) to perform
/// real-time face detection and mouth movement analysis to identify the
/// active speaker in the camera feed.
class VisualService {
  static const _channel = MethodChannel('com.craig.livecaptions/visual');

  final _speakerController = StreamController<SpeakerInfo?>.broadcast();
  bool _isDetecting = false;

  /// A stream of [SpeakerInfo] objects.
  ///
  /// Emits a [SpeakerInfo] object when an active speaker is identified.
  /// Emits `null` when no speaker is detected.
  Stream<SpeakerInfo?> get speakerStream => _speakerController.stream;

  VisualService() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  /// Starts the visual speaker detection process.
  ///
  /// This will activate the camera and begin the native vision processing.
  Future<void> startDetection() async {
    if (_isDetecting) return;
    try {
      await _channel.invokeMethod('startDetection');
      _isDetecting = true;
      log('👁️ Visual speaker detection started.');
    } on PlatformException catch (e) {
      log('❌ Failed to start visual detection: ${e.message}');
    }
  }

  /// Stops the visual speaker detection process.
  ///
  /// This will release the camera and stop the native vision processing.
  Future<void> stopDetection() async {
    if (!_isDetecting) return;
    try {
      await _channel.invokeMethod('stopDetection');
      _isDetecting = false;
      log('👁️ Visual speaker detection stopped.');
    } on PlatformException catch (e) {
      log('❌ Failed to stop visual detection: ${e.message}');
    }
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onSpeakerUpdated':
        final data = call.arguments as Map<dynamic, dynamic>?;
        if (data != null) {
          final box = Rect.fromLTWH(
            data['x'],
            data['y'],
            data['width'],
            data['height'],
          );
          final confidence = data['confidence'] as double;
          _speakerController.add(SpeakerInfo(boundingBox: box, confidence: confidence));
        } else {
          _speakerController.add(null);
        }
        break;
      default:
        log('Unknown method call from native: ${call.method}');
    }
  }

  void dispose() {
    _speakerController.close();
  }
}
