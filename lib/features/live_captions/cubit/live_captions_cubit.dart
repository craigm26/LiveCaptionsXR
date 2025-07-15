import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../core/services/speech_processor.dart';
import '../../../core/services/hybrid_localization_engine.dart';
import '../../../core/services/contextual_enhancer.dart';
import '../../../core/models/speech_result.dart';
import 'live_captions_state.dart';

class LiveCaptionsCubit extends Cubit<LiveCaptionsState> {
  final SpeechProcessor _speechProcessor;
  final HybridLocalizationEngine _hybridLocalizationEngine;
  final ContextualEnhancer _contextualEnhancer;
  final Logger _logger = Logger();

  StreamSubscription<SpeechResult>? _speechSubscription;
  final List<SpeechResult> _captionHistory = [];
  final StringBuffer _accumulatedText = StringBuffer();
  Timer? _enhancementTimer;

  LiveCaptionsCubit({
    required SpeechProcessor speechProcessor,
    required HybridLocalizationEngine hybridLocalizationEngine,
    required ContextualEnhancer contextualEnhancer,
  })  : _speechProcessor = speechProcessor,
        _hybridLocalizationEngine = hybridLocalizationEngine,
        _contextualEnhancer = contextualEnhancer,
        super(const LiveCaptionsInitial());

  Future<void> startCaptions() async {
    if (state is! LiveCaptionsActive) return;
    final currentState = state as LiveCaptionsActive;
    if (currentState.isListening) return;

    await _speechProcessor.startProcessing();
    _speechSubscription = _speechProcessor.speechResults.listen(_handleSpeechResult);
    _startEnhancementTimer();
    emit(currentState.copyWith(isListening: true));
  }

  void _startEnhancementTimer() {
    _enhancementTimer?.cancel();
    _enhancementTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_accumulatedText.isNotEmpty) {
        final text = _accumulatedText.toString();
        _accumulatedText.clear();
        _runPeriodicEnhancement(text);
      }
    });
  }

  Future<void> _runPeriodicEnhancement(String text) async {
    try {
      final enhancedText = await _contextualEnhancer.enhanceText(text);
      await _hybridLocalizationEngine.placeContextualSummary(enhancedText);
    } catch (e) {
      _logger.e("Failed to run periodic enhancement: $e");
    }
  }

  void _handleSpeechResult(SpeechResult result) {
    if (state is! LiveCaptionsActive) return;
    final currentState = state as LiveCaptionsActive;

    if (result.isFinal) {
      _captionHistory.add(result);
      if (_captionHistory.length > 50) _captionHistory.removeAt(0);
      _accumulatedText.writeln(result.text);
      _hybridLocalizationEngine.placeRealtimeCaption(result.text);
      emit(currentState.copyWith(captions: List.from(_captionHistory), currentCaption: null));
    } else {
      emit(currentState.copyWith(currentCaption: result));
    }
  }

  Future<void> stopCaptions() async {
    if (state is! LiveCaptionsActive) return;
    final currentState = state as LiveCaptionsActive;

    _enhancementTimer?.cancel();
    await _speechSubscription?.cancel();
    await _speechProcessor.stopProcessing();
    emit(currentState.copyWith(isListening: false, currentCaption: null));
  }

  @override
  Future<void> close() {
    stopCaptions();
    _speechProcessor.dispose();
    return super.close();
  }
}
