// import 'dart:ffi'; // Not available on web
import 'dart:math';
import 'dart:typed_data';
import 'stereo_audio_capture.dart';
import 'app_logger.dart';

/// Simple Complex number class for FFT calculations
class Complex {
  final double real;
  final double imag;
  
  Complex(this.real, this.imag);
  
  Complex operator *(Complex other) => Complex(
    real * other.real - imag * other.imag,
    real * other.imag + imag * other.real,
  );
  
  Complex operator +(Complex other) => Complex(real + other.real, imag + other.imag);
  Complex operator -(Complex other) => Complex(real - other.real, imag - other.imag);
  Complex operator /(double scalar) => Complex(real / scalar, imag / scalar);
  
  Complex conjugate() => Complex(real, -imag);
  double abs() => sqrt(real * real + imag * imag);
}

/// Simple Complex number class for FFT calculations
class Complex {
  final double real;
  final double imag;
  
  Complex(this.real, this.imag);
  
  Complex operator *(Complex other) => Complex(
    real * other.real - imag * other.imag,
    real * other.imag + imag * other.real,
  );
  
  Complex operator +(Complex other) => Complex(real + other.real, imag + other.imag);
  Complex operator -(Complex other) => Complex(real - other.real, imag - other.imag);
  Complex operator /(double scalar) => Complex(real / scalar, imag / scalar);
  
  Complex conjugate() => Complex(real, -imag);
  double abs() => sqrt(real * real + imag * imag);
}

/// Basic audio direction estimation using RMS amplitude comparison.
///
/// This implements the algorithm described in `prd/02_basic_audio_direction_estimation.md`.
/// It calculates the root mean square (RMS) value of the left and right channels
/// of a [StereoAudioFrame] and converts the normalized difference into a
/// horizontal angle in radians (negative = left, positive = right).
class SpeechLocalizer {
  static final AppLogger _logger = AppLogger.instance;
  
  /// Minimum RMS to consider a frame as valid speech (tune as needed)
  final double minRmsThreshold;
  /// Smoothing factor for exponential moving average (0 = no smoothing, 1 = max smoothing)
  final double smoothing;

  double _lastAngle = 0.0;

  SpeechLocalizer({this.minRmsThreshold = 0.01, this.smoothing = 0.2}) {
    _logger.i('🏗️ Initializing SpeechLocalizer...');
    _logger.d('RMS threshold: $minRmsThreshold, Smoothing: $smoothing');
  }

  // static const MethodChannel _channel =
  //     MethodChannel('live_captions_xr/speech_localizer');

  // /// Basic amplitude-based direction estimation (native).
  // static Future<double> estimateDirectionNative({
  //   required Float32List left,
  //   required Float32List right,
  //   double sampleRate = 16000.0,
  // }) async {
  //   final result = await _channel.invokeMethod<double>(
  //     'estimateDirection',
  //     {
  //       'left': left,
  //       'right': right,
  //       'sampleRate': sampleRate,
  //     },
  //   );
  //   if (result == null) throw Exception('No result from native code');
  //   return result;
  // }

  

  /// Estimate horizontal angle from a stereo audio frame.
  ///
  /// Returns an angle in radians between `-pi/2` (full left) and `pi/2` (full right).
  double estimateDirection(StereoAudioFrame frame) {
    final leftRms = _rms(frame.left);
    final rightRms = _rms(frame.right);
    final sum = leftRms + rightRms;
    if (sum < minRmsThreshold) {
      // Too quiet, treat as center or hold last value
      return _lastAngle;
    }
    final diff = leftRms - rightRms;
    final normalized = (diff / sum).clamp(-1.0, 1.0);
    final angle = normalized * (pi / 2);

    // Exponential moving average smoothing
    _lastAngle = smoothing * _lastAngle + (1 - smoothing) * angle;
    return _lastAngle;
  }

  /// Estimate horizontal angle using GCC-PHAT Time Difference of Arrival.
  ///
  /// [sampleRate] is the sampling rate of the audio buffers and
  /// [micDistance] is the spacing between device microphones in meters.
  double estimateDirectionAdvanced(
    StereoAudioFrame frame, {
    double sampleRate = 48000,
    double micDistance = 0.08,
    double soundSpeed = 343.0,
  }) {
    try {
      final left = frame.left;
      final right = frame.right;
      
      // Ensure both channels have the same length
      final length = left.length;
      if (right.length != length) {
        _logger.w('⚠️ Channel length mismatch, using basic estimation');
        return estimateDirection(frame);
      }
      
      // Apply window function to reduce spectral leakage
      final windowedLeft = _applyHannWindow(left);
      final windowedRight = _applyHannWindow(right);
      
      // Compute FFT
      final fftSize = _nextPowerOf2(length);
      final leftFFT = _computeFFT(windowedLeft, fftSize);
      final rightFFT = _computeFFT(windowedRight, fftSize);
      
      // Compute cross-power spectral density
      final crossPower = _computeCrossPower(leftFFT, rightFFT);
      
      // Apply GCC-PHAT weighting
      final gccPhat = _applyGccPhatWeighting(crossPower);
      
      // Compute inverse FFT to get cross-correlation
      final crossCorrelation = _computeInverseFFT(gccPhat);
      
      // Find the peak of cross-correlation
      final peakIndex = _findPeakIndex(crossCorrelation);
      
      // Convert peak index to time delay
      final timeDelay = _indexToTimeDelay(peakIndex, fftSize, sampleRate);
      
      // Convert time delay to angle
      final angle = _timeDelayToAngle(timeDelay, micDistance, soundSpeed);
      
      _logger.d('🔊 GCC-PHAT: delay=${timeDelay.toStringAsFixed(6)}s, angle=${angle.toStringAsFixed(3)}rad');
      
      return angle;
    } catch (e) {
      _logger.w('⚠️ GCC-PHAT failed, falling back to basic estimation: $e');
      return estimateDirection(frame);
    }
  }

