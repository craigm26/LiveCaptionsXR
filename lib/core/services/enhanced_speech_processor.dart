import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:get_it/get_it.dart';
import '../models/speech_result.dart';
import '../models/speech_config.dart';
import '../models/enhanced_caption.dart';
import 'audio_capture_service.dart';
import 'gemma_3n_service.dart';
import 'whisper_service_impl.dart';
import 'apple_speech_service.dart';
import 'frame_capture_service.dart';
import 'stereo_audio_capture.dart';
import 'spatial_caption_integration_service.dart';
import 'app_logger.dart';
import 'nexa_asr_service.dart';
import 'nexa_llm_service.dart';

/// Speech processing engine types
enum SpeechEngine {
  native,
  flutter_sound,
  gemma3n,
  openAI,
  whisper_ggml,  // Android: Whisper GGML
  apple_speech,  // iOS: Apple Speech Recognition
  nexa_asr,      // Android: Nexa SDK ASR (NPU/GPU/CPU)
}

/// Enhanced service for processing speech with multiple engine support and Gemma enhancement
class EnhancedSpeechProcessor {
  final AppLogger _logger = AppLogger.instance;

  final Gemma3nService gemma3nService;
  final AudioCaptureService _audioCaptureService;
  final WhisperService _whisperService;
  final AppleSpeechService _appleSpeechService;
  final FrameCaptureService _frameCaptureService;

  // Nexa SDK services for NPU-accelerated inference
  final NexaAsrService? _nexaAsrService;
  final NexaLlmService? _nexaLlmService;
  
  // Stereo audio capture for spatial positioning
  late final StereoAudioCapture _stereoAudioCapture;
  StreamSubscription<StereoAudioFrame>? _stereoAudioSubscription;

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
  
  // Visual context
  List<int>? _latestFrame;
  StreamSubscription? _frameSubscription;
  
  // Mutex for Gemma requests to ensure only one at a time
  bool _gemmaProcessing = false;

  EnhancedSpeechProcessor({
    required this.gemma3nService,
    required AudioCaptureService audioCaptureService,
    required WhisperService whisperService,
    required AppleSpeechService appleSpeechService,
    required FrameCaptureService frameCaptureService,
    NexaAsrService? nexaAsrService,
    NexaLlmService? nexaLlmService,
    SpeechEngine? defaultEngine,
  })  : _activeEngine = defaultEngine ?? _getDefaultEngine(),
        _audioCaptureService = audioCaptureService,
        _whisperService = whisperService,
        _appleSpeechService = appleSpeechService,
        _frameCaptureService = frameCaptureService,
        _nexaAsrService = nexaAsrService,
        _nexaLlmService = nexaLlmService {
    _logger.i('🏗️ [DEBUG] EnhancedSpeechProcessor constructor called', category: LogCategory.speech);
    _logger.i('🎤 [DEBUG] AppleSpeechService instance: ${_appleSpeechService.runtimeType}', category: LogCategory.speech);
    _logger.i('🔧 [DEBUG] Active engine set to: $_activeEngine', category: LogCategory.speech);
    _logger.i('🍎 [DEBUG] Platform.isIOS: ${Platform.isIOS}', category: LogCategory.speech);
    _logger.i('🚀 [DEBUG] NexaAsrService available: ${_nexaAsrService != null}', category: LogCategory.speech);
    _logger.i('🚀 [DEBUG] NexaLlmService available: ${_nexaLlmService != null}', category: LogCategory.speech);

    // Initialize stereo audio capture for spatial positioning
    _stereoAudioCapture = StereoAudioCapture();
    _logger.i('🎧 [DEBUG] StereoAudioCapture initialized for spatial positioning', category: LogCategory.speech);
  }

  /// Get default engine based on platform
  /// On Android, prefers Nexa ASR if available for NPU acceleration
  static SpeechEngine _getDefaultEngine() {
    final logger = AppLogger.instance;
    logger.i('🔧 [DEBUG] _getDefaultEngine called', category: LogCategory.speech);
    if (Platform.isIOS) {
      logger.i('🍎 [DEBUG] iOS detected - returning apple_speech engine', category: LogCategory.speech);
      return SpeechEngine.apple_speech;
    } else if (Platform.isAndroid) {
      // Default to Nexa ASR on Android for NPU acceleration
      // Falls back to Whisper GGML if Nexa is not available
      logger.i('🤖 [DEBUG] Android detected - returning nexa_asr engine (NPU accelerated)', category: LogCategory.speech);
      return SpeechEngine.nexa_asr;
    }
    logger.i('🖥️ [DEBUG] Other platform - returning flutter_sound engine', category: LogCategory.speech);
    return SpeechEngine.flutter_sound;
  }

