import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:logger/logger.dart';

import '../models/speech_result.dart';
import '../models/speech_config.dart';
import '../models/enhanced_caption.dart';
import 'audio_capture_service.dart';
import 'gemma3n_service.dart';
import 'whisper_service.dart';
import 'debug_capturing_logger.dart';

/// Speech processing engine types
enum SpeechEngine {
  native,
  flutter_sound,
  gemma3n,
  openAI,
  whisper_ggml,
}

/// Enhanced service for processing speech with multiple engine support and Gemma enhancement
class EnhancedSpeechProcessor {
  static final DebugCapturingLogger _logger = DebugCapturingLogger();
  static final Logger _processorLogger = Logger();

  final Gemma3nService gemma3nService;
  final AudioCaptureService _audioCaptureService;
  final WhisperService _whisperService;

  SpeechEngine _activeEngine;
  SpeechConfig _config = const SpeechConfig();
  String _currentLanguage = 'en';
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _useEnhancement = true; // New flag to control enhancement

  // Flutter Sound components
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  StreamSubscription? _recorderSubscription;

  // Native channel
  static const MethodChannel _nativeChannel =
      MethodChannel('com.example.live_captions_xr/speech');

  // Stream controllers
  final StreamController<SpeechResult> _speechResultController =
      StreamController<SpeechResult>.broadcast();
  final StreamController<EnhancedCaption> _enhancedCaptionController =
      StreamController<EnhancedCaption>.broadcast();

  // Recent texts for enhancement
  final List<String> _recentTexts = [];
  static const String defaultFallbackTranscript = "Listening...";

  EnhancedSpeechProcessor({
    required this.gemma3nService,
    required AudioCaptureService audioCaptureService,
    required WhisperService whisperService,
    SpeechEngine? defaultEngine,
  })  : _activeEngine = defaultEngine ?? SpeechEngine.whisper_ggml,
        _audioCaptureService = audioCaptureService,
        _whisperService = whisperService;

  List<SpeechEngine> get availableEngines {
    final engines = <SpeechEngine>[];
    // Prioritize Whisper GGML as the primary engine
    engines.add(SpeechEngine.whisper_ggml);
    // Add other engines
    engines.add(SpeechEngine.flutter_sound);
    // Native engine availability could be checked here if needed
    // For Gemma3n, only add if available
    if (gemma3nService.isAvailable) {
      engines.add(SpeechEngine.gemma3n);
    }
    // Add other engines as they become available
    return engines;
  }

  void setActiveEngine(SpeechEngine engine) {
    if (!availableEngines.contains(engine)) {
      throw StateError('Selected ASR backend is not available: $engine');
    }
    _activeEngine = engine;
    _logger.i('🔄 User selected speech engine: $engine');
  }

  Stream<SpeechResult> get speechResults => _speechResultController.stream;
  Stream<EnhancedCaption> get enhancedCaptions =>
      _enhancedCaptionController.stream;

  Future<bool> initialize({
    SpeechConfig? config,
    bool enableGemmaEnhancement = true,
  }) async {
    if (_isInitialized) return true;

    try {
      _config = config ?? const SpeechConfig();
      _currentLanguage = _config.language;
      _useEnhancement = enableGemmaEnhancement; // Set the flag

      switch (_activeEngine) {
        case SpeechEngine.flutter_sound:
          await _initializeFlutterSound();
          break;
        case SpeechEngine.native:
          await _initializeNativeEngine();
          break;
        case SpeechEngine.gemma3n:
          _logger.w(
              'Gemma 3n ASR not yet implemented, falling back to flutter_sound');
          _activeEngine = SpeechEngine.flutter_sound;
          await _initializeFlutterSound();
          break;
        case SpeechEngine.openAI:
          // TODO: Handle this case.
          throw UnimplementedError();
        case SpeechEngine.whisper_ggml:
          await _initializeWhisperGgml();
          break;
      }

      if (enableGemmaEnhancement && gemma3nService.isAvailable) {
        _logger.i('✅ Gemma enhancement enabled');
      } else if (enableGemmaEnhancement) {
        _logger.w('⚠️ Gemma3nService not available, enhancement will be disabled.');
      }

      _isInitialized = true;
      _logger.i(
          '✅ EnhancedSpeechProcessor initialized with engine: $_activeEngine');
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Error initializing EnhancedSpeechProcessor',
          error: e, stackTrace: stackTrace);
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

  Future<void> _initializeWhisperGgml() async {
    try {
      await _whisperService.initialize(config: _config);
      _logger.i('✅ Whisper GGML engine initialized');
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to initialize Whisper GGML', error: e, stackTrace: stackTrace);
      rethrow;
    }
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
        case SpeechEngine.whisper_ggml:
          await _startWhisperGgmlProcessing();
          break;
      }

      _isProcessing = true;
      _logger.i('✅ Speech processing started with engine: $_activeEngine');
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Error starting speech processing',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> _startFlutterSoundProcessing() async {
    final StreamController<Food> recordingDataController = StreamController<Food>();
    _recorderSubscription = recordingDataController.stream.listen((buffer) async {
      if (buffer is FoodData && buffer.data != null) {
        try {
          String transcript = defaultFallbackTranscript;
          switch (_activeEngine) {
            case SpeechEngine.flutter_sound:
              // TODO: Integrate a real ASR backend for flutter_sound if available
              break;
            case SpeechEngine.gemma3n:
              if (gemma3nService.isAvailable) {
                // TODO: Implement audio transcription with Gemma3nService
                // For now, use fallback transcript
                transcript = defaultFallbackTranscript;
              }
              break;
            case SpeechEngine.native:
              // TODO: Integrate native ASR backend if available
              break;
            case SpeechEngine.openAI:
              // TODO: Integrate OpenAI ASR backend if available
              break;
            case SpeechEngine.whisper_ggml:
              // Process audio with WhisperService
              if (_whisperService.isInitialized) {
                final result = await _whisperService.processAudioBuffer(buffer.data!);
                transcript = result.text;
              } else {
                transcript = defaultFallbackTranscript;
              }
              break;
          }
          _processSpeechResult(SpeechResult(
            text: transcript,
            confidence: 1.0,
            isFinal: true,
            timestamp: DateTime.now(),
          ));
        } catch (e) {
          _logger.e('Error transcribing audio', error: e);
        }
      }
    });

    final StreamController<Uint8List> uint8ListController =
        StreamController<Uint8List>();
    recordingDataController.stream.transform(StreamTransformer.fromHandlers(
      handleData: (data, sink) {
        if (data is FoodData) {
          sink.add(data.data!);
        }
      },
    )).pipe(uint8ListController.sink);

    await _recorder.startRecorder(
      toStream: uint8ListController.sink,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: 16000,
    );
  }

