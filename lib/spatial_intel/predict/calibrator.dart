import 'dart:math';

class CalibrationPoint {
  CalibrationPoint(this.input, this.output);

  final double input;
  final double output;
}

class CalibrationStats {
  CalibrationStats({
    required this.brierScore,
    required this.ece,
    required this.totalSamples,
  });

  final double brierScore;
  final double ece;
  final int totalSamples;
}

class _CalibrationBin {
  _CalibrationBin(this.lower, this.upper);

  final double lower;
  final double upper;
  int count = 0;
  double sumConfidence = 0.0;
  double sumOutcome = 0.0;

  void addSample(double confidence, bool outcome) {
    count += 1;
    sumConfidence += confidence;
    sumOutcome += outcome ? 1.0 : 0.0;
  }

  double get accuracy =>
      count == 0 ? 0.0 : (sumOutcome / count.toDouble()).clamp(0.0, 1.0);

  double get confidence =>
      count == 0 ? 0.0 : (sumConfidence / count.toDouble()).clamp(0.0, 1.0);
}

/// Simple probability calibrator supporting temperature scaling + isotonic fit.
class ProbabilityCalibrator {
  ProbabilityCalibrator({
    this.temperature = 1.0,
    List<CalibrationPoint>? isotonicCurve,
    int binCount = 10,
  })  : _isotonicCurve = (isotonicCurve ?? const [])
            .map((point) => CalibrationPoint(
                  point.input.clamp(0.0, 1.0),
                  point.output.clamp(0.0, 1.0),
                ))
            .toList(),
        _bins = List.generate(
          binCount,
          (index) {
            final lower = index / binCount;
            final upper = (index + 1) / binCount;
            return _CalibrationBin(lower, upper);
          },
        );

  final double temperature;
  final List<CalibrationPoint> _isotonicCurve;
  final List<_CalibrationBin> _bins;
  int _samples = 0;
  double _brierSum = 0.0;

  factory ProbabilityCalibrator.fromConfig(Map<String, dynamic> config) {
    final temperature = (config['temperature'] as num?)?.toDouble() ?? 1.0;
    final curve = ((config['isotonic'] as List?) ?? [])
        .map(
          (item) => CalibrationPoint(
            (item['input'] as num).toDouble(),
            (item['output'] as num).toDouble(),
          ),
        )
        .toList();
    final bins = (config['bins'] as num?)?.toInt() ?? 10;
    return ProbabilityCalibrator(
      temperature: temperature,
      isotonicCurve: curve,
      binCount: bins,
    );
  }

  Map<String, dynamic> toConfig() {
    return {
      'temperature': temperature,
      'isotonic': _isotonicCurve
          .map((point) => {'input': point.input, 'output': point.output})
          .toList(),
      'bins': _bins.length,
    };
  }

  double calibrateProbability(double probability) {
    final tempScaled = _applyTemperature(probability);
    return _applyIsotonic(tempScaled);
  }

  void trackObservation(double predictedProbability, bool outcome) {
    final clamped = predictedProbability.clamp(0.0, 1.0);
    _samples += 1;
    _brierSum += pow(clamped - (outcome ? 1.0 : 0.0), 2) as double;
    final binIndex = min(
      _bins.length - 1,
      (clamped * _bins.length).floor(),
    );
    _bins[binIndex].addSample(clamped, outcome);
  }

  CalibrationStats snapshot() {
    final brier = _samples == 0 ? 0.0 : _brierSum / _samples;
    double ece = 0.0;
    for (final bin in _bins) {
      if (bin.count == 0) continue;
      final weight = bin.count / _samples;
      ece += weight * (bin.confidence - bin.accuracy).abs();
    }
    return CalibrationStats(
      brierScore: brier,
      ece: ece,
      totalSamples: _samples,
    );
  }

  double _applyTemperature(double probability) {
    final clamped = probability.clamp(1e-6, 1 - 1e-6);
    final logit = log(clamped / (1 - clamped));
    final scaled = logit / temperature;
    return 1 / (1 + exp(-scaled));
  }

  double _applyIsotonic(double probability) {
    if (_isotonicCurve.isEmpty) {
      return probability.clamp(0.0, 1.0);
    }
    final sorted = List<CalibrationPoint>.from(_isotonicCurve)
      ..sort((a, b) => a.input.compareTo(b.input));
    if (probability <= sorted.first.input) {
      return sorted.first.output;
    }
    if (probability >= sorted.last.input) {
      return sorted.last.output;
    }
    for (var i = 0; i < sorted.length - 1; i++) {
      final left = sorted[i];
      final right = sorted[i + 1];
      if (probability >= left.input && probability <= right.input) {
        final range = right.input - left.input;
        if (range <= 1e-6) {
          return left.output;
        }
        final ratio = (probability - left.input) / range;
        return (left.output + ratio * (right.output - left.output))
            .clamp(0.0, 1.0);
      }
    }
    return probability.clamp(0.0, 1.0);
  }
}

