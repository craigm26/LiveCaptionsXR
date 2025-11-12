import 'dart:async';
import 'dart:math';

/// Represents a fused direction-of-arrival estimate from the mic array.
class DoaEstimate {
  DoaEstimate({
    required double azimuth,
    required double elevation,
    required this.confidence,
    DateTime? timestamp,
  })  : azimuth = _normalizeRadians(azimuth),
        elevation = elevation.clamp(-pi / 2, pi / 2).toDouble(),
        timestamp = timestamp ?? DateTime.now();

  final double azimuth;
  final double elevation;
  final double confidence;
  final DateTime timestamp;

  static double _normalizeRadians(double value) {
    var v = value;
    while (v <= -pi) {
      v += 2 * pi;
    }
    while (v > pi) {
      v -= 2 * pi;
    }
    return v;
  }
}

/// Simple IMU reading (device-centric).
class ImuSample {
  ImuSample({
    required this.gyroscope,
    required this.accelerometer,
    required this.gravity,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final List<double> gyroscope; // rad/s (x,y,z)
  final List<double> accelerometer; // m/s^2 (x,y,z)
  final List<double> gravity; // normalized vector
  final DateTime timestamp;
}

/// Represents a head/eye-gaze ray in camera space.
class GazeSample {
  GazeSample({
    required this.origin,
    required this.direction,
    required this.confidence,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final List<double> origin; // meters (x,y,z)
  final List<double> direction; // normalized (x,y,z)
  final double confidence;
  final DateTime timestamp;
}

class SpatialSensorBus {
  final _doaController = StreamController<DoaEstimate>.broadcast();
  final _imuController = StreamController<ImuSample>.broadcast();
  final _gazeController = StreamController<GazeSample>.broadcast();

  Stream<DoaEstimate> get doaStream => _doaController.stream;
  Stream<ImuSample> get imuStream => _imuController.stream;
  Stream<GazeSample> get gazeStream => _gazeController.stream;

  void publishDoa(DoaEstimate estimate) {
    if (!_doaController.isClosed) {
      _doaController.add(estimate);
    }
  }

  void publishImu(ImuSample sample) {
    if (!_imuController.isClosed) {
      _imuController.add(sample);
    }
  }

  void publishGaze(GazeSample sample) {
    if (!_gazeController.isClosed) {
      _gazeController.add(sample);
    }
  }

  Future<void> dispose() async {
    await Future.wait([
      _doaController.close(),
      _imuController.close(),
      _gazeController.close(),
    ]);
  }
}

