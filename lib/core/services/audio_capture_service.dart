import 'dart:async';
import 'package:mic_stream/mic_stream.dart';
import 'package:live_captions_xr/core/services/debug_capturing_logger.dart';

class AudioCaptureService {
  static final DebugCapturingLogger _logger = DebugCapturingLogger();
  Stream<List<int>>? _stream;

  Stream<List<int>>? get audioStream => _stream;

  Future<void> start() async {
    _logger.i('🎤 Starting audio capture...');
    _stream = await MicStream.microphone(
      audioSource: AudioSource.MIC,
      sampleRate: 16000,
      channelConfig: ChannelConfig.CHANNEL_IN_MONO,
      audioFormat: AudioFormat.ENCODING_PCM_16BIT,
    );
    _logger.i('✅ Audio capture started.');
  }

  void stop() {
    _logger.i('🛑 Stopping audio capture...');
    // The mic_stream package handles the stream closure.
  }
}
