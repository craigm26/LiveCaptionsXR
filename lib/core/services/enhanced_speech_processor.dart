import 'dart:async';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart' as stt;
import 'package:dart_openai/dart_openai.dart';

import '../models/speech_result.dart';
import '../models/speech_config.dart';
import '../models/enhanced_caption.dart';
import 'debug_capturing_logger.dart';
import 'gemma3n_service.dart';

/// Speech processing engine types
enum SpeechEngine {
  native,
  speechToText,
  gemma3n,
  openAI,
  googleCloud,
}

/// Enhanced service for processing speech with multiple engine support and Gemma enhancement
class EnhancedSpeechProcessor {
  static final DebugCapturingLogger _logger = DebugCapturingLogger();

  final Gemma3nService gemma3nService;
  final SpeechToText _speechToText = SpeechToText();
  static const MethodChannel _nativeChannel = MethodChannel('live_captions_xr/speech');

  // Google Cloud Speech specific
  SpeechToTextV2? _googleSpeechV2;
  StreamSubscription<StreamingRecognizeResponse>? _googleSpeechSubscription;

  bool _isInitialized = false;
  bool _isProcessing = false;
  SpeechConfig _config = const SpeechConfig();
  SpeechEngine _activeEngine = SpeechEngine.speechToText;
  String? _currentLanguage;
  final List<String> _recentTexts = [];

  final StreamController<SpeechResult> _speechResultController = StreamController<SpeechResult>.broadcast();
  final StreamController<EnhancedCaption> _enhancedCaptionController = StreamController<EnhancedCaption>.broadcast();

  Stream<SpeechResult> get speechResults => _speechResultController.stream;
  Stream<EnhancedCaption> get enhancedCaptions => _enhancedCaptionController.stream;

  EnhancedSpeechProcessor({
    required this.gemma3nService,
    SpeechEngine? defaultEngine,
  }) : _activeEngine = defaultEngine ?? SpeechEngine.speechToText;

