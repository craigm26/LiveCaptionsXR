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
    if (state is LiveCaptionsActive && (state as LiveCaptionsActive).isListening) {
      _logger.i('🎤 Live captions already listening, skipping start', category: LogCategory.captions);
      return;
    }

    try {
      _logger.i('🎤 Starting live captions...', category: LogCategory.captions);
      emit(const LiveCaptionsLoading(message: 'Initializing speech processing...'));

      if (!_speechProcessor.isReady) {
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
        if (_speechConfig != null) {
          // Update config if processor is already initialized
          await _speechProcessor.updateConfig(_speechConfig!);
        }
      }
      
      // The UI will remain in the "loading" state until the first caption is received.
      if (_useEnhancement && _speechProcessor.isReady) {
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
        _logger.i('✨ Subscribed to enhanced captions stream.', category: LogCategory.captions);
      } else {
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
        _logger.i('📝 Subscribed to raw speech results stream.', category: LogCategory.captions);
      }

      // Pass the speech config during processing start
      await _speechProcessor.startProcessing(config: _speechConfig);
      
      // We no longer emit an "Active" state here immediately. The first
      // received caption will transition the state from Loading to Active.
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
      
      // Place caption in AR
      try {
        _hybridLocalizationEngine.placeRealtimeCaption(displayText).catchError((e, stackTrace) {
          _logger.e('❌ [CAPTIONS CUBIT] Failed to place caption in AR', category: LogCategory.captions, error: e, stackTrace: stackTrace);
        });
      } catch (e, stackTrace) {
        _logger.e('❌ [CAPTIONS CUBIT] Exception placing caption in AR', category: LogCategory.captions, error: e, stackTrace: stackTrace);
      }
      _logger.d('📍 Caption placed in AR space', category: LogCategory.captions);

      emit(currentState.copyWith(
        captions: _captionHistory.map((c) => SpeechResult(
          text: c.displayText,
          confidence: c.confidence,
          isFinal: c.isFinal,
          timestamp: c.timestamp,
        )).toList(),
        currentCaption: null,
        hasEnhancement: caption.isEnhanced,
      ));
      _logger.i('📤 [CAPTIONS CUBIT] Emitted updated state with ${_captionHistory.length} captions - FINAL CAPTION SHOULD BE VISIBLE NOW', category: LogCategory.captions);
    } else {
      _logger.i('⏳ [CAPTIONS CUBIT] Processing partial caption: "${caption.displayText}"', category: LogCategory.captions);
      
      // Place partial captions in AR for real-time feedback
      if (caption.displayText.isNotEmpty && caption.displayText.length > 3) {
        _logger.d('⚡ [CAPTIONS CUBIT] Placing PARTIAL caption in AR: "${caption.displayText}"', category: LogCategory.captions);
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
