import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:audio_streamer/audio_streamer.dart';
import 'package:live_captions_xr/core/services/app_logger.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioCaptureService {
  static final AppLogger _logger = AppLogger.instance;
  StreamSubscription<List<double>>? _audioSubscription;
  StreamController<Uint8List>? _streamController;
  
  bool _isCapturing = false;
  int _audioChunksProcessed = 0;

  Stream<Uint8List> get audioStream {
    final controller = _streamController;
    if (controller != null && !controller.isClosed) {
      return controller.stream;
    }
    return Stream<Uint8List>.empty();
  }

  Future<void> start() async {
    if (_isCapturing) {
      _logger.w('⚠️ Audio capture already running, skipping start', category: LogCategory.audio);
      return;
    }
    
    _logger.i('🎤 Starting audio capture...', category: LogCategory.audio);
    _logger.d('🔐 Checking microphone permission...', category: LogCategory.audio);

    final permissionStatus = await Permission.microphone.status;
    if (!permissionStatus.isGranted) {
      final result = await Permission.microphone.request();
      if (!result.isGranted) {
        _logger.e('❌ Microphone permission denied. Cannot start audio capture.', category: LogCategory.audio);
        throw Exception('Microphone permission required for audio capture');
      }
    }

    _logger.d('📊 Configuring audio streamer with 16kHz sample rate', category: LogCategory.audio);
    
    try {
      final audioStreamer = AudioStreamer();
      audioStreamer.sampleRate = 16000;
      final controller = StreamController<Uint8List>.broadcast();
      _streamController = controller;
      _audioSubscription = audioStreamer.audioStream.listen((buffer) {
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
        
        final byteData = ByteData(buffer.length * 2);
        for (int i = 0; i < buffer.length; i++) {
          final double sample = buffer[i].clamp(-1.0, 1.0);
          final int intSample = (sample * 32767).round().clamp(-32768, 32767);
          byteData.setInt16(i * 2, intSample, Endian.little);
        }
        final chunk = byteData.buffer.asUint8List();
        if (!controller.isClosed) {
          controller.add(chunk);
        }
        _logger.d('📤 Sent audio chunk to stream (${chunk.length} bytes)', category: LogCategory.audio);
        
      }, onError: (error) {
        _logger.e('❌ Error in audio stream: $error', category: LogCategory.audio);
        if (!controller.isClosed) {
          controller.addError(error);
        }
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

  Future<void> stop() async {
    if (!_isCapturing) {
      _logger.w('⚠️ Audio capture not running, skipping stop', category: LogCategory.audio);
      return;
    }
    
    _logger.i('🛑 Stopping audio capture...', category: LogCategory.audio);
    _logger.d('📊 Final stats - Total chunks processed: $_audioChunksProcessed', category: LogCategory.audio);
    
    try {
      await _audioSubscription?.cancel();
      _audioSubscription = null;
      await _streamController?.close();
      _streamController = null;
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
