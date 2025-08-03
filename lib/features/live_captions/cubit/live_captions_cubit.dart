import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/enhanced_caption.dart';
import '../../../core/models/speech_result.dart';
import '../../../core/models/speech_config.dart';
import '../../../core/services/enhanced_speech_processor.dart';
import '../../../core/services/hybrid_localization_engine.dart';
import '../../../core/services/app_logger.dart';
import 'live_captions_state.dart';

/// A unified Cubit for managing live captions, with optional enhancement.
///
/// This Cubit handles the logic for starting, stopping, and processing
/// speech results, and can optionally use the enhanced caption stream
/// from the [EnhancedSpeechProcessor].
class LiveCaptionsCubit extends Cubit<LiveCaptionsState> {
  final EnhancedSpeechProcessor _speechProcessor;
  final HybridLocalizationEngine _hybridLocalizationEngine;
  final AppLogger _logger = AppLogger.instance;

  StreamSubscription? _captionSubscription;
  final List<EnhancedCaption> _captionHistory = [];
  final bool _useEnhancement;
  SpeechConfig? _speechConfig;

  LiveCaptionsCubit({
    required EnhancedSpeechProcessor speechProcessor,
    required HybridLocalizationEngine hybridLocalizationEngine,
    bool useEnhancement = true,
    SpeechConfig? speechConfig,
  })  : _speechProcessor = speechProcessor,
        _hybridLocalizationEngine = hybridLocalizationEngine,
        _useEnhancement = useEnhancement,
        _speechConfig = speechConfig,
        super(const LiveCaptionsInitial());

  /// Update speech configuration (useful for changing whisper settings)
  void updateSpeechConfig(SpeechConfig config) {
    _speechConfig = config;
    _logger.i('⚙️ Updated speech config: ${config.whisperModel}', category: LogCategory.captions);
  }

  Future<void> startCaptions() async {
    print('DEBUG: LiveCaptionsCubit.startCaptions() called'); // Debug print
    if (state is LiveCaptionsActive && (state as LiveCaptionsActive).isListening) {
      print('DEBUG: Live captions already listening, skipping start'); // Debug print
      _logger.i('🎤 Live captions already listening, skipping start', category: LogCategory.captions);
      return;
    }

    try {
      print('DEBUG: Starting live captions initialization'); // Debug print
      _logger.i('🎤 Starting live captions...', category: LogCategory.captions);
      print('DEBUG: Emitting LiveCaptionsLoading state'); // Debug print
      emit(const LiveCaptionsLoading(message: 'Initializing speech processing...'));
      print('DEBUG: LiveCaptionsLoading state emitted'); // Debug print

      print('DEBUG: Checking if _speechProcessor.isReady: ${_speechProcessor.isReady}'); // Debug print
      if (!_speechProcessor.isReady) {
        print('DEBUG: Speech processor not ready, initializing...'); // Debug print
        // Subscribe to Gemma enhancement events to show progress
        StreamSubscription? gemmaProgressSubscription;
        if (_useEnhancement) {
          gemmaProgressSubscription = _speechProcessor.gemma3nService.enhancementEvents.listen((event) {
            if (!event.isComplete && event.error == null) {
              emit(LiveCaptionsLoading(
                message: event.message,
                progress: event.progress,
              ));
            }
          });
        }

        try {
          // Pass the speech config during initialization
          await _speechProcessor.initialize(
            config: _speechConfig,
            enableGemmaEnhancement: _useEnhancement,
          );
        } finally {
          // Cancel progress subscription
          await gemmaProgressSubscription?.cancel();
        }
      } else {
        print('DEBUG: Speech processor already ready, skipping initialization'); // Debug print
        if (_speechConfig != null) {
          print('DEBUG: Updating speech processor config'); // Debug print
          // Update config if processor is already initialized
          await _speechProcessor.updateConfig(_speechConfig!);
          print('DEBUG: Speech processor config updated'); // Debug print
        }
      }
      
      // The UI will remain in the "loading" state until the first caption is received.
      print('DEBUG: Setting up caption subscription - _useEnhancement: $_useEnhancement, _speechProcessor.isReady: ${_speechProcessor.isReady}'); // Debug print
      if (_useEnhancement && _speechProcessor.isReady) {
        print('DEBUG: Setting up enhanced caption subscription'); // Debug print
        _logger.i('🔍 [CAPTIONS CUBIT] Setting up enhanced caption subscription...', category: LogCategory.captions);
        _logger.i('🔍 [CAPTIONS CUBIT] _useEnhancement: $_useEnhancement, hasGemmaEnhancement: ${_speechProcessor.hasGemmaEnhancement}', category: LogCategory.captions);
        _captionSubscription = _speechProcessor.enhancedCaptions.listen(
          _handleEnhancedCaption,
          onError: (error, stackTrace) {
            _logger.e('❌ [CAPTIONS CUBIT] Error in enhanced captions stream', category: LogCategory.captions, error: error, stackTrace: stackTrace);
          },
          onDone: () {
            _logger.w('⚠️ [CAPTIONS CUBIT] Enhanced captions stream closed', category: LogCategory.captions);
          },
        );
        print('DEBUG: Enhanced caption subscription set up'); // Debug print
        _logger.i('✨ Subscribed to enhanced captions stream.', category: LogCategory.captions);
      } else {
        print('DEBUG: Setting up raw speech subscription'); // Debug print
        _logger.i('🔍 [CAPTIONS CUBIT] Setting up raw speech subscription (enhancement: $_useEnhancement, ready: ${_speechProcessor.isReady})', category: LogCategory.captions);
        _captionSubscription = _speechProcessor.speechResults.listen(
          _handleRawSpeechResult,
          onError: (error, stackTrace) {
            _logger.e('❌ [CAPTIONS CUBIT] Error in speech results stream', category: LogCategory.captions, error: error, stackTrace: stackTrace);
          },
          onDone: () {
            _logger.w('⚠️ [CAPTIONS CUBIT] Speech results stream closed', category: LogCategory.captions);
          },
        );
        print('DEBUG: Raw speech subscription set up'); // Debug print
        _logger.i('📝 Subscribed to raw speech results stream.', category: LogCategory.captions);
      }

      // Pass the speech config during processing start
      print('DEBUG: About to call _speechProcessor.startProcessing()'); // Debug print
      await _speechProcessor.startProcessing(config: _speechConfig);
      print('DEBUG: _speechProcessor.startProcessing() completed'); // Debug print
      
      // We no longer emit an "Active" state here immediately. The first
      // received caption will transition the state from Loading to Active.
      print('DEBUG: Live captions setup completed, waiting for first result'); // Debug print
      _logger.i('✅ Live captions started successfully, waiting for first result...', category: LogCategory.captions);
    } catch (e) {
      _logger.e('❌ Failed to start live captions: $e', category: LogCategory.captions, error: e);
      emit(LiveCaptionsError(message: 'Failed to start live captions', details: e.toString()));
      rethrow;
    }
  }

