import 'package:vector_math/vector_math_64.dart';

/// Lightweight alpha-beta filter approximating a Kalman anchor smoother.
class KalmanAnchor {
  KalmanAnchor({
    double processNoise = 1.0,
    double measurementNoise = 4.0,
  })  : _q = processNoise,
        _r = measurementNoise;

  final double _q;
  final double _r;

  Vector3? _position;
  Vector3 _velocity = Vector3.zero();
  double _p = 1.0;
  DateTime? _lastUpdate;

  Vector3? get position => _position;
  Vector3 get velocity => _velocity;
  double get uncertainty => _p;

  void predict(Duration delta) {
    if (_position == null || _lastUpdate == null) {
      return;
    }
    final dt = delta.inMilliseconds / 1000.0;
    if (dt <= 0) return;
    _position = _position! + (_velocity * dt);
    _p += _q;
    _lastUpdate = _lastUpdate!.add(delta);
  }

  void update(Vector3 measurement, {double confidence = 1.0}) {
    final timestamp = DateTime.now();
    if (_position == null) {
      _position = measurement.clone();
      _velocity = Vector3.zero();
      _p = _r;
      _lastUpdate = timestamp;
      return;
    }

    final dt = _lastUpdate == null
        ? 0.0
        : timestamp.difference(_lastUpdate!).inMilliseconds / 1000.0;
    if (dt > 0) {
      _position = _position! + (_velocity * dt);
      _p += _q * dt;
    }

    final kalmanGain = _p / (_p + _r / confidence.clamp(0.1, 1.0));
    final residual = measurement - _position!;
    _position = _position! + (residual * kalmanGain);
    _velocity = residual * (kalmanGain / (dt == 0 ? 1 : dt));
    _p = (1 - kalmanGain) * _p;
    _lastUpdate = timestamp;
  }

  void reset() {
    _position = null;
    _velocity = Vector3.zero();
    _p = 1.0;
    _lastUpdate = null;
  }
}

