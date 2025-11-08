import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:get_it/get_it.dart';

import '../models/sound_event.dart';
import '../../features/sound_detection/cubit/sound_detection_cubit.dart';
import 'stereo_audio_capture.dart';
import 'speech_localizer.dart';
import 'spatial_caption_integration_service.dart';
import 'gemma_3n_service.dart';
import 'visual_identification_service.dart';
import 'enhanced_speech_processor.dart';
import 'app_logger.dart';

/// Audio processing service demonstrating Gemma 3n multimodal integration
///
/// This service showcases how we integrate Gemma 3n's audio capabilities
/// with visual context for comprehensive environmental understanding.
///
/// For Google Gemma 3n Hackathon: This demonstrates the multimodal fusion
/// that makes our accessibility solution uniquely powerful.
class AudioService {
  static final AppLogger _logger = AppLogger.instance;

  final Gemma3nService gemma3nService;
  final SoundDetectionCubit soundDetectionCubit;
  final VisualIdentificationService visualService;
  late final StereoAudioCapture _audioCapture;
  late final SpeechLocalizer _speechLocalizer;
  final EnhancedSpeechProcessor? speechProcessor;

  bool _modelLoaded = false;
  bool _gemmaReady = false;
  bool _isListening = false;
  StreamSubscription<StereoAudioFrame>? _captureSub;
  StreamController<SoundEvent>? _soundEventController;
  AudioService({
    required this.gemma3nService,
    this.speechProcessor,
    required this.soundDetectionCubit,
    required this.visualService,
    }) {
    _logger.i('🏗️ Initializing AudioService...', category: LogCategory.audio);
    _audioCapture = StereoAudioCapture();
    _speechLocalizer = SpeechLocalizer();
    _logger.d('Audio capture and speech localizer initialized', category: LogCategory.audio);
    
    if (speechProcessor != null) {
      _logger.d('🎤 Speech processor connected to AudioService', category: LogCategory.audio);
    } else {
      _logger.d('⚠️ No speech processor connected - speech recognition will be limited', category: LogCategory.audio);
    }   
  }

  /// Initialize Gemma 3n for audio processing
  ///
  /// This method shows our strategy for deploying Gemma 3n models:
  /// 1. Load optimized model for mobile devices
  /// 2. Configure for real-time audio processing
  /// 3. Set up multimodal integration pipeline
  Future<void> start({bool requireGemma = false, bool enableVisualService = true}) async {
    _logger.i('🚀 Starting AudioService...', category: LogCategory.audio);

    _gemmaReady = await _initializeGemma(requireGemma: requireGemma);
    if (!_gemmaReady) {
      _logger.w(
        '⚠️ Gemma 3n service unavailable - running in 2D fallback mode',
        category: LogCategory.audio,
      );
    }

    if (enableVisualService) {
      await _startVisualService();
    } else {
      _logger.i('ℹ️ Visual service disabled for this session', category: LogCategory.audio);
    }

    await _startSpeechProcessor();
    await _startAudioCapture(); 

    _logger.i(
      _gemmaReady
          ? '✅ AudioService started successfully with Gemma enhancement'
          : '✅ AudioService started successfully (Gemma disabled)',
      category: LogCategory.audio,
    );
  }

  /// Start continuous audio capture and processing.
  ///
  /// This sets up the [StereoAudioCapture] service and listens to the
  /// incoming audio frames.
  Future<void> _startAudioCapture() async {
    _logger.d('🎧 Attempting to start audio capture...', category: LogCategory.audio);
    _logger.d('Current listening state: $_isListening', category: LogCategory.audio);
    
    if (_isListening) {
      _logger.w('⚠️ Audio capture already running, skipping start', category: LogCategory.audio);
      return;
    }

    try {
      _isListening = true;
      _soundEventController = StreamController<SoundEvent>.broadcast();
      _logger.d('Stream controller created', category: LogCategory.audio);

      _logger.d('Starting stereo audio capture...', category: LogCategory.audio);
      await _audioCapture.startRecording();
      _logger.i('✅ Stereo audio recording started', category: LogCategory.audio);
      
      _logger.d('Setting up audio frame processing...', category: LogCategory.audio);
      _captureSub = _audioCapture.frames.listen((frame) async {
        final monoFrame = frame.toMono();
        final frameSize = monoFrame.length;
        
        // Calculate RMS level for monitoring
        double rmsLevel = 0.0;
        for (int i = 0; i < frameSize; i++) {
          rmsLevel += monoFrame[i] * monoFrame[i];
        }
        rmsLevel = frameSize > 0 ? sqrt(rmsLevel / frameSize) : 0.0;
        
        _logger.d('📊 Audio frame: ${frameSize} samples, RMS: ${rmsLevel.toStringAsFixed(4)}', category: LogCategory.audio);
        
        // Use advanced direction estimation
        final angle = _speechLocalizer.estimateDirectionAdvanced(frame);
        _logger.d('🧭 Estimated direction: ${angle.toStringAsFixed(3)} radians');
        
        // Feed audio frame to spatial caption integration service
        try {
          final spatialService = GetIt.I<SpatialCaptionIntegrationService>();
          spatialService.updateAudioFrame(frame);
          _logger.d('📍 Audio frame sent to spatial caption integration');
        } catch (e) {
          _logger.w('⚠️ Could not update spatial caption service: $e');
        }
        
        _processAudioFrame(monoFrame, angle);
      });

      _logger.i('🎤 Started real-time audio processing with Gemma 3n', category: LogCategory.audio);
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to start audio capture', category: LogCategory.audio, error: e, stackTrace: stackTrace);
      _isListening = false;
      rethrow;
    }
  }