  List<SpeechEngine> get availableEngines {
    final engines = <SpeechEngine>[];

    // Platform-specific engines
    if (Platform.isAndroid) {
      // Android: Nexa ASR as primary (NPU accelerated)
      if (_nexaAsrService != null) {
        engines.add(SpeechEngine.nexa_asr);
      }
      // Whisper GGML as fallback
      engines.add(SpeechEngine.whisper_ggml);
    } else if (Platform.isIOS) {
      // iOS: Apple Speech as primary
      engines.add(SpeechEngine.apple_speech);
    }

    // Add fallback engines
    engines.add(SpeechEngine.flutter_sound);
    engines.add(SpeechEngine.native);

    // For Gemma3n, only add if available
    if (gemma3nService.isReady) {
      engines.add(SpeechEngine.gemma3n);
    }

    return engines;
  }

  void setActiveEngine(SpeechEngine engine) {
    if (!availableEngines.contains(engine)) {
      throw StateError('Selected ASR backend is not available: $engine');
    }
    _activeEngine = engine;
    _logger.i('🔄 User selected speech engine: $engine', category: LogCategory.speech);
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

      // Initialize unified frame capture service
      _logger.i('📸 Initializing FrameCaptureService...', category: LogCategory.camera);
      final frameInitialized = await _frameCaptureService.initialize();
      if (frameInitialized) {
        _logger.i('✅ FrameCaptureService initialized for ${_frameCaptureService.platformInfo}', category: LogCategory.camera);
        
        // On Android, we can subscribe to frame stream for continuous frames
        // On iOS, we capture frames on-demand via ARFrameService
        if (!Platform.isIOS) {
          // Note: For Android, we'd need to implement frame streaming in FrameCaptureService
          // For now, we'll capture frames on-demand for both platforms
          _logger.d('🤖 Android detected - frames will be captured on-demand', category: LogCategory.camera);
        } else {
          _logger.d('🍎 iOS detected - ARKit frames will be captured on-demand', category: LogCategory.ar);
        }
      } else {
        _logger.e('❌ Failed to initialize FrameCaptureService', category: LogCategory.camera);
      }
      
      // Initialize Gemma3n service if enhancement is enabled
      if (enableGemmaEnhancement) {
        _logger.i('🤖 Checking Gemma3n service for enhancement...', category: LogCategory.gemma);
        
        if (gemma3nService.isReady) {
          _logger.i('✅ Gemma3n service already ready (pre-initialized)', category: LogCategory.gemma);
        } else {
          _logger.i('🔄 Gemma3n service not ready, attempting initialization...', category: LogCategory.gemma);
          try {
            // Use platform-specific timeout
            final timeout = Platform.isIOS ? Duration(seconds: 60) : Duration(seconds: 120);
            _logger.i('⏱️ Initializing Gemma with ${timeout.inSeconds}s timeout for ${Platform.isIOS ? 'iOS' : 'Android'}', category: LogCategory.gemma);
            
            await gemma3nService.initialize().timeout(timeout);
            
            if (gemma3nService.isReady) {
              _logger.i('✅ Gemma3n service initialized successfully', category: LogCategory.gemma);
            } else {
              _logger.w('⚠️ Gemma3n service initialized but not ready - enhancement will be disabled', category: LogCategory.gemma);
            }
          } on TimeoutException catch (e) {
            _logger.e('⏱️ Gemma3n service initialization timed out', category: LogCategory.gemma, error: e);
            _logger.w('⚠️ Gemma enhancement will be disabled due to timeout', category: LogCategory.gemma);
          } catch (e, stackTrace) {
            _logger.e('❌ Failed to initialize Gemma3n service', category: LogCategory.gemma, error: e, stackTrace: stackTrace);
            _logger.w('⚠️ Gemma enhancement will be disabled due to error', category: LogCategory.gemma);
          }
        }
      }

      switch (_activeEngine) {
        case SpeechEngine.flutter_sound:
          await _initializeFlutterSound();
          break;
        case SpeechEngine.native:
          await _initializeNativeEngine();
          break;
        case SpeechEngine.gemma3n:
          _logger.w(
              'Gemma 3n ASR not yet implemented, falling back to flutter_sound', category: LogCategory.speech);
          _activeEngine = SpeechEngine.flutter_sound;
          await _initializeFlutterSound();
          break;
        case SpeechEngine.openAI:
          // TODO: Handle this case.
          throw UnimplementedError();
        case SpeechEngine.whisper_ggml:
          if (Platform.isIOS) {
            _logger.i('🍎 Skipping Whisper GGML initialization on iOS - using Apple Speech instead', category: LogCategory.speech);
            // Switch to Apple Speech on iOS
            _activeEngine = SpeechEngine.apple_speech;
            await _initializeAppleSpeech();
          } else {
            await _initializeWhisperGgml();
          }
          break;
        case SpeechEngine.apple_speech:
          _logger.i('🍎 [DEBUG] About to initialize Apple Speech', category: LogCategory.speech);
          await _initializeAppleSpeech();
          _logger.i('🍎 [DEBUG] Apple Speech initialization completed', category: LogCategory.speech);
          break;
        case SpeechEngine.nexa_asr:
          if (Platform.isAndroid) {
            _logger.i('🚀 [DEBUG] About to initialize Nexa ASR', category: LogCategory.speech);
            final nexaSuccess = await _initializeNexaAsr();
            if (!nexaSuccess) {
              _logger.w('⚠️ Nexa ASR initialization failed, falling back to Whisper GGML', category: LogCategory.speech);
              _activeEngine = SpeechEngine.whisper_ggml;
              await _initializeWhisperGgml();
            }
            _logger.i('🚀 [DEBUG] Nexa ASR initialization completed', category: LogCategory.speech);
          } else {
            _logger.w('⚠️ Nexa ASR only available on Android, falling back to platform default', category: LogCategory.speech);
            _activeEngine = Platform.isIOS ? SpeechEngine.apple_speech : SpeechEngine.flutter_sound;
            if (Platform.isIOS) {
              await _initializeAppleSpeech();
            } else {
              await _initializeFlutterSound();
            }
          }
          break;
      }

      if (enableGemmaEnhancement && gemma3nService.isReady) {
        _logger.i('✅ Gemma enhancement enabled', category: LogCategory.gemma);
      } else if (enableGemmaEnhancement) {
        _logger.w('⚠️ Gemma3nService not available, enhancement will be disabled.', category: LogCategory.gemma);
      }

      _isInitialized = true;
      _logger.i(
          '✅ EnhancedSpeechProcessor initialized with engine: $_activeEngine', category: LogCategory.speech);
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Error initializing EnhancedSpeechProcessor',
          category: LogCategory.speech, error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> _initializeFlutterSound() async {
    await _recorder.openRecorder();
    _logger.i('✅ FlutterSound engine initialized', category: LogCategory.speech);
  }

  Future<void> _initializeNativeEngine() async {
    await _nativeChannel.invokeMethod('initializeSpeech');
    _logger.i('✅ Native speech engine initialized', category: LogCategory.speech);
  }

  Future<void> _initializeWhisperGgml() async {
    try {
      await _whisperService.initialize(config: _config);
      _logger.i('✅ Whisper GGML engine initialized', category: LogCategory.speech);
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to initialize Whisper GGML', category: LogCategory.speech, error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  Future<void> _initializeAppleSpeech() async {
    try {
      _logger.i('🍎 [DEBUG] _initializeAppleSpeech called', category: LogCategory.speech);
      _logger.i('🍎 [DEBUG] AppleSpeechService instance check: ${_appleSpeechService != null}', category: LogCategory.speech);
      _logger.i('🍎 [DEBUG] Config: $_config', category: LogCategory.speech);

      _logger.i('🍎 [DEBUG] About to call _appleSpeechService.initialize() with 30s timeout', category: LogCategory.speech);

      await _appleSpeechService.initialize(config: _config)
          .timeout(Duration(seconds: 30), onTimeout: () {
        _logger.e('⏰ [DEBUG] AppleSpeechService.initialize() timed out after 30 seconds', category: LogCategory.speech);
        throw TimeoutException('Apple Speech initialization timed out', Duration(seconds: 30));
      });

      _logger.i('✅ Apple Speech engine initialized', category: LogCategory.speech);
      _logger.i('🍎 [DEBUG] Apple Speech isInitialized: ${_appleSpeechService.isInitialized}', category: LogCategory.speech);
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to initialize Apple Speech', category: LogCategory.speech, error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Initialize Nexa ASR service for NPU-accelerated speech recognition
  Future<bool> _initializeNexaAsr() async {
    if (_nexaAsrService == null) {
      _logger.w('⚠️ NexaAsrService not available', category: LogCategory.speech);
      return false;
    }

    try {
      _logger.i('🚀 [DEBUG] _initializeNexaAsr called', category: LogCategory.speech);

      // Check NPU availability
      final npuAvailable = await _nexaAsrService!.isNpuAvailable();
      _logger.i('🚀 [DEBUG] NPU available: $npuAvailable', category: LogCategory.speech);

      // Initialize with NPU preference
      final success = await _nexaAsrService!.initialize(
        config: _config,
        preferNpu: true,
      ).timeout(Duration(seconds: 60), onTimeout: () {
        _logger.e('⏰ [DEBUG] NexaAsrService.initialize() timed out after 60 seconds', category: LogCategory.speech);
        return false;
      });

      if (success) {
        _logger.i('✅ Nexa ASR engine initialized (mode: ${_nexaAsrService!.inferenceMode.name.toUpperCase()})', category: LogCategory.speech);

        // Also initialize Nexa LLM for text enhancement if available
        if (_nexaLlmService != null) {
          _logger.i('🚀 Initializing Nexa LLM for text enhancement...', category: LogCategory.gemma);
          try {
            await _nexaLlmService!.initialize(
              preferNpu: true,
            ).timeout(Duration(seconds: 60));
            _logger.i('✅ Nexa LLM initialized for enhancement', category: LogCategory.gemma);
          } catch (e) {
            _logger.w('⚠️ Nexa LLM initialization failed, using Gemma fallback', category: LogCategory.gemma, error: e);
          }
        }

        return true;
      } else {
        _logger.w('⚠️ Nexa ASR initialization returned false', category: LogCategory.speech);
        return false;
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to initialize Nexa ASR', category: LogCategory.speech, error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> startProcessing({SpeechConfig? config}) async {
    if (!_isInitialized) return false;
    if (_isProcessing) return true;

    try {
      if (config != null) await updateConfig(config);

      await _audioCaptureService.start();
      await _frameCaptureService.start();
      
      // Start stereo audio capture for spatial positioning
      _logger.i('🎧 [SPATIAL] Starting stereo audio capture for spatial positioning...', category: LogCategory.speech);
      await _startStereoAudioCapture();

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
        case SpeechEngine.apple_speech:
          _logger.i('🍎 [DEBUG] About to start Apple Speech processing', category: LogCategory.speech);
          await _startAppleSpeechProcessing();
          _logger.i('🍎 [DEBUG] Apple Speech processing started', category: LogCategory.speech);
          break;
        case SpeechEngine.nexa_asr:
          _logger.i('🚀 [DEBUG] About to start Nexa ASR processing', category: LogCategory.speech);
          await _startNexaAsrProcessing();
          _logger.i('🚀 [DEBUG] Nexa ASR processing started', category: LogCategory.speech);
          break;
      }

      _isProcessing = true;
      _logger.i('✅ Speech processing started with engine: $_activeEngine', category: LogCategory.speech);
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Error starting speech processing',
          category: LogCategory.speech, error: e, stackTrace: stackTrace);
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
              // Gemma3n handles visual analysis only, not audio transcription
              // Audio transcription is handled by Whisper
              _logger.w('⚠️ Gemma3n engine called for audio transcription - this should not happen', category: LogCategory.speech);
              transcript = defaultFallbackTranscript;
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
            case SpeechEngine.nexa_asr:
              // Nexa ASR uses its own streaming pipeline; flutter_sound buffer is not used
              transcript = defaultFallbackTranscript;
              break;
            case SpeechEngine.apple_speech:
              // Apple Speech uses continuous listening, not buffer processing
              // Results are handled via stream subscription
              transcript = defaultFallbackTranscript;
              break;
          }
          _processSpeechResult(SpeechResult(
            text: transcript,
            confidence: 1.0,
            isFinal: true,
            timestamp: DateTime.now(),
          ));
        } catch (e) {
          _logger.e('Error transcribing audio', category: LogCategory.speech, error: e);
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
      _logger.i('🎤 Starting Whisper GGML processing...', category: LogCategory.speech);
      
      // Subscribe to audio capture service for real-time processing
      _audioCaptureService.audioStream.listen((audioData) async {
        _logger.d('🎵 Received audio chunk (${audioData.length} samples)', category: LogCategory.speech);
        
        try {
          // Convert audio data to Uint8List for Whisper processing
          final audioBytes = Uint8List.fromList(audioData);
          _logger.d('🔄 Converting audio to bytes (${audioBytes.length} bytes)', category: LogCategory.speech);
          
          // Process with Whisper service
          _logger.d('🎤 Sending audio to Whisper for transcription...', category: LogCategory.speech);
          final result = await _whisperService.processAudioBuffer(audioBytes);
          
          _logger.i('📝 Whisper transcription result: "${result.text}" (confidence: ${result.confidence})', category: LogCategory.speech);
          
          // Process the speech result
          _processSpeechResult(result);
          
        } catch (e, stackTrace) {
          _logger.e('❌ Error processing audio chunk', category: LogCategory.speech, error: e, stackTrace: stackTrace);
        }
      }, onError: (error, stackTrace) {
        _logger.e('❌ Error in audio stream', category: LogCategory.speech, error: error, stackTrace: stackTrace);
      });
      
      await _whisperService.startProcessing();
      _logger.i('✅ Whisper GGML processing started successfully', category: LogCategory.speech);
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to start Whisper GGML processing', category: LogCategory.speech, error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  Future<void> _startAppleSpeechProcessing() async {
    try {
      _logger.i('🎤🍎 [APPLE STT] Starting Apple Speech processing...', category: LogCategory.speech);
      _logger.i('🍎 [DEBUG] Apple Speech service initialized check: ${_appleSpeechService.isInitialized}', category: LogCategory.speech);

      // Subscribe to Apple Speech results
      _appleSpeechService.speechResults.listen((result) {
        _logger.i('🎤📥 [APPLE STT] Received result from AppleSpeechService: "${result.text}" (confidence: ${result.confidence}, final: ${result.isFinal})', category: LogCategory.speech);
        _logger.i('🔄 [APPLE STT] Forwarding to _processSpeechResult...', category: LogCategory.speech);
        _processSpeechResult(result);
      }, onError: (error, stackTrace) {
        _logger.e('❌ [APPLE STT] Error in Apple Speech stream', category: LogCategory.speech, error: error, stackTrace: stackTrace);
      });

      // Start Apple Speech processing with offline mode
      bool useOfflineMode = !await _hasInternetConnection() || _config.forceOfflineMode;
      _logger.i('🎤⚙️ [APPLE STT] Starting processing with offline mode: $useOfflineMode, forceOfflineMode: ${_config.forceOfflineMode}', category: LogCategory.speech);

      _logger.i('🍎 [DEBUG] About to call _appleSpeechService.startProcessing()', category: LogCategory.speech);
      bool success = await _appleSpeechService.startProcessing(useOfflineMode: useOfflineMode);
      _logger.i('🍎 [DEBUG] _appleSpeechService.startProcessing() returned: $success', category: LogCategory.speech);

      _logger.i('✅ [APPLE STT] Apple Speech processing started successfully (offline: $useOfflineMode)', category: LogCategory.speech);
    } catch (e, stackTrace) {
      _logger.e('❌ [APPLE STT] Failed to start Apple Speech processing', category: LogCategory.speech, error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Start Nexa ASR processing for NPU-accelerated speech recognition
  Future<void> _startNexaAsrProcessing() async {
    if (_nexaAsrService == null) {
      _logger.e('❌ [NEXA STT] NexaAsrService not available', category: LogCategory.speech);
      throw StateError('NexaAsrService not available');
    }

    try {
      _logger.i('🎤🚀 [NEXA STT] Starting Nexa ASR processing...', category: LogCategory.speech);
      _logger.i('🚀 [DEBUG] Nexa ASR service initialized check: ${_nexaAsrService!.isInitialized}', category: LogCategory.speech);
      _logger.i('🚀 [DEBUG] Nexa ASR inference mode: ${_nexaAsrService!.inferenceMode.name.toUpperCase()}', category: LogCategory.speech);

      // Subscribe to Nexa ASR results
      _nexaAsrService!.speechResults.listen((result) {
        _logger.i('🎤📥 [NEXA STT] Received result from NexaAsrService: "${result.text}" (confidence: ${result.confidence}, final: ${result.isFinal})', category: LogCategory.speech);
        _logger.i('🔄 [NEXA STT] Forwarding to _processSpeechResult...', category: LogCategory.speech);
        _processSpeechResultWithNexa(result);
      }, onError: (error, stackTrace) {
        _logger.e('❌ [NEXA STT] Error in Nexa ASR stream', category: LogCategory.speech, error: error, stackTrace: stackTrace);
      });

      // Subscribe to audio capture and feed to Nexa ASR
      _audioCaptureService.audioStream.listen((audioData) async {
        _logger.d('🎵 [NEXA STT] Received audio chunk (${audioData.length} samples)', category: LogCategory.speech);

        try {
          // Convert audio data to Uint8List for Nexa processing
          final audioBytes = Uint8List.fromList(audioData);
          _logger.d('🔄 [NEXA STT] Converting audio to bytes (${audioBytes.length} bytes)', category: LogCategory.speech);

          // Process with Nexa ASR service
          _logger.d('🎤 [NEXA STT] Sending audio to Nexa ASR for transcription...', category: LogCategory.speech);
          await _nexaAsrService!.processAudioBuffer(audioBytes);

        } catch (e, stackTrace) {
          _logger.e('❌ [NEXA STT] Error processing audio chunk', category: LogCategory.speech, error: e, stackTrace: stackTrace);
        }
      }, onError: (error, stackTrace) {
        _logger.e('❌ [NEXA STT] Error in audio stream', category: LogCategory.speech, error: error, stackTrace: stackTrace);
      });

      // Start Nexa ASR streaming
      bool success = await _nexaAsrService!.startProcessing();
      _logger.i('🚀 [DEBUG] _nexaAsrService.startProcessing() returned: $success', category: LogCategory.speech);

      _logger.i('✅ [NEXA STT] Nexa ASR processing started successfully (mode: ${_nexaAsrService!.inferenceMode.name.toUpperCase()})', category: LogCategory.speech);
    } catch (e, stackTrace) {
      _logger.e('❌ [NEXA STT] Failed to start Nexa ASR processing', category: LogCategory.speech, error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Process speech result with Nexa-specific enhancement
  void _processSpeechResultWithNexa(SpeechResult result) {
    _logger.d('🔄📥 [NEXA PROCESSING] Received speech result: "${result.text}" (final: ${result.isFinal}, confidence: ${result.confidence})', category: LogCategory.speech);

    try {
      // Add to recent texts for enhancement
      if (result.text.isNotEmpty && result.text != defaultFallbackTranscript) {
        _recentTexts.add(result.text);
        if (_recentTexts.length > 10) _recentTexts.removeAt(0);
        _logger.d('📚 [NEXA PROCESSING] Added to recent texts (${_recentTexts.length} items)', category: LogCategory.speech);
      }

      // Emit the raw speech result
      _speechResultController.add(result);
      _logger.d('📤 [NEXA PROCESSING] Emitted raw speech result to speechResults stream', category: LogCategory.speech);

      // Try to enhance with Nexa LLM first, then fall back to Gemma
      if (_nexaLlmService != null && _nexaLlmService!.isReady && _useEnhancement) {
        _logger.i('✨ [NEXA PROCESSING] Nexa LLM available - attempting enhancement...', category: LogCategory.speech);
        _enhanceWithNexaLlm(result);
      } else if (gemma3nService.isReady && _useEnhancement) {
        _logger.i('✨ [NEXA PROCESSING] Falling back to Gemma3n for enhancement...', category: LogCategory.speech);
        _enhanceWithGemma3n(result);
      } else {
        _logger.d('📝 [NEXA PROCESSING] Using raw speech result (nexa llm ready: ${_nexaLlmService?.isReady}, gemma ready: ${gemma3nService.isReady}, enhancement enabled: $_useEnhancement)', category: LogCategory.speech);
        // Create basic enhanced caption from raw result
        final basicCaption = EnhancedCaption.fromSpeechResult(result);
        _enhancedCaptionController.add(basicCaption);
        _logger.d('📋➡️ [NEXA PROCESSING] Created and emitted basic caption: "${basicCaption.displayText}"', category: LogCategory.speech);
      }
    } catch (e, stackTrace) {
      _logger.e('❌ [NEXA PROCESSING] Error processing speech result', category: LogCategory.speech, error: e, stackTrace: stackTrace);
    }
  }

  /// Enhance speech result with Nexa LLM for NPU-accelerated text enhancement
  void _enhanceWithNexaLlm(SpeechResult result) async {
    try {
      _logger.d('🚀 Starting Nexa LLM enhancement for: "${result.text}"', category: LogCategory.gemma);

      if (result.isFinal) {
        // Check if Gemma/Nexa is already processing
        if (_gemmaProcessing) {
          _logger.w('⚠️ Enhancement already processing another request, skipping: "${result.text}"', category: LogCategory.gemma);
          final basicCaption = EnhancedCaption.fromSpeechResult(result);
          _enhancedCaptionController.add(basicCaption);
          return;
        }

        // Set mutex
        _gemmaProcessing = true;
        _logger.d('🔒 Enhancement mutex acquired for: "${result.text}"', category: LogCategory.gemma);

        try {
          // Use multimodal enhancement with visual context if available
          String enhancedText;
          List<int>? currentFrame = await _getCurrentFrame();

          if (currentFrame != null && _nexaLlmService!.supportsVision) {
            _logger.d('🎥 Using visual context for Nexa LLM enhancement (${currentFrame.length} bytes)', category: LogCategory.gemma);
            enhancedText = await _nexaLlmService!.enhanceTextWithVisualContext(
              text: result.text,
              imageData: Uint8List.fromList(currentFrame),
            );
          } else {
            _logger.d('📝 Using text-only Nexa LLM enhancement', category: LogCategory.gemma);
            enhancedText = await _nexaLlmService!.enhanceText(result.text);
          }

          _logger.d('✨ Nexa LLM enhancement result: "$enhancedText"', category: LogCategory.gemma);

          final enhancedCaption = EnhancedCaption(
            raw: result.text,
            enhanced: enhancedText,
            isFinal: true,
            isEnhanced: enhancedText != result.text,
          );

          _enhancedCaptionController.add(enhancedCaption);
          _logger.i('📋 Created Nexa-enhanced caption: "${enhancedCaption.displayText}"', category: LogCategory.gemma);
        } finally {
          _gemmaProcessing = false;
          _logger.d('🔓 Enhancement mutex released', category: LogCategory.gemma);
        }
      } else {
        // For partial results, create a partial caption
        final partialCaption = EnhancedCaption.partial(result.text);
        _enhancedCaptionController.add(partialCaption);
        _logger.d('📋 Created partial caption: "${partialCaption.displayText}"', category: LogCategory.gemma);
      }
    } catch (e, stackTrace) {
      _gemmaProcessing = false;
      _logger.e('❌ Error enhancing with Nexa LLM', category: LogCategory.gemma, error: e, stackTrace: stackTrace);

      // Fallback to basic caption
      final fallbackCaption = EnhancedCaption.fallback(result.text);
      _enhancedCaptionController.add(fallbackCaption);
      _logger.w('⚠️ Using fallback caption: "${fallbackCaption.displayText}"', category: LogCategory.gemma);
    }
  }
  
  /// Start stereo audio capture for spatial positioning
  Future<void> _startStereoAudioCapture() async {
    try {
      _logger.i('🎧 [SPATIAL] Starting stereo audio recording...', category: LogCategory.speech);
      await _stereoAudioCapture.startRecording();
      _logger.i('✅ [SPATIAL] Stereo audio recording started', category: LogCategory.speech);
      
      // Listen to stereo audio frames and feed them to spatial caption service
      _stereoAudioSubscription = _stereoAudioCapture.frames.listen((frame) {
        try {
          _logger.d('🎧 [SPATIAL] Received stereo frame: L=${frame.left.length}, R=${frame.right.length} samples', category: LogCategory.speech);
          
          // Feed audio frame to spatial caption integration service
          final spatialService = GetIt.I<SpatialCaptionIntegrationService>();
          spatialService.updateAudioFrame(frame);
          _logger.d('📍 [SPATIAL] Audio frame sent to spatial caption integration', category: LogCategory.speech);
        } catch (e) {
          _logger.w('⚠️ [SPATIAL] Could not update spatial caption service: $e', category: LogCategory.speech);
        }
      });
      
      _logger.i('🎧 [SPATIAL] Stereo audio processing setup complete', category: LogCategory.speech);
    } catch (e, stackTrace) {
      _logger.e('❌ [SPATIAL] Failed to start stereo audio capture', category: LogCategory.speech, error: e, stackTrace: stackTrace);
      // Don't rethrow - spatial audio is optional, main speech processing should continue
    }
  }
  
  /// Stop stereo audio capture
  Future<void> _stopStereoAudioCapture() async {
    try {
      _logger.i('🛑 [SPATIAL] Stopping stereo audio capture...', category: LogCategory.speech);
      
      // Cancel subscription
      await _stereoAudioSubscription?.cancel();
      _stereoAudioSubscription = null;
      
      // Stop recording
      await _stereoAudioCapture.stopRecording();
      
      _logger.i('✅ [SPATIAL] Stereo audio capture stopped', category: LogCategory.speech);
    } catch (e, stackTrace) {
      _logger.e('❌ [SPATIAL] Error stopping stereo audio capture', category: LogCategory.speech, error: e, stackTrace: stackTrace);
    }
  }
  
  /// Check if device has internet connection
  Future<bool> _hasInternetConnection() async {
    try {
      // Simple connectivity check - you might want to use connectivity_plus package
      return true; // For now, assume connection is available
    } catch (e) {
      return false;
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
    _logger.d('🔄📥 [STT PROCESSING] Received speech result: "${result.text}" (final: ${result.isFinal}, confidence: ${result.confidence})', category: LogCategory.speech);
    
    try {
      // Add to recent texts for enhancement
      if (result.text.isNotEmpty && result.text != defaultFallbackTranscript) {
        _recentTexts.add(result.text);
        if (_recentTexts.length > 10) _recentTexts.removeAt(0);
        _logger.d('📚 [STT PROCESSING] Added to recent texts (${_recentTexts.length} items)', category: LogCategory.speech);
      }

      // Emit the raw speech result
      _speechResultController.add(result);
      _logger.d('📤 [STT PROCESSING] Emitted raw speech result to speechResults stream', category: LogCategory.speech);

      // Try to enhance with Gemma 3n if available and enabled
      if (gemma3nService.isReady && _useEnhancement) {
        _logger.i('✨ [STT PROCESSING] Gemma3n available - attempting enhancement...', category: LogCategory.speech);
        _enhanceWithGemma3n(result);
      } else {
        _logger.d('📝 [STT PROCESSING] Using raw speech result (gemma ready: ${gemma3nService.isReady}, enhancement enabled: $_useEnhancement)', category: LogCategory.speech);
        // Create basic enhanced caption from raw result
        final basicCaption = EnhancedCaption.fromSpeechResult(result);
        _enhancedCaptionController.add(basicCaption);
        _logger.d('📋➡️ [STT PROCESSING] Created and emitted basic caption: "${basicCaption.displayText}"', category: LogCategory.speech);
      }
    } catch (e, stackTrace) {
      _logger.e('❌ [STT PROCESSING] Error processing speech result', category: LogCategory.speech, error: e, stackTrace: stackTrace);
    }
  }

  void _enhanceWithGemma3n(SpeechResult result) async {
    try {
      _logger.d('🚀 Starting Gemma 3n enhancement for: "${result.text}"', category: LogCategory.gemma);
      
      if (result.isFinal) {
        // Check if Gemma is already processing
        if (_gemmaProcessing) {
          _logger.w('⚠️ Gemma already processing another request, skipping: "${result.text}"', category: LogCategory.gemma);
          // Create basic caption without enhancement
          final basicCaption = EnhancedCaption.fromSpeechResult(result);
          _enhancedCaptionController.add(basicCaption);
          return;
        }
        
        // Set mutex and block STT auto-restart during Gemma inference
        _gemmaProcessing = true;
        _logger.d('🔒 Gemma mutex acquired for: "${result.text}"', category: LogCategory.gemma);
        
        // Allow STT to continue running during Gemma inference - no blocking
        // _appleSpeechService.blockAutoRestart();
        _logger.d('▶️ STT continues running during Gemma inference (no blocking)', category: LogCategory.gemma);
        
        try {
          // Use multimodal enhancement with visual context if available
          String enhancedText;
          _logger.d('🚀 Restoring frame capture to test with images (old working behavior)...', category: LogCategory.gemma);
          List<int>? currentFrame = await _getCurrentFrame();
          // List<int>? currentFrame = null; // Force text-only for testing
          if (currentFrame != null) {
            _logger.d('🎥 Using visual context for enhancement (${currentFrame.length} bytes)', category: LogCategory.gemma);
            _logger.d('🧠 Calling gemma3nService.enhanceTextWithVisualContext...', category: LogCategory.gemma);
            enhancedText = await gemma3nService.enhanceTextWithVisualContext(
              text: result.text,
              imageData: Uint8List.fromList(currentFrame),
            );
            _logger.d('✅ enhanceTextWithVisualContext completed', category: LogCategory.gemma);
          } else {
            _logger.d('📝 Using text-only enhancement (no frame available)', category: LogCategory.gemma);
            _logger.d('🧠 Calling gemma3nService.enhanceText...', category: LogCategory.gemma);
            enhancedText = await gemma3nService.enhanceText(result.text);
            _logger.d('✅ enhanceText completed', category: LogCategory.gemma);
          }
          
          _logger.d('✨ Enhancement result: "$enhancedText"', category: LogCategory.gemma);
          
          final enhancedCaption = EnhancedCaption(
            raw: result.text,
            enhanced: enhancedText,
            isFinal: true,
            isEnhanced: enhancedText != result.text, // Mark as enhanced if text changed
          );
          
          _enhancedCaptionController.add(enhancedCaption);
          _logger.i('📋 Created enhanced caption: "${enhancedCaption.displayText}"', category: LogCategory.gemma);
        } finally {
          // Release mutex and unblock STT auto-restart
          _gemmaProcessing = false;
          _logger.d('🔓 Gemma mutex released', category: LogCategory.gemma);
          
          // STT was never blocked, so no need to unblock
          // _appleSpeechService.unblockAutoRestart(restartImmediately: true);
          _logger.d('▶️ STT was running continuously during Gemma inference', category: LogCategory.gemma);
        }
      } else {
        // For partial results, create a partial caption
        final partialCaption = EnhancedCaption.partial(result.text);
        _enhancedCaptionController.add(partialCaption);
        _logger.d('📋 Created partial caption: "${partialCaption.displayText}"', category: LogCategory.gemma);
      }
    } catch (e, stackTrace) {
      // Ensure mutex is released on error (STT was never blocked)
      _gemmaProcessing = false;
      // _appleSpeechService.unblockAutoRestart(restartImmediately: true);
      _logger.e('❌ Error enhancing with Gemma 3n', category: LogCategory.gemma, error: e, stackTrace: stackTrace);
      _logger.d('▶️ STT was running continuously during Gemma error', category: LogCategory.gemma);
      
      // Fallback to basic caption
      final fallbackCaption = EnhancedCaption.fallback(result.text);
      _enhancedCaptionController.add(fallbackCaption);
      _logger.w('⚠️ Using fallback caption: "${fallbackCaption.displayText}"', category: LogCategory.gemma);
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
        case SpeechEngine.apple_speech:
          await _appleSpeechService.stopProcessing();
          break;
        case SpeechEngine.nexa_asr:
          await _nexaAsrService?.stopProcessing();
          break;
      }

      // Stop stereo audio capture
      await _stopStereoAudioCapture();
      
      await _frameCaptureService.stop();
      _isProcessing = false;
      _logger.i('✅ Speech processing stopped', category: LogCategory.speech);
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Error stopping speech processing',
          category: LogCategory.speech, error: e, stackTrace: stackTrace);
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
    _logger.i('🔄 Switched to speech engine: $engine', category: LogCategory.speech);

    _isInitialized = false;
    return await initialize(config: _config);
  }

  Future<void> updateConfig(SpeechConfig newConfig) async {
    _config = newConfig;
    _currentLanguage = newConfig.language;
  }

  void dispose() {
    stopProcessing();
    _frameSubscription?.cancel();
    _frameCaptureService.dispose();
    _speechResultController.close();
    _enhancedCaptionController.close();
  }

  /// Get current frame for visual context using unified FrameCaptureService
  Future<List<int>?> _getCurrentFrame() async {
    _logger.d('📸 Capturing frame via FrameCaptureService...', category: LogCategory.camera);
    try {
      // Add timeout to frame capture to prevent hanging
      final frameData = await _frameCaptureService.captureFrame().timeout(
        Duration(seconds: 5),
        onTimeout: () {
          _logger.w('⏱️ Frame capture timed out after 5 seconds', category: LogCategory.camera);
          return null;
        },
      );
      if (frameData != null) {
        _logger.d('✅ Frame captured: ${frameData.length} bytes', category: LogCategory.camera);
        return frameData;
      } else {
        _logger.w('⚠️ Frame capture returned null', category: LogCategory.camera);
        return null;
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to capture frame', category: LogCategory.camera, error: e, stackTrace: stackTrace);
      return null;
    }
  }

  bool get isReady => _isInitialized;
  bool get isProcessing => _isProcessing;
  SpeechEngine get activeEngine => _activeEngine;
  bool get hasGemmaEnhancement => gemma3nService.isReady;
  bool get hasNexaEnhancement => _nexaLlmService?.isReady ?? false;
  bool get hasEnhancement => hasNexaEnhancement || hasGemmaEnhancement;
  bool get isNpuAccelerated => _nexaAsrService?.isNpuAccelerated ?? false;
  NexaInferenceMode? get nexaInferenceMode => _nexaAsrService?.inferenceMode;
}
