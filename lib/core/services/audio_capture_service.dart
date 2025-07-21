import 'dart:async';
import 'package:audio_streamer/audio_streamer.dart';
import 'package:live_captions_xr/core/services/debug_capturing_logger.dart';
import 'dart:math';

class AudioCaptureService {
  static final DebugCapturingLogger _logger = DebugCapturingLogger();
  StreamSubscription<List<double>>? _audioSubscription;
  final StreamController<List<int>> _streamController = StreamController<List<int>>();
  
  bool _isCapturing = false;
  int _audioChunksProcessed = 0;

  Stream<List<int>> get audioStream => _streamController.stream;

  Future<void> start() async {
    if (_isCapturing) {
      _logger.w('⚠️ Audio capture already running, skipping start');
      return;
    }
    
    _logger.i('🎤 Starting audio capture...');
    _logger.d('📊 Configuring audio streamer with 16kHz sample rate');
    
    try {
      AudioStreamer().sampleRate = 16000;
      _audioSubscription = AudioStreamer().audioStream.listen((buffer) {
        _audioChunksProcessed++;
        _logger.d('🎵 Audio chunk #$_audioChunksProcessed received (${buffer.length} samples)');
        
        // Calculate RMS level for monitoring
        double rmsLevel = 0.0;
        for (int i = 0; i < buffer.length; i++) {
          rmsLevel += buffer[i] * buffer[i];
        }
        rmsLevel = buffer.length > 0 ? sqrt(rmsLevel / buffer.length) : 0.0;
        
        _logger.d('📊 Audio levels - RMS: ${rmsLevel.toStringAsFixed(4)}');
        
        // Check if audio level is above threshold (potential speech)
        if (rmsLevel > 0.01) {
          _logger.d('🗣️ Potential speech detected (RMS: ${rmsLevel.toStringAsFixed(4)})');
        }
        
        final intBuffer = buffer.map((d) => d.toInt()).toList();
        _streamController.add(intBuffer);
        _logger.d('📤 Sent audio chunk to stream (${intBuffer.length} samples)');
        
      }, onError: (error) {
        _logger.e('❌ Error in audio stream: $error');
      });
      
      _isCapturing = true;
      _logger.i('✅ Audio capture started successfully');
      _logger.d('📊 Audio capture stats - Chunks processed: $_audioChunksProcessed');
      
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to start audio capture', error: e, stackTrace: stackTrace);
      _isCapturing = false;
      rethrow;
    }
  }

  void stop() {
    if (!_isCapturing) {
      _logger.w('⚠️ Audio capture not running, skipping stop');
      return;
    }
    
    _logger.i('🛑 Stopping audio capture...');
    _logger.d('📊 Final stats - Total chunks processed: $_audioChunksProcessed');
    
    try {
      _audioSubscription?.cancel();
      _streamController.close();
      _isCapturing = false;
      _audioChunksProcessed = 0;
      _logger.i('✅ Audio capture stopped successfully');
    } catch (e, stackTrace) {
      _logger.e('❌ Error stopping audio capture', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  bool get isCapturing => _isCapturing;
  int get audioChunksProcessed => _audioChunksProcessed;
}
