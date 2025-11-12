import 'dart:async';
import 'dart:math';

import 'package:live_captions_xr/core/models/speech_result.dart';
import 'package:live_captions_xr/spatial_intel/decoding/decode_policy.dart';
import 'package:live_captions_xr/spatial_intel/predict/calibrator.dart';

enum PredictiveTokenStatus { preview, committed, revoked }

class PredictiveToken {
  PredictiveToken({
    required this.value,
    required this.probability,
    required this.entropy,
    required this.status,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String value;
  final double probability;
  final double entropy;
  final PredictiveTokenStatus status;
  final DateTime timestamp;
}

class NextTokenState {
  NextTokenState({
    required this.committed,
    required this.preview,
    required this.revoked,
    required this.stableText,
    required this.previewText,
    required this.isFinal,
    required this.source,
    required this.spanProbability,
    required this.spanEntropy,
  });

  final List<PredictiveToken> committed;
  final List<PredictiveToken> preview;
  final List<PredictiveToken> revoked;
  final String stableText;
  final String previewText;
  final bool isFinal;
  final SpeechResult source;
  final double spanProbability;
  final double spanEntropy;
}

/// Streaming coordinator that derives per-token predictions from speech results.
class NextTokenStream {
  NextTokenStream({
    required DecodePolicy policy,
    required ProbabilityCalibrator calibrator,
  })  : _policy = policy,
        _calibrator = calibrator;

  final _controller = StreamController<NextTokenState>.broadcast();
  final List<String> _committedTokens = [];
  final List<String> _lastPreviewTokens = [];
  DecodePolicy _policy;
  final ProbabilityCalibrator _calibrator;
  String _stableText = '';

  Stream<NextTokenState> get stream => _controller.stream;

  void updatePolicy(DecodePolicy policy) {
    _policy = policy;
  }

  void dispose() {
    _controller.close();
  }

  void handleSpeechResult(SpeechResult result) {
    final tokens = _tokenize(result.text);
    final prefixLen = _commonPrefixLength(_committedTokens, tokens);
    final revokedTokens = <PredictiveToken>[];

    if (prefixLen < _committedTokens.length) {
      final removed = _committedTokens.sublist(prefixLen);
      for (final value in removed) {
        revokedTokens.add(
          PredictiveToken(
            value: value,
            probability: 0.0,
            entropy: 0.0,
            status: PredictiveTokenStatus.revoked,
          ),
        );
      }
      _committedTokens.removeRange(prefixLen, _committedTokens.length);
      _stableText = _reconstructText(_committedTokens);
    }

    final trailingTokens = tokens.sublist(prefixLen);
    final previewTokens = <PredictiveToken>[];
    final committedAdditions = <PredictiveToken>[];

    if (result.isFinal) {
      for (final value in trailingTokens) {
        final probability = _calibrator.calibrateProbability(0.999);
        _committedTokens.add(value);
        committedAdditions.add(
          PredictiveToken(
            value: value,
            probability: probability,
            entropy: _entropy(probability),
            status: PredictiveTokenStatus.committed,
          ),
        );
        _calibrator.trackObservation(probability, true);
      }
      _stableText = result.text;
      _lastPreviewTokens.clear();
      _emitState(
        committedAdditions: committedAdditions,
        previewTokens: const [],
        revokedTokens: revokedTokens,
        result: result,
        isFinal: true,
      );
      return;
    }

    _lastPreviewTokens
      ..clear()
      ..addAll(trailingTokens);

    double spanProbAccumulator = 0.0;
    for (final value in trailingTokens) {
      final rawProb = result.confidence.clamp(0.0, 1.0);
      final calibratedProb = _calibrator.calibrateProbability(rawProb);
      final entropy = _entropy(calibratedProb);
      final status = (calibratedProb >= _policy.tokenProbMin &&
              entropy <= _policy.entropyMax)
          ? PredictiveTokenStatus.preview
          : PredictiveTokenStatus.preview;
      previewTokens.add(
        PredictiveToken(
          value: value,
          probability: calibratedProb,
          entropy: entropy,
          status: status,
        ),
      );
      spanProbAccumulator += calibratedProb;
    }

    final spanProbability = trailingTokens.isEmpty
        ? 1.0
        : spanProbAccumulator / trailingTokens.length;
    final spanEntropy =
        trailingTokens.isEmpty ? 0.0 : _entropy(spanProbability);

    _emitState(
      committedAdditions: committedAdditions,
      previewTokens: previewTokens,
      revokedTokens: revokedTokens,
      result: result,
      isFinal: false,
      spanProbability: spanProbability,
      spanEntropy: spanEntropy,
    );
  }

  void _emitState({
    required List<PredictiveToken> committedAdditions,
    required List<PredictiveToken> previewTokens,
    required List<PredictiveToken> revokedTokens,
    required SpeechResult result,
    required bool isFinal,
    double? spanProbability,
    double? spanEntropy,
  }) {
    if (_controller.isClosed) {
      return;
    }

    final committedTokens = [
      ..._committedTokens.map(
        (value) => PredictiveToken(
          value: value,
          probability: 1.0,
          entropy: 0.0,
          status: PredictiveTokenStatus.committed,
        ),
      ),
    ];

    final state = NextTokenState(
      committed: committedTokens,
      preview: previewTokens,
      revoked: revokedTokens,
      stableText: _stableText,
      previewText: _reconstructText(_lastPreviewTokens),
      isFinal: isFinal,
      source: result,
      spanProbability: spanProbability ??
          (previewTokens.isEmpty
              ? 1.0
              : previewTokens
                      .map((token) => token.probability)
                      .reduce((a, b) => a + b) /
                  previewTokens.length),
      spanEntropy: spanEntropy ??
          (previewTokens.isEmpty
              ? 0.0
              : _entropy(previewTokens
                      .map((token) => token.probability)
                      .reduce((a, b) => a + b) /
                  previewTokens.length)),
    );
    _controller.add(state);
  }

  static List<String> _tokenize(String text) {
    final regex = RegExp(r"[^\s]+");
    return regex.allMatches(text).map((m) => m.group(0)!).toList();
  }

  static int _commonPrefixLength(List<String> a, List<String> b) {
    final minLength = min(a.length, b.length);
    for (var i = 0; i < minLength; i++) {
      if (a[i] != b[i]) {
        return i;
      }
    }
    return minLength;
  }

  static String _reconstructText(List<String> tokens) {
    if (tokens.isEmpty) {
      return '';
    }
    final buffer = StringBuffer(tokens.first);
    for (var i = 1; i < tokens.length; i++) {
      final token = tokens[i];
      if (_needsSpace(tokens[i - 1], token)) {
        buffer.write(' ');
      }
      buffer.write(token);
    }
    return buffer.toString();
  }

  static bool _needsSpace(String previous, String current) {
    const punctuation = {
      '.',
      ',',
      '!',
      '?',
      ';',
      ':',
      '"',
      '\'',
    };
    if (punctuation.contains(current)) {
      return false;
    }
    if (previous.endsWith('-')) {
      return false;
    }
    return true;
  }

  static double _entropy(double probability) {
    final p = probability.clamp(1e-6, 1 - 1e-6);
    return -p * log(p) - (1 - p) * log(1 - p);
  }
}

