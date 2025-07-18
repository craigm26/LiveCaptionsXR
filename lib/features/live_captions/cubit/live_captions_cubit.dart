import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../core/models/enhanced_caption.dart';
import '../../../core/models/speech_result.dart';
import '../../../core/models/speech_config.dart';
import '../../../core/services/enhanced_speech_processor.dart';
import '../../../core/services/hybrid_localization_engine.dart';
import 'live_captions_state.dart';

/// A unified Cubit for managing live captions, with optional enhancement.
///
/// This Cubit handles the logic for starting, stopping, and processing
/// speech results, and can optionally use the enhanced caption stream
/// from the [EnhancedSpeechProcessor].
class LiveCaptionsCubit extends Cubit<LiveCaptionsState> {
  final EnhancedSpeechProcessor _speechProcessor;
  final HybridLocalizationEngine _hybridLocalizationEngine;
  final Logger _logger = Logger();

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
    _logger.i('⚙️ Updated speech config: ${config.whisperModel}');
  }

  Future<void> startCaptions() async {
    if (state is LiveCaptionsActive && (state as LiveCaptionsActive).isListening) {
      _logger.i('🎤 Live captions already listening, skipping start');
      return;
    }

    try {
      _logger.i('🎤 Starting live captions...');
      emit(const LiveCaptionsLoading());

      if (!_speechProcessor.isReady) {
        // Pass the speech config during initialization
        await _speechProcessor.initialize(
          config: _speechConfig,
          enableGemmaEnhancement: _useEnhancement,
        );
      } else if (_speechConfig != null) {
        // Update config if processor is already initialized
        await _speechProcessor.updateConfig(_speechConfig!);
      }
      
      // The UI will remain in the "loading" state until the first caption is received.
      if (_useEnhancement && _speechProcessor.isReady) {
        _captionSubscription = _speechProcessor.enhancedCaptions.listen(_handleEnhancedCaption);
        _logger.i('✨ Subscribed to enhanced captions stream.');
      } else {
        _captionSubscription = _speechProcessor.speechResults.listen(_handleRawSpeechResult);
        _logger.i('📝 Subscribed to raw speech results stream.');
      }

      // Pass the speech config during processing start
      await _speechProcessor.startProcessing(config: _speechConfig);
      
      // We no longer emit an "Active" state here immediately. The first
      // received caption will transition the state from Loading to Active.
      _logger.i('✅ Live captions started successfully, waiting for first result...');
    } catch (e) {
      _logger.e('❌ Failed to start live captions: $e');
      emit(LiveCaptionsError(message: 'Failed to start live captions', details: e.toString()));
      rethrow;
    }
  }

  void _handleEnhancedCaption(EnhancedCaption caption) {
    final currentState = state is LiveCaptionsActive
        ? (state as LiveCaptionsActive)
        : LiveCaptionsActive(isListening: true, hasEnhancement: _useEnhancement, captions: []);

    if (caption.isFinal) {
      _captionHistory.add(caption);
      if (_captionHistory.length > 50) _captionHistory.removeAt(0);

      final displayText = caption.displayText;
      _hybridLocalizationEngine.placeRealtimeCaption(displayText);

      emit(currentState.copyWith(
        captions: List.from(_captionHistory),
        currentCaption: null,
        hasEnhancement: caption.isEnhanced,
      ));
    } else {
      emit(currentState.copyWith(currentCaption: SpeechResult(
        text: caption.displayText,
        confidence: caption.confidence,
        isFinal: caption.isFinal,
        timestamp: caption.timestamp,
      )));
    }
  }

  void _handleRawSpeechResult(SpeechResult result) {
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
