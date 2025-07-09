import 'dart:async';
import 'dart:typed_data';
import 'dart:math' show sqrt;
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../core/services/speech_processor.dart';
import '../../../core/services/stereo_audio_capture.dart';
import '../../../core/services/hybrid_localization_engine.dart';
import '../../../core/models/speech_result.dart';
import 'live_captions_state.dart';

/// Cubit for managing live captions functionality
class LiveCaptionsCubit extends Cubit<LiveCaptionsState> {
  final SpeechProcessor _speechProcessor;
  final HybridLocalizationEngine _hybridLocalizationEngine;
  final StereoAudioCapture _audioCapture = StereoAudioCapture();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  StreamSubscription<SpeechResult>? _speechSubscription;
  StreamSubscription? _audioSubscription;
  final List<SpeechResult> _captionHistory = [];
  static const int _maxCaptionHistory = 50; // Keep last 50 captions
  int _audioFrameCount = 0;

  LiveCaptionsCubit({
    required SpeechProcessor speechProcessor,
    required HybridLocalizationEngine hybridLocalizationEngine,
  })  : _speechProcessor = speechProcessor,
        _hybridLocalizationEngine = hybridLocalizationEngine,
        super(const LiveCaptionsInitial());

  /// Initialize the speech processor and prepare for live captions
  Future<void> initialize() async {
    try {
      _logger.i('🎤 Initializing LiveCaptionsCubit...');
      emit(const LiveCaptionsLoading());

      final success = await _speechProcessor.initialize();

      if (success) {
        _logger.i('✅ LiveCaptionsCubit initialized successfully');
        emit(const LiveCaptionsActive(
          captions: [],
          isListening: false,
        ));
      } else {
        _logger.e('❌ Failed to initialize speech processor');
        emit(const LiveCaptionsError(
          message: 'Failed to initialize speech processing',
          details: 'Could not load the speech recognition model',
        ));
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Error initializing LiveCaptionsCubit',
          error: e, stackTrace: stackTrace);
      emit(LiveCaptionsError(
        message: 'Initialization error: ${e.toString()}',
        details: stackTrace.toString(),
      ));
    }
  }

  /// Start live caption processing
  Future<void> startCaptions() async {
    final currentState = state;
    if (currentState is! LiveCaptionsActive) {
      _logger.w('⚠️ Cannot start captions - not in active state');
      return;
    }

    if (currentState.isListening) {
      _logger.w('⚠️ Captions already running');
      return;
    }

    try {
      _logger.i('🎤 Starting live captions...');

      // Start speech processing first
      final success = await _speechProcessor.startProcessing();

      if (success) {
        // Subscribe to speech results
        _speechSubscription = _speechProcessor.speechResults.listen(
          _handleSpeechResult,
          onError: _handleSpeechError,
        );

        // Start audio capture and connect it to speech processor
        _logger.i('🎧 Starting audio capture for speech processing...');
        await _startAudioCapture();

        emit(currentState.copyWith(isListening: true, error: null));
        _logger.i('✅ Live captions started with audio capture');
      } else {
        _logger.e('❌ Failed to start speech processing');
        emit(currentState.copyWith(
          error: 'Failed to start speech processing',
        ));
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Error starting live captions',
          error: e, stackTrace: stackTrace);
      emit(currentState.copyWith(
        error: 'Error starting captions: ${e.toString()}',
      ));
    }
  }