  Future<void> _startNativeProcessing() async {
    _nativeChannel.setMethodCallHandler(_handleNativeMethodCall);
    await _nativeChannel
        .invokeMethod('startListening', {'language': _currentLanguage});
  }

  Future<void> _startWhisperGgmlProcessing() async {
    try {
      _logger.i('🎤 Starting Whisper GGML processing...');
      
      // Subscribe to audio capture service for real-time processing
      _audioCaptureService.audioStream.listen((audioData) async {
        _logger.d('🎵 Received audio chunk (${audioData.length} samples)');
        
        try {
          // Convert audio data to Uint8List for Whisper processing
          final audioBytes = Uint8List.fromList(audioData);
          _logger.d('🔄 Converting audio to bytes (${audioBytes.length} bytes)');
          
          // Process with Whisper service
          _logger.d('🎤 Sending audio to Whisper for transcription...');
          final result = await _whisperService.processAudioBuffer(audioBytes);
          
          _logger.i('📝 Whisper transcription result: "${result.text}" (confidence: ${result.confidence})');
          
          // Process the speech result
          _processSpeechResult(result);
          
        } catch (e, stackTrace) {
          _logger.e('❌ Error processing audio chunk', error: e, stackTrace: stackTrace);
        }
      }, onError: (error, stackTrace) {
        _logger.e('❌ Error in audio stream', error: error, stackTrace: stackTrace);
      });
      
      await _whisperService.startProcessing();
      _logger.i('✅ Whisper GGML processing started successfully');
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to start Whisper GGML processing', error: e, stackTrace: stackTrace);
      rethrow;
    }
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

  void _processSpeechResult(SpeechResult result) {
    _logger.d('🔄 Processing speech result: "${result.text}" (final: ${result.isFinal})');
    
    try {
      // Add to recent texts for enhancement
      if (result.text.isNotEmpty && result.text != defaultFallbackTranscript) {
        _recentTexts.add(result.text);
        if (_recentTexts.length > 10) _recentTexts.removeAt(0);
        _logger.d('📚 Added to recent texts (${_recentTexts.length} items)');
      }

      // Emit the raw speech result
      _speechResultController.add(result);
      _logger.d('📤 Emitted raw speech result to stream');

      // Try to enhance with Gemma 3n if available and enabled
      if (gemma3nService.isAvailable && _useEnhancement) {
        _logger.d('✨ Attempting Gemma 3n enhancement...');
        _enhanceWithGemma3n(result);
      } else {
        _logger.d('📝 Using raw speech result (enhancement disabled or unavailable)');
        // Create basic enhanced caption from raw result
        final basicCaption = EnhancedCaption.fromSpeechResult(result);
        _enhancedCaptionController.add(basicCaption);
        _logger.i('📋 Created basic caption: "${basicCaption.displayText}"');
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Error processing speech result', error: e, stackTrace: stackTrace);
    }
  }

  void _enhanceWithGemma3n(SpeechResult result) async {
    try {
      _logger.d('🚀 Starting Gemma 3n enhancement for: "${result.text}"');
      
      if (result.isFinal) {
        // TODO: Implement text enhancement with Gemma3nService
        // For now, use the original text
        final enhancedText = result.text;
        _logger.d('📝 Gemma 3n enhancement result: "$enhancedText"');
        
        final enhancedCaption = EnhancedCaption(
          raw: result.text,
          enhanced: enhancedText,
          isFinal: true,
          isEnhanced: false,
        );
        
        _enhancedCaptionController.add(enhancedCaption);
        _logger.i('📋 Created enhanced caption: "${enhancedCaption.displayText}"');
      } else {
        // For partial results, create a partial caption
        final partialCaption = EnhancedCaption.partial(result.text);
        _enhancedCaptionController.add(partialCaption);
        _logger.d('📋 Created partial caption: "${partialCaption.displayText}"');
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Error enhancing with Gemma 3n', error: e, stackTrace: stackTrace);
      // Fallback to basic caption
      final fallbackCaption = EnhancedCaption.fallback(result.text);
      _enhancedCaptionController.add(fallbackCaption);
      _logger.w('⚠️ Using fallback caption: "${fallbackCaption.displayText}"');
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
        case SpeechEngine.whisper_ggml:
          await _whisperService.stopProcessing();
          break;
      }

      _isProcessing = false;
      _logger.i('✅ Speech processing stopped');
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Error stopping speech processing',
          error: e, stackTrace: stackTrace);
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
  bool get hasGemmaEnhancement => gemma3nService.isAvailable;
}
