import 'dart:math';

class TokenLifecycle {
  TokenLifecycle({
    required this.partialLatency,
    required this.commitLatency,
    required this.changedAfterDisplay,
  });

  final Duration partialLatency;
  final Duration commitLatency;
  final bool changedAfterDisplay;
}

class PredictionRecord {
  PredictionRecord({
    required this.probability,
    required this.outcome,
  });

  final double probability;
  final bool outcome;
}

class SpatialRecord {
  SpatialRecord({
    required this.angularErrorDeg,
    required this.anchorJitterDps,
    required this.occlusionRate,
  });

  final double angularErrorDeg;
  final double anchorJitterDps;
  final double occlusionRate;
}

class PerformanceRecord {
  PerformanceRecord({
    required this.cpuPercent,
    required this.gpuPercent,
    required this.memoryMb,
    required this.deviceTempC,
    required this.batteryMw,
  });

  final double cpuPercent;
  final double gpuPercent;
  final double memoryMb;
  final double deviceTempC;
  final double batteryMw;
}

class MetricsAggregator {
  final List<TokenLifecycle> _lifecycles = [];
  final List<PredictionRecord> _predictions = [];
  final List<SpatialRecord> _spatial = [];
  final List<PerformanceRecord> _performance = [];

  DateTime? _firstPartialAt;

  void recordTokenLifecycle(TokenLifecycle lifecycle) {
    _lifecycles.add(lifecycle);
    _firstPartialAt ??= DateTime.now();
  }

  void recordPrediction(PredictionRecord record) {
    _predictions.add(record);
  }

  void recordSpatial(SpatialRecord record) {
    _spatial.add(record);
  }

  void recordPerformance(PerformanceRecord record) {
    _performance.add(record);
  }

  Map<String, dynamic> summary() {
    return {
      'latency': _latencySummary(),
      'calibration': _calibrationSummary(),
      'spatial': _spatialSummary(),
      'performance': _performanceSummary(),
    };
  }

  Map<String, dynamic> _latencySummary() {
    if (_lifecycles.isEmpty) {
      return {
        'ttf_ms': 0,
        'ttc_ms_mean': 0,
        'ttc_ms_p95': 0,
        'edit_flicker_rate': 0,
      };
    }
    final ttf = _lifecycles.first.partialLatency.inMilliseconds;
    final commitLatencies =
        _lifecycles.map((l) => l.commitLatency.inMilliseconds).toList();
    commitLatencies.sort();
    final p95 = commitLatencies[
        (commitLatencies.length * 0.95).clamp(0, commitLatencies.length - 1)
            .toInt()];
    final mean = commitLatencies.reduce((a, b) => a + b) /
        commitLatencies.length;
    final flickerRate = _lifecycles
            .where((l) => l.changedAfterDisplay)
            .length /
        _lifecycles.length;
    return {
      'ttf_ms': ttf,
      'ttc_ms_mean': mean,
      'ttc_ms_p95': p95,
      'edit_flicker_rate': flickerRate,
    };
  }

  Map<String, dynamic> _calibrationSummary() {
    if (_predictions.isEmpty) {
      return {'brier': 0, 'ece': 0, 'samples': 0};
    }
    double brier = 0;
    final bins = List.generate(10, (index) => _CalibrationBin(index / 10, (index + 1) / 10));
    for (final record in _predictions) {
      final prob = record.probability.clamp(0.0, 1.0);
      brier += pow(prob - (record.outcome ? 1.0 : 0.0), 2) as double;
      final idx = min(bins.length - 1, (prob * bins.length).floor());
      bins[idx].add(prob, record.outcome);
    }
    final ece = bins
        .where((bin) => bin.count > 0)
        .fold<double>(0.0, (sum, bin) => sum + bin.weightedGap(_predictions.length));
    return {
      'brier': brier / _predictions.length,
      'ece': ece,
      'samples': _predictions.length,
    };
  }

  Map<String, dynamic> _spatialSummary() {
    if (_spatial.isEmpty) {
      return {
        'angular_error_mean_deg': 0,
        'anchor_jitter_mean_dps': 0,
        'occlusion_rate_mean_pct': 0,
      };
    }
    final angularMean = _spatial
            .map((s) => s.angularErrorDeg)
            .reduce((a, b) => a + b) /
        _spatial.length;
    final jitterMean = _spatial
            .map((s) => s.anchorJitterDps)
            .reduce((a, b) => a + b) /
        _spatial.length;
    final occlusionMean = _spatial
            .map((s) => s.occlusionRate)
            .reduce((a, b) => a + b) /
        _spatial.length;
    return {
      'angular_error_mean_deg': angularMean,
      'anchor_jitter_mean_dps': jitterMean,
      'occlusion_rate_mean_pct': occlusionMean,
    };
  }

  Map<String, dynamic> _performanceSummary() {
    if (_performance.isEmpty) {
      return {};
    }
    double avgCpu = 0, avgGpu = 0, avgMem = 0, avgTemp = 0, avgBattery = 0;
    for (final record in _performance) {
      avgCpu += record.cpuPercent;
      avgGpu += record.gpuPercent;
      avgMem += record.memoryMb;
      avgTemp += record.deviceTempC;
      avgBattery += record.batteryMw;
    }
    final count = _performance.length.toDouble();
    return {
      'cpu_percent_mean': avgCpu / count,
      'gpu_percent_mean': avgGpu / count,
      'memory_mb_mean': avgMem / count,
      'device_temp_c_mean': avgTemp / count,
      'battery_mw_mean': avgBattery / count,
    };
  }
}

class _CalibrationBin {
  _CalibrationBin(this.lower, this.upper);

  final double lower;
  final double upper;
  int count = 0;
  double confidenceSum = 0;
  double outcomeSum = 0;

  void add(double confidence, bool outcome) {
    count += 1;
    confidenceSum += confidence;
    outcomeSum += outcome ? 1.0 : 0.0;
  }

  double get meanConfidence =>
      count == 0 ? 0.0 : confidenceSum / count.toDouble();
  double get accuracy => count == 0 ? 0.0 : outcomeSum / count.toDouble();

  double weightedGap(int totalSamples) {
    if (count == 0 || totalSamples == 0) return 0.0;
    final weight = count / totalSamples;
    return weight * (meanConfidence - accuracy).abs();
  }
}