  /// Apply Hann window to reduce spectral leakage
  Float32List _applyHannWindow(Float32List data) {
    final windowed = Float32List(data.length);
    for (int i = 0; i < data.length; i++) {
      final window = 0.5 * (1 - cos(2 * pi * i / (data.length - 1)));
      windowed[i] = data[i] * window;
    }
    return windowed;
  }

  /// Find next power of 2 for FFT
  int _nextPowerOf2(int n) {
    int power = 1;
    while (power < n) power *= 2;
    return power;
  }

  /// Simple FFT implementation (for real input)
  List<Complex> _computeFFT(Float32List data, int fftSize) {
    // Pad with zeros if needed
    final padded = Float32List(fftSize);
    for (int i = 0; i < data.length; i++) {
      padded[i] = data[i];
    }
    
    // Convert to complex numbers
    final complex = List<Complex>.generate(fftSize, (i) => Complex(padded[i], 0));
    
    // Apply FFT (simplified implementation)
    return _fft(complex);
  }

  /// Simple FFT implementation
  List<Complex> _fft(List<Complex> data) {
    final n = data.length;
    if (n <= 1) return data;
    
    // Split into even and odd indices
    final even = <Complex>[];
    final odd = <Complex>[];
    for (int i = 0; i < n; i++) {
      if (i % 2 == 0) {
        even.add(data[i]);
      } else {
        odd.add(data[i]);
      }
    }
    
    // Recursive FFT
    final evenFFT = _fft(even);
    final oddFFT = _fft(odd);
    
    // Combine results
    final result = List<Complex>.filled(n, Complex(0, 0));
    for (int k = 0; k < n ~/ 2; k++) {
      final angle = -2 * pi * k / n;
      final twiddle = Complex(cos(angle), sin(angle));
      final oddTerm = oddFFT[k] * twiddle;
      
      result[k] = evenFFT[k] + oddTerm;
      result[k + n ~/ 2] = evenFFT[k] - oddTerm;
    }
    
    return result;
  }

  /// Compute cross-power spectral density
  List<Complex> _computeCrossPower(List<Complex> leftFFT, List<Complex> rightFFT) {
    final crossPower = <Complex>[];
    for (int i = 0; i < leftFFT.length; i++) {
      crossPower.add(leftFFT[i] * rightFFT[i].conjugate());
    }
    return crossPower;
  }

  /// Apply GCC-PHAT weighting
  List<Complex> _applyGccPhatWeighting(List<Complex> crossPower) {
    final gccPhat = <Complex>[];
    for (final power in crossPower) {
      final magnitude = power.abs();
      if (magnitude > 1e-10) {
        gccPhat.add(power / magnitude);
      } else {
        gccPhat.add(Complex(0, 0));
      }
    }
    return gccPhat;
  }

  /// Compute inverse FFT
  Float32List _computeInverseFFT(List<Complex> data) {
    // Conjugate the input for IFFT
    final conjugated = data.map((c) => c.conjugate()).toList();
    
    // Apply FFT
    final fftResult = _fft(conjugated);
    
    // Conjugate and scale
    final result = Float32List(data.length);
    for (int i = 0; i < data.length; i++) {
      result[i] = fftResult[i].conjugate().real / data.length;
    }
    
    return result;
  }

  /// Find peak index in cross-correlation
  int _findPeakIndex(Float32List crossCorrelation) {
    int peakIndex = 0;
    double peakValue = crossCorrelation[0].abs();
    
    for (int i = 1; i < crossCorrelation.length; i++) {
      if (crossCorrelation[i].abs() > peakValue) {
        peakValue = crossCorrelation[i].abs();
        peakIndex = i;
      }
    }
    
    return peakIndex;
  }

  /// Convert peak index to time delay
  double _indexToTimeDelay(int peakIndex, int fftSize, double sampleRate) {
    // Handle circular shift for negative delays
    if (peakIndex > fftSize ~/ 2) {
      peakIndex -= fftSize;
    }
    
    return peakIndex / sampleRate;
  }

  /// Convert time delay to angle
  double _timeDelayToAngle(double timeDelay, double micDistance, double soundSpeed) {
    // Clamp time delay to physical limits
    final maxDelay = micDistance / soundSpeed;
    final clampedDelay = timeDelay.clamp(-maxDelay, maxDelay);
    
    // Convert to angle using arcsin
    final angle = asin(clampedDelay * soundSpeed / micDistance);
    
    // Clamp to reasonable range
    return angle.clamp(-pi / 2, pi / 2);
  }



  /// Convert an angle in radians to a simple left/center/right label.
  String directionLabel(double angle) {
    final threshold = pi / 8; // ~22.5 degrees dead zone for "center"
    if (angle > threshold) return 'right';
    if (angle < -threshold) return 'left';
    return 'center';
  }

  double _rms(Float32List samples) {
    double sum = 0.0;
    for (var i = 0; i < samples.length; i++) {
      final v = samples[i];
      sum += v * v;
    }
    return sqrt(sum / samples.length);
  }
}