  Future<bool> initialize({
    SpeechConfig? config,
    bool enableGemmaEnhancement = true,
  }) async {
    if (_isInitialized) return true;

    try {
      _config = config ?? const SpeechConfig();
      _currentLanguage = _config.language;

      switch (_activeEngine) {
        case SpeechEngine.speechToText:
          await _initializeSpeechToText();
          break;
        case SpeechEngine.native:
          await _initializeNativeEngine();
          break;
        case SpeechEngine.openAI:
          _initializeOpenAI();
          break;
        case SpeechEngine.googleCloud:
          await _initializeGoogleCloudSpeech();
          break;
        case SpeechEngine.gemma3n:
          _logger.w('Gemma 3n ASR not yet implemented, falling back to speech_to_text');
          _activeEngine = SpeechEngine.speechToText;
          await _initializeSpeechToText();
          break;
      }

      if (enableGemmaEnhancement && gemma3nService.isReady) {
        _logger.i('✅ Gemma enhancement enabled');
      } else if (enableGemmaEnhancement) {
        _logger.w('⚠️ Gemma3nService not ready, enhancement will be disabled.');
      }

      _isInitialized = true;
      _logger.i('✅ EnhancedSpeechProcessor initialized with engine: $_activeEngine');
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Error initializing EnhancedSpeechProcessor', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> _initializeSpeechToText() async {
    final available = await _speechToText.initialize(
      onStatus: (status) => _logger.d('Speech status: $status'),
      onError: (error) => _logger.e('Speech error: $error'),
    );
    if (!available) throw Exception('Speech-to-text not available on this device');
    _logger.i('✅ speech_to_text package initialized');
  }

  Future<void> _initializeNativeEngine() async {
    await _nativeChannel.invokeMethod('initializeSpeech');
    _logger.i('✅ Native speech engine initialized');
  }

  void _initializeOpenAI() {
    // This should be done at app startup, not here.
    // OpenAI.apiKey = 'YOUR_API_KEY';
    _logger.i('✅ OpenAI (Whisper) engine initialized');
  }

  Future<void> _initializeGoogleCloudSpeech() async {
    final serviceAccountJson = dotenv.env['GOOGLE_APPLICATION_CREDENTIALS_JSON'];
    if (serviceAccountJson == null || serviceAccountJson.isEmpty) {
      _logger.e('❌ GOOGLE_APPLICATION_CREDENTIALS_JSON not found in .env file.');
      throw Exception('Google Cloud credentials not found.');
    }
    final credentials = GoogleSpeechV2Credentials.fromJson(serviceAccountJson);
    _googleSpeechV2 = SpeechToTextV2(credentials);
    _logger.i('✅ Google Cloud Speech V2 initialized');
  }

  Future<bool> startProcessing({SpeechConfig? config}) async {
    if (!_isInitialized) return false;
    if (_isProcessing) return true;

    try {
      if (config != null) await updateConfig(config);

      switch (_activeEngine) {
        case SpeechEngine.speechToText:
          await _startSpeechToTextProcessing();
          break;
        case SpeechEngine.native:
          await _startNativeProcessing();
          break;
        case SpeechEngine.openAI:
          _startOpenAIProcessing();
          break;
        case SpeechEngine.googleCloud:
          _startGoogleCloudSpeechProcessing();
          break;
        case SpeechEngine.gemma3n:
          await _startSpeechToTextProcessing();
          break;
      }

      _isProcessing = true;
      _logger.i('✅ Speech processing started with engine: $_activeEngine');
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Error starting speech processing', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> _startSpeechToTextProcessing() async {
    await _speechToText.listen(
      onResult: _onSpeechToTextResult,
      localeId: _currentLanguage,
    );
  }

  Future<void> _startNativeProcessing() async {
    _nativeChannel.setMethodCallHandler(_handleNativeMethodCall);
    await _nativeChannel.invokeMethod('startListening', {'language': _currentLanguage});
  }

  import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart' as stt;
import 'package:dart_openai/dart_openai.dart';

import '../models/speech_result.dart';
import '../models/speech_config.dart';
import '../models/enhanced_caption.dart';
import 'debug_capturing_logger.dart';
import 'gemma3n_service.dart';

// ... (enum and class definition are the same)

  void _startOpenAIProcessing() {
    // This requires a file path to an audio file. The dart_openai package
    // does not support streaming transcription directly. This would need to be
    // adapted to a record -> save -> transcribe workflow.
    _logger.w('OpenAI processing needs to be adapted to a file-based workflow.');
  }

  void _startGoogleCloudSpeechProcessing() {
    final config = RecognitionConfigV2(
      autoDecodingConfig: AutoDetectDecodingConfig(),
      model: 'chirp', // Using the newer Chirp model
      languageCodes: [_currentLanguage ?? 'en-US'],
      features: RecognitionFeatures(
        enableAutomaticPunctuation: true,
      ),
    );
    
    // This requires a stream of audio bytes from the microphone.
    final audioStream = Stream<List<int>>.empty();

    _googleSpeechSubscription = _googleSpeechV2?.streamingRecognize(config, audioStream).listen((response) {
      final result = response.results.first;
      _processSpeechResult(SpeechResult(
        text: result.alternatives.first.transcript,
        confidence: result.alternatives.first.confidence,
        isFinal: result.isFinal,
        timestamp: DateTime.now(),
      ));
    });
  }

  Future<void> _transcribeAudioChunk(Uint8List audioData) async {
    if (OpenAI.apiKey.isEmpty) {
      _logger.e('❌ OpenAI API key is not set. Cannot transcribe.');
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/temp_audio.wav');
    await tempFile.writeAsBytes(audioData);

    try {
      final transcription = await OpenAI.instance.audio.createTranscription(
        file: tempFile,
        model: 'whisper-1',
      );

      final result = SpeechResult(
        text: transcription.text,
        confidence: 1.0, // Whisper API doesn't provide confidence score
        isFinal: true,
        timestamp: DateTime.now(),
      );
      _processSpeechResult(result);
    } catch (e) {
      _logger.e('❌ OpenAI transcription failed', error: e);
    } finally {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

// ... (rest of the class is the same)

  void _onSpeechToTextResult(stt.SpeechRecognitionResult result) {
    _processSpeechResult(SpeechResult(
      text: result.recognizedWords,
      confidence: result.confidence,
      isFinal: result.finalResult,
      timestamp: DateTime.now(),
    ));
  }

  Future<dynamic> _handleNativeMethodCall(MethodCall call) async {
    // ... (implementation unchanged)
  }

  void _processSpeechResult(SpeechResult result) async {
    // ... (implementation unchanged)
  }

  Future<bool> stopProcessing() async {
    if (!_isProcessing) return true;

    try {
      switch (_activeEngine) {
        case SpeechEngine.speechToText:
          await _speechToText.stop();
          break;
        case SpeechEngine.native:
          await _nativeChannel.invokeMethod('stopListening');
          break;
        case SpeechEngine.openAI:
          // No streaming to stop
          break;
        case SpeechEngine.googleCloud:
          await _googleSpeechSubscription?.cancel();
          break;
        case SpeechEngine.gemma3n:
          await _speechToText.stop();
          break;
      }

      _isProcessing = false;
      _logger.i('✅ Speech processing stopped');
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Error stopping speech processing', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  // ... (rest of the class is unchanged)
} 