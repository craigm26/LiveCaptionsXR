import 'dart:async';
import 'package:mockito/mockito.dart';
import 'package:live_captions_xr/core/services/apple_speech_service.dart';
import 'package:live_captions_xr/core/models/speech_result.dart';

class MockAppleSpeechService extends Mock implements AppleSpeechService {
  final StreamController<SpeechResult> _mockSpeechResultController = StreamController<SpeechResult>.broadcast();
  final StreamController<AppleSpeechEvent> _mockSttEventController = StreamController<AppleSpeechEvent>.broadcast();
  
  @override
  Stream<SpeechResult> get speechResults => _mockSpeechResultController.stream;
  
  @override
  Stream<AppleSpeechEvent> get sttEvents => _mockSttEventController.stream;
  
  @override
  bool get isInitialized => true;
  
  @override
  bool get isListening => false;
  
  @override
  Future<bool> initialize({config}) async {
    // Mock initialization - always succeeds
    return true;
  }
  
  @override
  Future<bool> startProcessing({bool useOfflineMode = true}) async {
    // Mock start processing - always succeeds
    return true;
  }
  
  @override
  Future<void> stopProcessing() async {
    // Mock stop - do nothing
  }
  
  @override
  Future<void> updateConfig(config) async {
    // Mock update - do nothing
  }
  
  @override
  Future<void> dispose() async {
    _mockSpeechResultController.close();
    _mockSttEventController.close();
  }
}