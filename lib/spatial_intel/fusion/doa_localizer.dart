import 'dart:async';
import 'dart:math';

import 'package:live_captions_xr/spatial_intel/streams/spatial_sensor_stream.dart';

/// Smooths raw DOA estimates using EMA and outlier rejection.
class DoaLocalizer {
  DoaLocalizer({
    required SpatialSensorBus sensorBus,
    double smoothingFactor = 0.3,
    Duration maxAge = const Duration(milliseconds: 400),
    double gateRadians = pi / 3,
  })  : _sensorBus = sensorBus,
        _smoothing = smoothingFactor.clamp(0.0, 1.0),
        _maxAge = maxAge,
        _gateRadians = gateRadians {
    _subscription = sensorBus.doaStream.listen(_handleEstimate);
  }

  final SpatialSensorBus _sensorBus;
  final double _smoothing;
  final Duration _maxAge;
  final double _gateRadians;
  StreamSubscription<DoaEstimate>? _subscription;
  DoaEstimate? _smoothed;

  DoaEstimate? get currentEstimate {
    final estimate = _smoothed;
    if (estimate == null) return null;
    final age = DateTime.now().difference(estimate.timestamp);
    if (age > _maxAge) {
      _smoothed = null;
      return null;
    }
    return estimate;
  }

  Stream<DoaEstimate> get stream async* {
    final controller = StreamController<DoaEstimate>();
    final subscription = _sensorBus.doaStream.listen(controller.add);
    yield* controller.stream;
    await subscription.cancel();
    await controller.close();
  }

  void _handleEstimate(DoaEstimate estimate) {
    final current = _smoothed;
    if (current == null) {
      _smoothed = estimate;
      return;
    }

    final delta =
        _angularDistance(current.azimuth, estimate.azimuth).abs();
    if (delta > _gateRadians) {
      // Hard jump – accept only if confidence significantly higher.
      if (estimate.confidence > current.confidence + 0.2) {
        _smoothed = estimate;
      }
      return;
    }

    final alpha = _smoothing;
    final blendedAzimuth = _wrapRadians(
      (1 - alpha) * current.azimuth + alpha * estimate.azimuth,
    );
    final blendedElevation =
        (1 - alpha) * current.elevation + alpha * estimate.elevation;
    final blendedConfidence = max(
      current.confidence * 0.95,
      estimate.confidence,
    );
    _smoothed = DoaEstimate(
      azimuth: blendedAzimuth,
      elevation: blendedElevation,
      confidence: blendedConfidence,
      timestamp: estimate.timestamp,
    );
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _smoothed = null;
  }

  static double _wrapRadians(double value) {
    var v = value;
    while (v <= -pi) v += 2 * pi;
    while (v > pi) v -= 2 * pi;
    return v;
  }

  static double _angularDistance(double a, double b) {
    final diff = _wrapRadians(a - b);
    return diff;
  }
}

