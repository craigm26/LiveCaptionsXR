import 'dart:async';
import 'package:audio_streamer/audio_streamer.dart';
import 'package:live_captions_xr/core/services/app_logger.dart';
import 'dart:math';

class AudioCaptureService {
  static final AppLogger _logger = AppLogger.instance;
  StreamSubscription<List<double>>? _audioSubscription;
  StreamController<List<int>> _streamController = StreamController<List<int>>.broadcast();
  
  bool _isCapturing = false;
  int _audioChunksProcessed = 0;

  Stream<List<int>> get audioStream => _streamController.stream;

  void _ensureStreamController() {
    if (_streamController.isClosed) {
      _streamController = StreamController<List<int>>.broadcast();
    }
  }

  Future<void> start() async {
    if (_isCapturing) {
      _logger.w('⚠️ Audio capture already running, skipping start', category: LogCategory.audio);
      return;
    }
    
    _logger.i('🎤 Starting audio capture...', category: LogCategory.audio);
    _logger.d('📊 Configuring audio streamer with 16kHz sample rate', category: LogCategory.audio);
    
    try {
      _ensureStreamController();
      AudioStreamer().sampleRate = 16000;
      _audioSubscription = AudioStreamer().audioStream.listen((buffer) {
        _audioChunksProcessed++;
        _logger.d('🎵 Audio chunk #$_audioChunksProcessed received (${buffer.length} samples)', category: LogCategory.audio);
        
        // Calculate RMS level for monitoring
        double rmsLevel = 0.0;
        for (int i = 0; i < buffer.length; i++) {
          rmsLevel += buffer[i] * buffer[i];
        }
        rmsLevel = buffer.isNotEmpty ? sqrt(rmsLevel / buffer.length) : 0.0;
        
        _logger.d('📊 Audio levels - RMS: ${rmsLevel.toStringAsFixed(4)}', category: LogCategory.audio);
        
        // Check if audio level is above threshold (potential speech)
        if (rmsLevel > 0.01) {
          _logger.d('🗣️ Potential speech detected (RMS: ${rmsLevel.toStringAsFixed(4)})', category: LogCategory.audio);
        }
        
        // Adaptively map plugin samples to normalized [-1.0, 1.0] audio.
        // Some runtimes provide samples in [0.0, 1.0] (unsigned normalized),
        // others in [-1.0, 1.0] (signed normalized).
        double minSample = double.infinity;
        double maxSample = double.negativeInfinity;
        double meanSample = 0.0;
        for (final sample in buffer) {
          if (sample < minSample) minSample = sample;
          if (sample > maxSample) maxSample = sample;
          meanSample += sample;
        }
        if (buffer.isNotEmpty) {
          meanSample /= buffer.length;
        }

        final looksUnsignedNormalized = minSample >= -0.001 && maxSample <= 1.001;

        // Convert to signed normalized then remove DC offset before int16 conversion.
        final signed = List<double>.filled(buffer.length, 0.0);
        for (int i = 0; i < buffer.length; i++) {
          final value = looksUnsignedNormalized
              ? (buffer[i] * 2.0) - 1.0
              : buffer[i];
          signed[i] = value;
        }

        double signedMean = 0.0;
        for (final value in signed) {
          signedMean += value;
        }
        if (signed.isNotEmpty) {
          signedMean /= signed.length;
        }

        final intBuffer = signed
            .map((value) => (((value - signedMean).clamp(-1.0, 1.0)) * 32767)
                .round()
                .clamp(-32768, 32767))
            .toList();

        if (_audioChunksProcessed % 25 == 0) {
          _logger.i(
            '🎛️ [AUDIO SRC] format=${looksUnsignedNormalized ? '[0..1]' : '[-1..1]'} min=${minSample.toStringAsFixed(3)} max=${maxSample.toStringAsFixed(3)} mean=${meanSample.toStringAsFixed(3)} signedMean=${signedMean.toStringAsFixed(3)}',
            category: LogCategory.audio,
          );
        }

        _streamController.add(intBuffer);
        _logger.d('📤 Sent audio chunk to stream (${intBuffer.length} samples)', category: LogCategory.audio);
        
      }, onError: (error) {
        _logger.e('❌ Error in audio stream: $error', category: LogCategory.audio);
      });
      
      _isCapturing = true;
      _logger.i('✅ Audio capture started successfully', category: LogCategory.audio);
      _logger.d('📊 Audio capture stats - Chunks processed: $_audioChunksProcessed', category: LogCategory.audio);
      
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to start audio capture', category: LogCategory.audio, error: e, stackTrace: stackTrace);
      _isCapturing = false;
      rethrow;
    }
  }

  void stop() {
    if (!_isCapturing) {
      _logger.w('⚠️ Audio capture not running, skipping stop', category: LogCategory.audio);
      return;
    }
    
    _logger.i('🛑 Stopping audio capture...', category: LogCategory.audio);
    _logger.d('📊 Final stats - Total chunks processed: $_audioChunksProcessed', category: LogCategory.audio);
    
    try {
      _audioSubscription?.cancel();
      _isCapturing = false;
      _audioChunksProcessed = 0;
      _logger.i('✅ Audio capture stopped successfully', category: LogCategory.audio);
    } catch (e, stackTrace) {
      _logger.e('❌ Error stopping audio capture', category: LogCategory.audio, error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  bool get isCapturing => _isCapturing;
  int get audioChunksProcessed => _audioChunksProcessed;
}
