import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

/// Represents a time-aligned chunk of mono audio samples captured at 16 kHz.
///
/// Consumers (predictive decoder, calibration, benchmarking) use this to drive
/// deterministic token updates and latency tracking. The structure keeps both
/// the original floating-point samples (normalized -1.0‒1.0) and a lazily
/// computed PCM16 view when downstream code needs raw bytes.
class AudioStreamFrame {
  AudioStreamFrame({
    required this.samples,
    required this.sampleRate,
    required this.hop,
    DateTime? timestamp,
    this.sequenceId,
  })  : timestamp = timestamp ?? DateTime.now(),
        rms = _computeRms(samples),
        peak = _computePeak(samples);

  /// Normalized mono samples.
  final Float32List samples;

  /// Samples per second (defaults to 16 kHz in current pipeline).
  final int sampleRate;

  /// Hop size between frames (e.g., 20‒40 ms).
  final Duration hop;

  /// Capture timestamp aligned to the end of the frame.
  final DateTime timestamp;

  /// Optional monotonically increasing sequence id from the capture source.
  final int? sequenceId;

  /// Root-mean-square amplitude – useful for VAD heuristics.
  final double rms;

  /// Peak amplitude in the frame.
  final double peak;

  Uint8List? _pcmCache;

  /// Retrieve the frame as PCM16 (little-endian). Lazily materialized.
  Uint8List asPcm16() {
    final cached = _pcmCache;
    if (cached != null) {
      return cached;
    }
    final buffer = Uint8List(samples.length * 2);
    final byteData = ByteData.view(buffer.buffer);
    for (var i = 0; i < samples.length; i++) {
      final clamped = samples[i].clamp(-1.0, 1.0);
      final s = (clamped * 32767.0).round().clamp(-32768, 32767);
      byteData.setInt16(i * 2, s, Endian.little);
    }
    _pcmCache = buffer;
    return buffer;
  }

  static double _computeRms(Float32List samples) {
    if (samples.isEmpty) {
      return 0;
    }
    var sum = 0.0;
    for (final sample in samples) {
      sum += sample * sample;
    }
    return sqrt(sum / samples.length);
  }

  static double _computePeak(Float32List samples) {
    var peak = 0.0;
    for (final sample in samples) {
      final abs = sample.abs();
      if (abs > peak) {
        peak = abs;
      }
    }
    return peak;
  }
}

/// Broadcast hub for audio frames consumed by predictive decoding and metrics.
///
/// `AudioStreamBus` intentionally avoids directly depending on Flutter layers
/// to keep the API simple for unit tests and benchmarking harnesses.
class AudioStreamBus {
  final _controller = StreamController<AudioStreamFrame>.broadcast();
  int _sequenceCounter = 0;

  /// Stream of frames in capture order.
  Stream<AudioStreamFrame> get stream => _controller.stream;

  /// Publish a new frame and return the assigned sequence id.
  int publish(AudioStreamFrame frame) {
    if (_controller.isClosed) {
      return frame.sequenceId ?? -1;
    }
    final sequence =
        frame.sequenceId ?? _sequenceCounter++; // assign if missing
    _controller.add(
      AudioStreamFrame(
        samples: frame.samples,
        sampleRate: frame.sampleRate,
        hop: frame.hop,
        timestamp: frame.timestamp,
        sequenceId: sequence,
      ),
    );
    return sequence;
  }

  /// Convenience helper for List<double> samples produced by existing capture.
  int publishFloatSamples({
    required List<double> samples,
    required int sampleRate,
    required Duration hop,
    DateTime? timestamp,
  }) {
    return publish(
      AudioStreamFrame(
        samples: Float32List.fromList(samples.map((s) {
          if (s > 1.0) return 1.0;
          if (s < -1.0) return -1.0;
          return s.toDouble();
        }).toList()),
        sampleRate: sampleRate,
        hop: hop,
        timestamp: timestamp,
      ),
    );
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