  /// Start audio capture and connect it to speech processor
  Future<void> _startAudioCapture() async {
    try {
      _logger.i('🎧 Starting stereo audio capture...');
      await _audioCapture.startRecording();
      _logger.i('✅ Audio capture started successfully');

      _audioFrameCount = 0;
      _audioSubscription = _audioCapture.frames.listen((frame) async {
        _audioFrameCount++;
        final monoFrame = frame.toMono();
        final frameSize = monoFrame.length;

        // Calculate RMS level for monitoring
        double rmsLevel = 0.0;
        for (int i = 0; i < frameSize; i++) {
          rmsLevel += monoFrame[i] * monoFrame[i];
        }
        rmsLevel = frameSize > 0 ? sqrt(rmsLevel / frameSize) : 0.0;

        // Log detailed audio info periodically
        if (_audioFrameCount % 50 == 0) {
          _logger.d('📊 Audio frame #$_audioFrameCount: ${frameSize} samples, RMS: ${rmsLevel.toStringAsFixed(4)}');
        }

        // Send audio chunk to speech processor
        try {
          await _speechProcessor.processAudioChunk(monoFrame);
          if (_audioFrameCount % 50 == 0) {
            _logger.d('✅ Audio chunk sent to speech processor');
          }
        } catch (e) {
          _logger.e('❌ Failed to send audio chunk to speech processor: $e');
        }
      });

      _logger.i('🎤 Audio capture connected to speech processor');
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to start audio capture', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Stop live caption processing
  Future<void> stopCaptions() async {
    final currentState = state;
    if (currentState is! LiveCaptionsActive) {
      return;
    }

    try {
      _logger.i('🛑 Stopping live captions...');

      // Stop audio capture first
      await _audioSubscription?.cancel();
      _audioSubscription = null;
      await _audioCapture.stopRecording();
      _logger.i('✅ Audio capture stopped');

      // Stop speech processing
      await _speechSubscription?.cancel();
      _speechSubscription = null;
      await _speechProcessor.stopProcessing();

      emit(currentState.copyWith(
        isListening: false,
        currentCaption: null,
        error: null,
      ));

      _logger.i('✅ Live captions stopped - processed $_audioFrameCount audio frames');
    } catch (e, stackTrace) {
      _logger.e('❌ Error stopping live captions',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Clear caption history
  void clearCaptions() {
    final currentState = state;
    if (currentState is LiveCaptionsActive) {
      _captionHistory.clear();
      emit(currentState.copyWith(
        captions: [],
        currentCaption: null,
        error: null,
      ));
      _logger.d('🗑️ Caption history cleared');
    }
  }

  /// Handle incoming speech results
  void _handleSpeechResult(SpeechResult result) {
    final currentState = state;
    if (currentState is! LiveCaptionsActive) {
      return;
    }

    try {
      _logger.d(
          '🎤 Received speech result: "${result.text}" (confidence: ${result.confidence})');

      if (result.isFinal) {
        // Add to caption history
        _captionHistory.add(result);

        // Keep only the last N captions
        if (_captionHistory.length > _maxCaptionHistory) {
          _captionHistory.removeAt(0);
        }

        // Update state with new caption
        emit(currentState.copyWith(
          captions: List.from(_captionHistory),
          currentCaption: null, // Clear current since it's now final
          error: null,
        ));

        _logger.i('📝 Final caption added: "${result.text}"');
        
        // Place caption in AR space if text is not empty
        if (result.text.trim().isNotEmpty) {
          _placeCaptionInAR(result.text.trim());
        }
      } else {
        // Update current caption (interim result)
        emit(currentState.copyWith(
          currentCaption: result,
          error: null,
        ));

        _logger.d('🔄 Interim caption: "${result.text}"');
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Error handling speech result',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Place caption in AR space using the injected hybrid localization engine
  void _placeCaptionInAR(String text) {
    // Only place captions if we're in an active state
    final currentState = state;
    if (currentState is! LiveCaptionsActive) {
      _logger.d('⚠️ Skipping caption placement - not in active state');
      return;
    }
    
    _logger.i('🎯 Attempting to place caption in AR space...');
    _logger.d('Caption text: "$text" (${text.length} characters)');
    
    // Run caption placement asynchronously so it doesn't block UI updates
    Future.microtask(() async {
      try {
        _logger.d('🔄 Requesting fused transform from hybrid localization...');
        
        // Use the injected hybrid localization engine
        await _hybridLocalizationEngine.placeCaption(text);
        
        _logger.i('✅ Caption placed successfully in AR space at estimated speaker location');
      } catch (e, stackTrace) {
        _logger.e('❌ Failed to place caption in AR', 
            error: e, stackTrace: stackTrace);
        // Don't update UI state with this error as caption placement 
        // failures shouldn't break the main captions functionality
      }
    });
  }

  /// Handle speech processing errors
  void _handleSpeechError(dynamic error) {
    _logger.e('🚨 Speech processing error: $error');

    final currentState = state;
    if (currentState is LiveCaptionsActive) {
      emit(currentState.copyWith(
        error: 'Speech processing error: ${error.toString()}',
      ));
    }
  }

  /// Get the latest caption text for display
  String? get latestCaptionText {
    final currentState = state;
    if (currentState is LiveCaptionsActive) {
      // Return current interim caption if available, otherwise latest final caption
      if (currentState.currentCaption != null) {
        return currentState.currentCaption!.text;
      } else if (currentState.captions.isNotEmpty) {
        return currentState.captions.last.text;
      }
    }
    return null;
  }

  /// Get caption history for display
  List<SpeechResult> get captionHistory {
    final currentState = state;
    if (currentState is LiveCaptionsActive) {
      return List.from(currentState.captions);
    }
    return [];
  }

  /// Check if captions are currently active
  bool get isActive {
    final currentState = state;
    return currentState is LiveCaptionsActive && currentState.isListening;
  }

  /// Handle speech result for testing purposes
  @visibleForTesting
  void handleSpeechResult(SpeechResult result) {
    _handleSpeechResult(result);
  }

  @override
  Future<void> close() async {
    _logger.i('🗑️ Disposing LiveCaptionsCubit...');

    await stopCaptions();
    await _speechProcessor.dispose();

    _logger.d('✅ LiveCaptionsCubit disposed');
    return super.close();
  }
}