  void _handleEnhancedCaption(EnhancedCaption caption) {
    _logger.i('📋📥 [CAPTIONS CUBIT] Received enhanced caption: "${caption.displayText}" (final: ${caption.isFinal}, enhanced: ${caption.isEnhanced})', category: LogCategory.captions);
    
    final currentState = state is LiveCaptionsActive
        ? (state as LiveCaptionsActive)
        : LiveCaptionsActive(isListening: true, hasEnhancement: _useEnhancement, captions: []);

    if (caption.isFinal) {
      _captionHistory.add(caption);
      if (_captionHistory.length > 50) _captionHistory.removeAt(0);
      _logger.i('📚 [CAPTIONS CUBIT] Added FINAL caption to history (${_captionHistory.length} total)', category: LogCategory.captions);

      final displayText = caption.displayText;
      _logger.i('🎯 [CAPTIONS CUBIT] Placing FINAL caption in AR space: "$displayText"', category: LogCategory.captions);
      
      // Place caption in AR - catch any errors
      try {
        _hybridLocalizationEngine.placeRealtimeCaption(displayText).catchError((e, stackTrace) {
          _logger.e('❌ [CAPTIONS CUBIT] Failed to place caption in AR', category: LogCategory.captions, error: e, stackTrace: stackTrace);
        });
      } catch (e, stackTrace) {
        _logger.e('❌ [CAPTIONS CUBIT] Exception placing caption in AR', category: LogCategory.captions, error: e, stackTrace: stackTrace);
      }

      emit(currentState.copyWith(
        captions: List.from(_captionHistory),
        currentCaption: null,
        hasEnhancement: caption.isEnhanced,
      ));
      _logger.i('📤 [CAPTIONS CUBIT] Emitted updated state with ${_captionHistory.length} captions - FINAL CAPTION SHOULD BE VISIBLE NOW', category: LogCategory.captions);
    } else {
      _logger.i('⏳ [CAPTIONS CUBIT] Processing partial caption: "${caption.displayText}"', category: LogCategory.captions);
      
      // TEMPORARY: Place partial captions in AR for testing
      if (caption.displayText.isNotEmpty && caption.displayText.length > 3) {
        _logger.w('🧪 [CAPTIONS CUBIT] TEST MODE: Placing PARTIAL caption in AR: "${caption.displayText}"', category: LogCategory.captions);
        try {
          _hybridLocalizationEngine.placeRealtimeCaption(caption.displayText).catchError((e, stackTrace) {
            _logger.e('❌ [CAPTIONS CUBIT] Failed to place partial caption in AR', category: LogCategory.captions, error: e, stackTrace: stackTrace);
          });
        } catch (e, stackTrace) {
          _logger.e('❌ [CAPTIONS CUBIT] Exception placing partial caption in AR', category: LogCategory.captions, error: e, stackTrace: stackTrace);
        }
      }
      
      emit(currentState.copyWith(currentCaption: SpeechResult(
        text: caption.displayText,
        confidence: caption.confidence,
        isFinal: caption.isFinal,
        timestamp: caption.timestamp,
      )));
      _logger.i('📤 [CAPTIONS CUBIT] Emitted state with partial caption - PARTIAL CAPTION SHOULD BE VISIBLE NOW', category: LogCategory.captions);
    }
  }

  void _handleRawSpeechResult(SpeechResult result) {
    _logger.i('🎤📥 [CAPTIONS CUBIT] Received raw speech result: "${result.text}" (final: ${result.isFinal})', category: LogCategory.captions);
    final enhancedCaption = EnhancedCaption.fromSpeechResult(result);
    _handleEnhancedCaption(enhancedCaption);
  }

  Future<void> stopCaptions() async {
    if (state is! LiveCaptionsActive) return;
    final currentState = state as LiveCaptionsActive;

    await _captionSubscription?.cancel();
    await _speechProcessor.stopProcessing();
    emit(currentState.copyWith(isListening: false, currentCaption: null));
  }

  void clearCaptions() {
    _captionHistory.clear();
    if (state is LiveCaptionsActive) {
      emit((state as LiveCaptionsActive).copyWith(captions: [], currentCaption: null));
    }
  }

  @override
  Future<void> close() {
    stopCaptions();
    _speechProcessor.dispose();
    return super.close();
  }
}
