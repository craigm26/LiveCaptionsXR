import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

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

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  Stream<StereoAudioFrame>? _frameStream;

  /// Starts stereo audio capture on the native side.
  Future<void> startRecording() async {
    _logger.i('🎙️ Starting stereo audio capture');

    try {
      await _methodChannel.invokeMethod<void>('startRecording');
      _frameStream = _eventChannel.receiveBroadcastStream().map(_parseFrame);
      _logger.i('✅ Stereo audio capture started successfully');
    } catch (e) {
      _logger.e('❌ Failed to start stereo audio capture: $e');
      rethrow;
    }
  }

  /// Stops stereo audio capture.
  Future<void> stopRecording() async {
    _logger.i('⏹️ Stopping stereo audio capture');

    try {
      await _methodChannel.invokeMethod<void>('stopRecording');
      _frameStream = null;
      _logger.i('✅ Stereo audio capture stopped successfully');
    } catch (e) {
      _logger.e('❌ Failed to stop stereo audio capture: $e');
      rethrow;
    }
  }

  /// Stream of captured stereo audio frames.
  Stream<StereoAudioFrame> get frames {
    _logger.d('📊 Accessing audio frames stream');
    return _frameStream ?? const Stream<StereoAudioFrame>.empty();
  }

  StereoAudioFrame _parseFrame(dynamic event) {
    _logger.d('🔍 Parsing audio frame: ${event.runtimeType}');

    if (event is Float32List) {
      _logger.d('📊 Processing Float32List with ${event.length} samples');
      final left = Float32List(event.length ~/ 2);
      final right = Float32List(event.length ~/ 2);
      for (var i = 0; i < event.length; i += 2) {
        left[i ~/ 2] = event[i];
        right[i ~/ 2] = event[i + 1];
      }
      return StereoAudioFrame(left: left, right: right);
    }
    if (event is Uint8List) {
      _logger.d('📊 Processing Uint8List with ${event.length} bytes');
      final data = Float32List.view(event.buffer);
      final left = Float32List(data.length ~/ 2);
      final right = Float32List(data.length ~/ 2);
      for (var i = 0; i < data.length; i += 2) {
        left[i ~/ 2] = data[i];
        right[i ~/ 2] = data[i + 1];
      }
      return StereoAudioFrame(left: left, right: right);
    }

    _logger.e('❌ Unsupported audio frame format: ${event.runtimeType}');
    throw ArgumentError('Unsupported audio frame format');
  }
}
