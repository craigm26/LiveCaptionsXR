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
  BytesBuilder? _pendingChunkBuilder;
  DateTime? _lastChunkEmitAt;
  DateTime? _lastSpeechAt;
  bool _speechActive = false;
  double _smoothedRms = 0.0;

  static const int _targetSampleRate = 16000;
  static const int _bytesPerSample = 2;
  static const double _speechStartRms = 0.02;
  static const double _speechStopRms = 0.015;
  static const Duration _speechHangover = Duration(milliseconds: 350);
  static const int _minSpeechChunkBytes =
      (_targetSampleRate * _bytesPerSample) ~/ 2; // ~0.5 second
  static const int _targetChunkBytes =
      _targetSampleRate * _bytesPerSample * 1; // ~1 second
  static const Duration _maxChunkInterval = Duration(seconds: 1);
  static const Duration _silenceFlushInterval = Duration(milliseconds: 700);

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
      _resetBufferingState();
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
        _bufferAudioChunk(controller, chunk, rmsLevel);
        
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
      if (_streamController != null) {
        await _flushBufferedAudio(_streamController!);
        await _streamController?.close();
      }
      _streamController = null;
      _isCapturing = false;
      _audioChunksProcessed = 0;
      _resetBufferingState();
      _logger.i('✅ Audio capture stopped successfully', category: LogCategory.audio);
    } catch (e, stackTrace) {
      _logger.e('❌ Error stopping audio capture', category: LogCategory.audio, error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  bool get isCapturing => _isCapturing;
  int get audioChunksProcessed => _audioChunksProcessed;

  void _bufferAudioChunk(
    StreamController<Uint8List> controller,
    Uint8List chunk,
    double rmsLevel,
  ) {
    if (controller.isClosed) {
      return;
    }

    _pendingChunkBuilder ??= BytesBuilder();
    _pendingChunkBuilder!.add(chunk);

    final now = DateTime.now();
    _lastChunkEmitAt ??= now;
    final bufferedBytes = _pendingChunkBuilder!.length;
    _smoothedRms = _smoothedRms == 0.0
        ? rmsLevel
        : (_smoothedRms * 0.8) + (rmsLevel * 0.2);

    final bool wasActive = _speechActive;
    if (_smoothedRms >= _speechStartRms) {
      _speechActive = true;
      _lastSpeechAt = now;
    } else if (_speechActive &&
        _lastSpeechAt != null &&
        now.difference(_lastSpeechAt!) > _speechHangover &&
        _smoothedRms < _speechStopRms) {
      _speechActive = false;
    }

    final bool reachedTargetSize = bufferedBytes >= _targetChunkBytes;
    final bool reachedSpeechThreshold = _speechActive &&
        bufferedBytes >= _minSpeechChunkBytes;

    final bool reachedTimeout =
        now.difference(_lastChunkEmitAt!) >= _maxChunkInterval;
    final bool silenceFlush = !wasActive &&
        !_speechActive &&
        _pendingChunkBuilder!.length >= (_targetSampleRate ~/ 5) * _bytesPerSample &&
        now.difference(_lastChunkEmitAt!) >= _silenceFlushInterval;

    if (reachedTargetSize ||
        reachedSpeechThreshold ||
        reachedTimeout ||
        silenceFlush) {
      final combined = _pendingChunkBuilder!.takeBytes();
      if (combined.isNotEmpty && !controller.isClosed) {
        controller.add(combined);
        _logger.d(
          '📤 Sent batched audio chunk to stream (${combined.length} bytes)',
          category: LogCategory.audio,
        );
      }
      _pendingChunkBuilder = null;
      _lastChunkEmitAt = now;
    }
  }

  Future<void> _flushBufferedAudio(StreamController<Uint8List> controller) async {
    final builder = _pendingChunkBuilder;
    if (builder == null || builder.length == 0 || controller.isClosed) {
      _pendingChunkBuilder = null;
      _lastChunkEmitAt = null;
      return;
    }

    final combined = builder.takeBytes();
    if (combined.isNotEmpty && !controller.isClosed) {
      controller.add(combined);
      _logger.d(
        '📤 Flushed final audio chunk (${combined.length} bytes)',
        category: LogCategory.audio,
      );
    }
    _pendingChunkBuilder = null;
    _lastChunkEmitAt = null;
  }

  void _resetBufferingState() {
    _pendingChunkBuilder = null;
    _lastChunkEmitAt = null;
    _lastSpeechAt = null;
    _speechActive = false;
    _smoothedRms = 0.0;
  }
}
