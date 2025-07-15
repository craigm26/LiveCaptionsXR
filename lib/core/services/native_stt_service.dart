import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class NativeSttService {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  StreamController<String> _transcriptionController = StreamController<String>.broadcast();

  Stream<String> get transcriptionStream => _transcriptionController.stream;

  Future<void> initialize() async {
    _speechEnabled = await _speechToText.initialize();
  }

  void startListening() {
    if (!_speechEnabled) {
      return;
    }
    _speechToText.listen(
      onResult: (SpeechRecognitionResult result) {
        _transcriptionController.add(result.recognizedWords);
      },
    );
  }

  void stopListening() {
    if (!_speechEnabled) {
      return;
    }
    _speechToText.stop();
  }

  void dispose() {
    _transcriptionController.close();
  }
}
