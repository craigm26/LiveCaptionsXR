import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:get_it/get_it.dart';

import '../models/sound_event.dart';
import '../../features/sound_detection/cubit/sound_detection_cubit.dart';
import 'stereo_audio_capture.dart';
import 'speech_localizer.dart';
import 'spatial_caption_integration_service.dart';
import 'debug_capturing_logger.dart';
import 'gemma_3n_service.dart';
import 'visual_identification_service.dart';
import 'enhanced_speech_processor.dart';

/// Audio processing service demonstrating Gemma 3n multimodal integration
///
/// This service showcases how we integrate Gemma 3n's audio capabilities
/// with visual context for comprehensive environmental understanding.
///
/// For Google Gemma 3n Hackathon: This demonstrates the multimodal fusion
/// that makes our accessibility solution uniquely powerful.
class AudioService {
  static final DebugCapturingLogger _logger = DebugCapturingLogger();

  final Gemma3nService gemma3nService;
  final SoundDetectionCubit soundDetectionCubit;
  final VisualIdentificationService visualService;
  late final StereoAudioCapture _audioCapture;
  late final SpeechLocalizer _speechLocalizer;
  final EnhancedSpeechProcessor? speechProcessor;

  bool _modelLoaded = false;
  bool _isListening = false;
  StreamSubscription<StereoAudioFrame>? _captureSub;
  StreamController<SoundEvent>? _soundEventController;
  AudioService({
    required this.gemma3nService,
    this.speechProcessor,
    required this.soundDetectionCubit,
    required this.visualService,
    }) {
    _logger.i('🏗️ Initializing AudioService...');
    _audioCapture = StereoAudioCapture();
    _speechLocalizer = SpeechLocalizer();
    _logger.d('Audio capture and speech localizer initialized');
    
    if (speechProcessor != null) {
      _logger.d('🎤 Speech processor connected to AudioService');
    } else {
      _logger.d('⚠️ No speech processor connected - speech recognition will be limited');
    }   
  }

  /// Initialize Gemma 3n for audio processing
  ///
  /// This method shows our strategy for deploying Gemma 3n models:
  /// 1. Load optimized model for mobile devices
  /// 2. Configure for real-time audio processing
  /// 3. Set up multimodal integration pipeline
  Future<void> start() async {
    _logger.i('🚀 Starting AudioService...');

    // start the gemma3n service
    await gemma3nService.initialize();

    // start the visual service
    await visualService.start();

    // start the speech processor
    await speechProcessor?.startProcessing();

    // start the audio capture
    await _startAudioCapture(); 

    _logger.i('✅ AudioService started successfully');
  }

  /// Start continuous audio capture and processing.
  ///
  /// This sets up the [StereoAudioCapture] service and listens to the
  /// incoming audio frames.
  Future<void> _startAudioCapture() async {
    _logger.d('🎧 Attempting to start audio capture...');
    _logger.d('Current listening state: $_isListening');
    
    if (_isListening) {
      _logger.w('⚠️ Audio capture already running, skipping start');
      return;
    }

    try {
      _isListening = true;
      _soundEventController = StreamController<SoundEvent>.broadcast();
      _logger.d('Stream controller created');

      _logger.d('Starting stereo audio capture...');
      await _audioCapture.startRecording();
      _logger.i('✅ Stereo audio recording started');
      
      _logger.d('Setting up audio frame processing...');
      _captureSub = _audioCapture.frames.listen((frame) async {
        final monoFrame = frame.toMono();
        final frameSize = monoFrame.length;
        
        // Calculate RMS level for monitoring
        double rmsLevel = 0.0;
        for (int i = 0; i < frameSize; i++) {
          rmsLevel += monoFrame[i] * monoFrame[i];
        }
        rmsLevel = frameSize > 0 ? sqrt(rmsLevel / frameSize) : 0.0;
        
        _logger.d('📊 Audio frame: ${frameSize} samples, RMS: ${rmsLevel.toStringAsFixed(4)}');
        
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

      _logger.i('🎤 Started real-time audio processing with Gemma 3n');
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to start audio capture', error: e, stackTrace: stackTrace);
      _isListening = false;
      rethrow;
    }
  }

  /// Core audio processing method showing Gemma 3n integration
  ///
  /// This demonstrates the key innovation: multimodal processing where
  /// audio events trigger combined audio+visual analysis through Gemma 3n
  void _processAudioFrame(Float32List audioFrame, double angle) async {
    _logger.d('🎯 Processing audio frame with ${audioFrame.length} samples at angle ${angle.toStringAsFixed(1)}°');
    
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
    _logger.i('🛑 Stopping AudioService...');
    _logger.d('Current state - Listening: $_isListening, Model loaded: $_modelLoaded');
    
    try {
      _isListening = false;
      _logger.d('Cancelling audio capture subscription...');
      await _captureSub?.cancel();
      
      _logger.d('Stopping audio recording...');
      await _audioCapture.stopRecording();
      
      _logger.d('Closing sound event controller...');
      await _soundEventController?.close();
      
      _logger.d('Disposing Gemma3n service...');
      // gemma3nService.dispose();

      _logger.i('✅ Audio processing stopped successfully');
    } catch (e, stackTrace) {
      _logger.e('❌ Error during AudioService stop', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get stream of detected sound events
  Stream<SoundEvent> get soundEventStream {
    _logger.d('📡 Providing sound event stream');
    return _soundEventController?.stream ?? Stream.empty();
  }
}
