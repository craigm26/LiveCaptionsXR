import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

/// Represents a chunk of stereo audio sampled from the microphone.
class StereoAudioFrame {
  /// Left channel PCM samples.
  final Float32List left;

  /// Right channel PCM samples.
  final Float32List right;

  StereoAudioFrame({required this.left, required this.right});

  /// Downmixes the stereo frame to mono by averaging both channels.
  Float32List toMono() {
    final length = left.length;
    final mono = Float32List(length);
    for (var i = 0; i < length; i++) {
      mono[i] = (left[i] + right[i]) / 2.0;
    }
    return mono;
  }
}

/// Captures stereo audio from the device microphones using platform channels.
///
/// This class exposes a simple API matching the requirements from
/// `prd/01_on_device_audio_capture.md`:
///   * `startRecording()` and `stopRecording()` to control capture.
///   * A `Stream<StereoAudioFrame>` providing continuous PCM buffers.
class StereoAudioCapture {
  static const MethodChannel _methodChannel =
      MethodChannel('live_captions_xr/audio_capture_methods');
  static const EventChannel _eventChannel =
      EventChannel('live_captions_xr/audio_capture_events');

  Stream<StereoAudioFrame>? _frameStream;

  /// Starts stereo audio capture on the native side.
  Future<void> startRecording() async {
    await _methodChannel.invokeMethod<void>('startRecording');
    _frameStream =
        _eventChannel.receiveBroadcastStream().map(_parseFrame);
  }

  /// Stops stereo audio capture.
  Future<void> stopRecording() async {
    await _methodChannel.invokeMethod<void>('stopRecording');
    _frameStream = null;
  }

  /// Stream of captured stereo audio frames.
  Stream<StereoAudioFrame> get frames =>
      _frameStream ?? const Stream<StereoAudioFrame>.empty();

  StereoAudioFrame _parseFrame(dynamic event) {
    if (event is Float32List) {
      final left = Float32List(event.length ~/ 2);
      final right = Float32List(event.length ~/ 2);
      for (var i = 0; i < event.length; i += 2) {
        left[i ~/ 2] = event[i];
        right[i ~/ 2] = event[i + 1];
      }
      return StereoAudioFrame(left: left, right: right);
    }
    if (event is Uint8List) {
      final data = Float32List.view(event.buffer);
      final left = Float32List(data.length ~/ 2);
      final right = Float32List(data.length ~/ 2);
      for (var i = 0; i < data.length; i += 2) {
        left[i ~/ 2] = data[i];
        right[i ~/ 2] = data[i + 1];
      }
      return StereoAudioFrame(left: left, right: right);
    }
    throw ArgumentError('Unsupported audio frame format');
  }
}
