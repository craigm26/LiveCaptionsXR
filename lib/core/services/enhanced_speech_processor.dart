import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart' as stt;
import 'package:dart_openai/dart_openai.dart';
import 'package:google_speech/google_speech.dart' as google_speech;
import 'package:live_captions_xr/core/di/service_locator.dart';
import 'package:live_captions_xr/core/services/google_auth_service.dart';

import '../models/speech_result.dart';
import '../models/speech_config.dart';
import '../models/enhanced_caption.dart';
import 'debug_capturing_logger.dart';
import 'gemma_3n_service.dart';

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
  google_speech.SpeechToTextV2? _googleSpeechV2;
  StreamSubscription<google_speech.StreamingRecognizeResponse>? _googleSpeechSubscription;

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
    _logger.i('✅ OpenAI (Whisper) engine initialized');
  }

  Future<void> _initializeGoogleCloudSpeech() async {
    final serviceAccountJson = dotenv.env['GOOGLE_APPLICATION_CREDENTIALS_JSON'];
    if (serviceAccountJson == null || serviceAccountJson.isEmpty) {
      _logger.e('❌ GOOGLE_APPLICATION_CREDENTIALS_JSON not found in .env file.');
      throw Exception('Google Cloud credentials not found.');
    }
    final credentials = google_speech.GoogleSpeechV2Credentials.fromJson(serviceAccountJson);
    _googleSpeechV2 = google_speech.SpeechToTextV2(credentials);
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

  void _startOpenAIProcessing() {
    _logger.w('OpenAI processing needs to be adapted to a file-based workflow.');
    _transcribeAudioChunk(Uint8List(0));
  }

  void _startGoogleCloudSpeechProcessing() {
    final config = google_speech.RecognitionConfigV2(
      autoDecodingConfig: google_speech.AutoDetectDecodingConfig(),
      model: 'chirp',
      languageCodes: [_currentLanguage ?? 'en-US'],
      features: google_speech.RecognitionFeatures(enableAutomaticPunctuation: true),
    );
    
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
        confidence: 1.0,
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

  void _onSpeechToTextResult(stt.SpeechRecognitionResult result) {
    _processSpeechResult(SpeechResult(
      text: result.recognizedWords,
      confidence: result.confidence,
      isFinal: result.finalResult,
      timestamp: DateTime.now(),
    ));
  }

  Future<dynamic> _handleNativeMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onSpeechResult':
        final text = call.arguments['text'] as String;
        final confidence = call.arguments['confidence'] as double;
        final isFinal = call.arguments['isFinal'] as bool;
        
        _processSpeechResult(SpeechResult(
          text: text,
          confidence: confidence,
          isFinal: isFinal,
          timestamp: DateTime.now(),
        ));
        break;
    }
  }

  void _processSpeechResult(SpeechResult result) async {
    _speechResultController.add(result);
    
    if (result.isFinal) {
      _recentTexts.add(result.text);
      if (_recentTexts.length > 10) {
        _recentTexts.removeAt(0);
      }
    }
    
    if (gemma3nService.isReady) {
      try {
        if (result.isFinal) {
          final enhancedText = await gemma3nService.enhanceText(result.text);
          _enhancedCaptionController.add(EnhancedCaption(
            raw: result.text,
            enhanced: enhancedText,
            isFinal: true,
            isEnhanced: enhancedText != result.text,
          ));
        } else {
          _enhancedCaptionController.add(EnhancedCaption.partial(result.text));
        }
      } catch (e) {
        _logger.e('Failed to enhance caption', error: e);
        _enhancedCaptionController.add(EnhancedCaption.fallback(result.text));
      }
    } else {
      _enhancedCaptionController.add(
        result.isFinal 
          ? EnhancedCaption(raw: result.text, enhanced: result.text, isFinal: true, isEnhanced: false)
          : EnhancedCaption.partial(result.text)
      );
    }
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
  
  Future<bool> switchEngine(SpeechEngine engine) async {
    if (_isProcessing) {
      await stopProcessing();
    }
    
    _activeEngine = engine;
    _logger.i('🔄 Switched to speech engine: $engine');
    
    _isInitialized = false;
    return await initialize(config: _config);
  }

  Future<void> updateConfig(SpeechConfig newConfig) async {
    _config = newConfig;
    _currentLanguage = newConfig.language;
  }

  void dispose() {
    stopProcessing();
    _speechResultController.close();
    _enhancedCaptionController.close();
  }

  bool get isReady => _isInitialized;
  bool get isProcessing => _isProcessing;
  SpeechEngine get activeEngine => _activeEngine;
  bool get hasGemmaEnhancement => gemma3nService.isReady;
}