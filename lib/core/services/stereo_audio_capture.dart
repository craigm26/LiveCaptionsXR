import 'dart:async';
import 'dart:typed_data';
import 'dart:math' show sqrt;
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'debug_capturing_logger.dart';

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

  static final DebugCapturingLogger _logger = DebugCapturingLogger();

  Stream<StereoAudioFrame>? _frameStream;

  /// Starts stereo audio capture on the native side.
  Future<void> startRecording() async {
    _logger.i('🎙️ Starting stereo audio capture');
    _logger.d('Configuring native audio capture system...');
    _logger.d('Target format: 16kHz, 2 channels, Float32, interleaved');

    try {
      _logger.d('Invoking native startRecording method...');
      await _methodChannel.invokeMethod<void>('startRecording');
      
      _logger.d('Setting up audio frame stream...');
      _frameStream = _eventChannel.receiveBroadcastStream().map((event) {
        _logger.d('📡 Raw event received from native: ${event.runtimeType}');
        return parseFrame(event);
      }).handleError((error, stackTrace) {
        _logger.e('❌ Error in audio frame stream processing', error: error, stackTrace: stackTrace);
      });
      
      _logger.i('✅ Stereo audio capture started successfully');
      _logger.d('Audio stream ready for frame processing');
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to start stereo audio capture', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Stops stereo audio capture.
  Future<void> stopRecording() async {
    _logger.i('⏹️ Stopping stereo audio capture');
    _logger.d('Current stream state: ${_frameStream != null ? 'active' : 'inactive'}');

    try {
      _logger.d('Invoking native stopRecording method...');
      await _methodChannel.invokeMethod<void>('stopRecording');
      
      _logger.d('Clearing audio frame stream...');
      _frameStream = null;
      
      _logger.i('✅ Stereo audio capture stopped successfully');
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to stop stereo audio capture', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Stream of captured stereo audio frames.
  Stream<StereoAudioFrame> get frames {
    _logger.d('📊 Accessing audio frames stream');
    if (_frameStream == null) {
      _logger.w('⚠️ Audio frame stream is null, returning empty stream');
      return const Stream<StereoAudioFrame>.empty();
    }
    
    // Add error handling wrapper around the stream
    return _frameStream!.handleError((error, stackTrace) {
      _logger.e('❌ Error in audio frame stream', error: error, stackTrace: stackTrace);
      // Don't rethrow to avoid breaking the stream
    });
  }

  /// Parse audio frame from native side - made public for testing
  StereoAudioFrame parseFrame(dynamic event) {
    try {
      if (event is Float32List) {
        _logger.d('📊 Processing Float32List with ${event.length} samples (${event.length / 2} per channel)');
        final left = Float32List(event.length ~/ 2);
        final right = Float32List(event.length ~/ 2);
        for (var i = 0; i < event.length; i += 2) {
          left[i ~/ 2] = event[i];
          right[i ~/ 2] = event[i + 1];
        }
        
        // Log audio level for monitoring
        double leftRms = 0.0, rightRms = 0.0;
        for (var i = 0; i < left.length; i++) {
          leftRms += left[i] * left[i];
          rightRms += right[i] * right[i];
        }
        leftRms = left.length > 0 ? sqrt(leftRms / left.length) : 0.0;
        rightRms = right.length > 0 ? sqrt(rightRms / right.length) : 0.0;
        
        _logger.d('🎧 Audio levels - Left: ${leftRms.toStringAsFixed(4)}, Right: ${rightRms.toStringAsFixed(4)}');
        
        return StereoAudioFrame(left: left, right: right);
      }
      if (event is Uint8List) {
        _logger.d('📊 Processing Uint8List with ${event.length} bytes');
        
        // Validate byte length should be multiple of 4 (Float32 size)
        if (event.length % 4 != 0) {
          _logger.e('❌ Invalid Uint8List length: ${event.length} bytes (not multiple of 4)');
          throw ArgumentError('Invalid audio data length: ${event.length} bytes');
        }
        
        // Convert bytes to Float32List
        final data = Float32List.view(event.buffer);
        _logger.d('📊 Converted to Float32List with ${data.length} samples');
        
        // Validate we have even number of samples for stereo
        if (data.length % 2 != 0) {
          _logger.e('❌ Invalid Float32List length: ${data.length} samples (not even for stereo)');
          throw ArgumentError('Invalid stereo audio data length: ${data.length} samples');
        }
        
        final left = Float32List(data.length ~/ 2);
        final right = Float32List(data.length ~/ 2);
        
        // De-interleave stereo data: [L0, R0, L1, R1, ...] -> [L0, L1, ...] and [R0, R1, ...]
        for (var i = 0; i < data.length; i += 2) {
          left[i ~/ 2] = data[i];
          right[i ~/ 2] = data[i + 1];
        }
        
        // Log audio level for monitoring (same as Float32List case)
        double leftRms = 0.0, rightRms = 0.0;
        for (var i = 0; i < left.length; i++) {
          leftRms += left[i] * left[i];
          rightRms += right[i] * right[i];
        }
        leftRms = left.length > 0 ? sqrt(leftRms / left.length) : 0.0;
        rightRms = right.length > 0 ? sqrt(rightRms / right.length) : 0.0;
        
        _logger.d('🎧 Audio levels - Left: ${leftRms.toStringAsFixed(4)}, Right: ${rightRms.toStringAsFixed(4)}');
        _logger.d('📊 Converted to ${left.length} samples per channel');
        
        return StereoAudioFrame(left: left, right: right);
      }

      _logger.e('❌ Unsupported audio frame format: ${event.runtimeType}');
      throw ArgumentError('Unsupported audio frame format: ${event.runtimeType}');
    } catch (e, stackTrace) {
      _logger.e('❌ Error parsing audio frame', error: e, stackTrace: stackTrace);
      _logger.e('📋 Event details: type=${event.runtimeType}, data=${event.toString().substring(0, 100)}...');
      rethrow;
    }
  }
}
