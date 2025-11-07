import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'app_logger.dart';

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

  static final AppLogger _logger = AppLogger.instance;

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
      
      // First, test if we can receive raw events
      _logger.d('🔍 Testing raw EventChannel stream...');
      final rawStream = _eventChannel.receiveBroadcastStream();
      
      _frameStream = rawStream.map((event) {
        _logger.d('📡 Raw event received from native: ${event.runtimeType}');
        try {
          final frame = parseFrame(event);
          _logger.d('✅ Successfully parsed audio frame');
          return frame;
        } catch (e, stackTrace) {
          _logger.e('❌ Failed to parse audio frame', error: e, stackTrace: stackTrace);
          rethrow;
        }
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
  
  /// Test method to check if events are flowing from native side
  Future<void> testEventFlow() async {
    _logger.i('🧪 Testing event flow from native EventChannel...');
    
    try {
      final rawStream = _eventChannel.receiveBroadcastStream();
      int eventCount = 0;
      
      final subscription = rawStream.listen((event) {
        eventCount++;
        _logger.d('🧪 Test event #$eventCount: ${event.runtimeType}');
        
        if (event is Uint8List) {
          _logger.d('🧪 Uint8List length: ${event.length}');
        }
        
        if (eventCount >= 5) {
          _logger.i('🧪 Received 5 test events, stopping test');
        }
      }, onError: (error) {
        _logger.e('🧪 Test event error: $error');
      });
      
      // Listen for 2 seconds then cancel
      await Future.delayed(const Duration(seconds: 2));
      await subscription.cancel();
      
      _logger.i('🧪 Test completed: received $eventCount events');
    } catch (e, stackTrace) {
      _logger.e('🧪 Test event flow failed', error: e, stackTrace: stackTrace);
    }
  }

  /// Parse audio frame from native side - made public for testing
  StereoAudioFrame parseFrame(dynamic event) {
    try {
      _logger.d('🔍 Parsing audio frame: type=${event.runtimeType}');
      
      if (event is Float32List) {
        final originalSamples = event.length;
        final usableSamples = originalSamples - (originalSamples % 2);

        if (usableSamples < originalSamples) {
          _logger.w('⚠️ Trimmed an odd sample from Float32List before deinterleaving '
              '($originalSamples -> $usableSamples samples)');
        }

        if (usableSamples < 2) {
          _logger.e('❌ Insufficient samples after trimming: $usableSamples samples');
          throw ArgumentError('Not enough audio samples');
        }

        _logger.d('📊 Processing Float32List with $usableSamples samples (${usableSamples / 2} per channel)');
        final left = Float32List(usableSamples ~/ 2);
        final right = Float32List(usableSamples ~/ 2);

        for (var i = 0; i < usableSamples; i += 2) {
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
        _logger.d('📊 First 16 bytes: ${event.take(16).toList()}');

        const floatBytes = Float32List.bytesPerElement;
        final usableBytes = event.length - (event.length % floatBytes);

        if (usableBytes != event.length) {
          _logger.w('⚠️ Dropped ${event.length - usableBytes} trailing byte(s) to align with Float32 samples');
        }

        final rawSampleCount = usableBytes ~/ floatBytes;
        if (rawSampleCount == 0) {
          _logger.e('❌ Audio frame contains no Float32 samples');
          throw ArgumentError('Invalid audio data length: ${event.length} bytes');
        }

        final usableSamples = rawSampleCount - (rawSampleCount % 2);
        if (usableSamples == 0) {
          _logger.e('❌ Audio frame too short after ensuring even stereo samples');
          throw ArgumentError('Not enough stereo samples: $rawSampleCount samples');
        }

        if (usableSamples != rawSampleCount) {
          _logger.w('⚠️ Trimmed odd sample from Uint8List (${rawSampleCount} -> $usableSamples samples)');
        }

        final data = Float32List.view(
          event.buffer,
          event.offsetInBytes,
          usableSamples,
        );
        _logger.d('📊 Converted to Float32List with ${data.length} samples');
        _logger.d('📊 First 8 float values: ${data.take(8).toList()}');

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
      _logger.e('📋 Event details: type=${event.runtimeType}');
      if (event is Uint8List) {
        _logger.e('📋 Uint8List length: ${event.length}');
        _logger.e('📋 First 16 bytes: ${event.take(16).toList()}');
      }
      rethrow;
    }
  }
}
