import 'dart:async';
import 'package:audio_streamer/audio_streamer.dart';
import 'package:live_captions_xr/core/services/debug_capturing_logger.dart';

class AudioCaptureService {
  static final DebugCapturingLogger _logger = DebugCapturingLogger();
  StreamSubscription<List<double>>? _audioSubscription;
  final StreamController<List<int>> _streamController = StreamController<List<int>>();

  Stream<List<int>> get audioStream => _streamController.stream;

  Future<void> start() async {
    _logger.i('🎤 Starting audio capture...');
    AudioStreamer().sampleRate = 16000;
    _audioSubscription = AudioStreamer().audioStream.listen((buffer) {
      _streamController.add(buffer.map((d) => d.toInt()).toList());
    }, onError: (error) {
      _logger.e('Error in audio stream: $error');
    });
    _logger.i('✅ Audio capture started.');
  }

  void stop() {
    _logger.i('🛑 Stopping audio capture...');
    _audioSubscription?.cancel();
    _streamController.close();
  }
}