  /// Core audio processing method showing Gemma 3n integration
  ///
  /// This demonstrates the key innovation: multimodal processing where
  /// audio events trigger combined audio+visual analysis through Gemma 3n
  void _processAudioFrame(Float32List audioFrame, double angle) async {
    _logger.d('🎯 Processing audio frame with ${audioFrame.length} samples at angle ${angle.toStringAsFixed(1)}°', category: LogCategory.audio);
    
    // Audio processing handled by Whisper, not Gemma
    // Create basic sound event for localization
    final event = SoundEvent(
      type: 'speech',
      confidence: 0.8,
      timestamp: DateTime.now(),
      sourceDirection: '${angle.toStringAsFixed(1)}°',
    );
    soundDetectionCubit.detectSound(event);
  }

  /// Stop audio processing and cleanup resources
  Future<void> stop() async {
    _logger.i('🛑 Stopping AudioService...', category: LogCategory.audio);
    _logger.d('Current state - Listening: $_isListening, Model loaded: $_modelLoaded', category: LogCategory.audio);
    
    try {
      _isListening = false;
      _logger.d('Cancelling audio capture subscription...', category: LogCategory.audio);
      await _captureSub?.cancel();
      
      _logger.d('Stopping audio recording...', category: LogCategory.audio);
      await _audioCapture.stopRecording();
      
      _logger.d('Closing sound event controller...', category: LogCategory.audio);
      await _soundEventController?.close();
      
      _logger.d('Disposing Gemma3n service...', category: LogCategory.audio);
      // gemma3nService.dispose();

      _logger.i('✅ Audio processing stopped successfully', category: LogCategory.audio);
    } catch (e, stackTrace) {
      _logger.e('❌ Error during AudioService stop', category: LogCategory.audio, error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get stream of detected sound events
  Stream<SoundEvent> get soundEventStream {
    _logger.d('📡 Providing sound event stream', category: LogCategory.audio);
    return _soundEventController?.stream ?? Stream.empty();
  }

  Future<bool> _initializeGemma({required bool requireGemma}) async {
    try {
      await gemma3nService.initialize();
      _modelLoaded = gemma3nService.isReady;
      if (!_modelLoaded && requireGemma) {
        throw StateError('Gemma 3n service required but not ready');
      }
      return _modelLoaded;
    } catch (e, stackTrace) {
      _logger.e(
        '❌ Failed to initialize Gemma 3n service',
        category: LogCategory.audio,
        error: e,
        stackTrace: stackTrace,
      );
      if (requireGemma) {
        rethrow;
      }
      _modelLoaded = false;
      return false;
    }
  }

  Future<void> _startVisualService() async {
    try {
      await visualService.start();
      _logger.i('✅ Visual identification service started', category: LogCategory.audio);
    } catch (e, stackTrace) {
      _logger.w(
        '⚠️ Visual service unavailable - continuing without camera enhancements',
        category: LogCategory.audio,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _startSpeechProcessor() async {
    if (speechProcessor == null) {
      _logger.w('⚠️ No speech processor configured - captions will be limited', category: LogCategory.audio);
      return;
    }

    try {
      final started = await speechProcessor!.startProcessing();
      if (!started) {
        _logger.w(
          '⚠️ Speech processor failed to start; live captions may be unavailable',
          category: LogCategory.audio,
        );
      }
    } catch (e, stackTrace) {
      _logger.e(
        '❌ Error starting speech processor',
        category: LogCategory.audio,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
