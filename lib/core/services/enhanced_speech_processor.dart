import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:live_captions_xr/core/services/audio_capture_service.dart';
import 'package:flutter_sound/flutter_sound.dart';

import '../models/speech_result.dart';
import '../models/speech_config.dart';
import '../models/enhanced_caption.dart';
import 'debug_capturing_logger.dart';
import 'gemma_3n_service.dart';

/// Speech processing engine types
enum SpeechEngine {
  native,
  flutter_sound,
  gemma3n, openAI,
}

/// Enhanced service for processing speech with multiple engine support and Gemma enhancement
class EnhancedSpeechProcessor {
  static final DebugCapturingLogger _logger = DebugCapturingLogger();

  final Gemma3nService gemma3nService;
  static const MethodChannel _nativeChannel = MethodChannel('live_captions_xr/speech');

  // FlutterSound specific
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  StreamSubscription? _recorderSubscription;


  // Google Cloud Speech specific

  bool _isInitialized = false;
  bool _isProcessing = false;
  SpeechConfig _config = const SpeechConfig();
  SpeechEngine _activeEngine = SpeechEngine.flutter_sound;
  String? _currentLanguage;
  final List<String> _recentTexts = [];

  final StreamController<SpeechResult> _speechResultController = StreamController<SpeechResult>.broadcast();
  final StreamController<EnhancedCaption> _enhancedCaptionController = StreamController<EnhancedCaption>.broadcast();

  Stream<SpeechResult> get speechResults => _speechResultController.stream;
  Stream<EnhancedCaption> get enhancedCaptions => _enhancedCaptionController.stream;

  final AudioCaptureService _audioCaptureService;

  EnhancedSpeechProcessor({
    required this.gemma3nService,
    required AudioCaptureService audioCaptureService,
    SpeechEngine? defaultEngine,
  }) : _activeEngine = defaultEngine ?? SpeechEngine.flutter_sound,
       _audioCaptureService = audioCaptureService;

  Future<bool> initialize({
    SpeechConfig? config,
    bool enableGemmaEnhancement = true,
  }) async {
    if (_isInitialized) return true;

    try {
      _config = config ?? const SpeechConfig();
      _currentLanguage = _config.language;

      switch (_activeEngine) {
        case SpeechEngine.flutter_sound:
          await _initializeFlutterSound();
          break;
        case SpeechEngine.native:
          await _initializeNativeEngine();
          break;
        case SpeechEngine.gemma3n:
          _logger.w('Gemma 3n ASR not yet implemented, falling back to flutter_sound');
          _activeEngine = SpeechEngine.flutter_sound;
          await _initializeFlutterSound();
          break;
        case SpeechEngine.openAI:
          // TODO: Handle this case.
          throw UnimplementedError();
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

  Future<void> _initializeFlutterSound() async {
    await _recorder.openRecorder();
    _logger.i('✅ FlutterSound engine initialized');
  }

  Future<void> _initializeNativeEngine() async {
    await _nativeChannel.invokeMethod('initializeSpeech');
    _logger.i('✅ Native speech engine initialized');
  }

  Future<bool> startProcessing({SpeechConfig? config}) async {
    if (!_isInitialized) return false;
    if (_isProcessing) return true;

    try {
      if (config != null) await updateConfig(config);

      await _audioCaptureService.start();

      switch (_activeEngine) {
        case SpeechEngine.flutter_sound:
          await _startFlutterSoundProcessing();
          break;
        case SpeechEngine.native:
          await _startNativeProcessing();
          break;
        case SpeechEngine.gemma3n:
          await _startFlutterSoundProcessing();
          break;
        case SpeechEngine.openAI:
          // TODO: Handle this case.
          throw UnimplementedError();
      }

      _isProcessing = true;
      _logger.i('✅ Speech processing started with engine: $_activeEngine');
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Error starting speech processing', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> _startFlutterSoundProcessing() async {
    final StreamController<Food> recordingDataController = StreamController<Food>();
    _recorderSubscription = recordingDataController.stream.listen((buffer) {
      if (buffer is FoodData) {
        _processSpeechResult(SpeechResult(
          text: "TODO",
          confidence: 1.0,
          isFinal: true,
          timestamp: DateTime.now(),
        ));
      }
    });

    final StreamController<Uint8List> uint8ListController = StreamController<Uint8List>();
    recordingDataController.stream.transform(StreamTransformer.fromHandlers(
      handleData: (data, sink) {
        if (data is FoodData) {
          sink.add(data.data!);
        }
      },
    )).pipe(uint8ListController);

    await _recorder.startRecorder(
      toStream: uint8ListController.sink,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: 16000,
    );
  }

  Future<void> _startNativeProcessing() async {
    _nativeChannel.setMethodCallHandler(_handleNativeMethodCall);
    await _nativeChannel.invokeMethod('startListening', {'language': _currentLanguage});
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
        case SpeechEngine.flutter_sound:
          await _stopFlutterSoundProcessing();
          break;
        case SpeechEngine.native:
          await _nativeChannel.invokeMethod('stopListening');
          break;
        case SpeechEngine.gemma3n:
          await _stopFlutterSoundProcessing();
          break;
        case SpeechEngine.openAI:
          // TODO: Handle this case.
          throw UnimplementedError();
      }

      _isProcessing = false;
      _logger.i('✅ Speech processing stopped');
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Error stopping speech processing', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> _stopFlutterSoundProcessing() async {
    await _recorder.stopRecorder();
    await _recorderSubscription?.cancel();
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