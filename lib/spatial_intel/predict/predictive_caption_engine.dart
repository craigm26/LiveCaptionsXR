import 'dart:async';

import 'package:live_captions_xr/core/models/speech_result.dart';
import 'package:live_captions_xr/spatial_intel/decoding/decode_policy.dart';
import 'package:live_captions_xr/spatial_intel/predict/calibrator.dart';
import 'package:live_captions_xr/spatial_intel/predict/next_token_stream.dart';

/// High-level coordinator for predictive captioning.
class PredictiveCaptionEngine {
  PredictiveCaptionEngine({
    DecodePolicy? initialPolicy,
    ProbabilityCalibrator? calibrator,
    DecodePolicyLoader? loader,
  })  : _policy = initialPolicy ?? DecodePolicy.defaultPolicy(),
        _loader = loader ?? DecodePolicyLoader(),
        _calibrator = calibrator ?? ProbabilityCalibrator(temperature: 1.2) {
    _nextTokenStream = NextTokenStream(
      policy: _policy,
      calibrator: _calibrator,
    );
  }

  late final NextTokenStream _nextTokenStream;
  final ProbabilityCalibrator _calibrator;
  final DecodePolicyLoader _loader;
  DecodePolicy _policy;
  bool _initialized = false;

  Stream<NextTokenState> get nextTokenStates => _nextTokenStream.stream;
  DecodePolicy get policy => _policy;
  ProbabilityCalibrator get calibrator => _calibrator;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _policy = await _loader.load();
      _nextTokenStream.updatePolicy(_policy);
    } finally {
      _initialized = true;
    }
  }

  Future<void> reloadPolicy() async {
    _loader.invalidateCache();
    _policy = await _loader.load();
    _nextTokenStream.updatePolicy(_policy);
  }

  void updatePolicy(DecodePolicy policy) {
    _policy = policy;
    _nextTokenStream.updatePolicy(policy);
  }

  void handleSpeechResult(SpeechResult result) {
    if (!_initialized) {
      // Attempt lazy init to avoid awaiting in hot path.
      initialize();
    }
    _nextTokenStream.handleSpeechResult(result);
  }

  CalibrationStats getCalibrationSnapshot() => _calibrator.snapshot();

  void dispose() {
    _nextTokenStream.dispose();
  }
}

