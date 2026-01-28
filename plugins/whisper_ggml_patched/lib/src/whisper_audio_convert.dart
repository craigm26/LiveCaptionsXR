import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart';

/// Class used to convert any audio file to wav
/// Patched: ffmpeg dependency removed - returns input file as-is
/// LiveCaptionsXR handles audio format natively via Nexa SDK
class WhisperAudioConvert {
  ///
  const WhisperAudioConvert({
    required this.audioInput,
    required this.audioOutput,
  });

  /// Input audio file
  final File audioInput;

  /// Output audio file
  final File audioOutput;

  /// convert [audioInput] to wav file
  /// Stub: copies input to output without ffmpeg conversion
  Future<File?> convert() async {
    try {
      await audioInput.copy(audioOutput.path);
      return audioOutput;
    } catch (e) {
      debugPrint('File conversion error: $e');
      return null;
    }
  }
}
