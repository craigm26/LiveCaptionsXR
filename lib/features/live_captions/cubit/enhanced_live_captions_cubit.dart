import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../core/services/enhanced_speech_processor.dart';
import '../../../core/services/speech_processor.dart';
import '../../../core/services/hybrid_localization_engine.dart';
import '../../../core/services/contextual_enhancer.dart';
import '../../../core/models/speech_result.dart';
import '../../../core/models/enhanced_caption.dart';
import 'live_captions_state.dart';
import 'live_captions_cubit.dart';

/// Enhanced version of LiveCaptionsCubit that supports Gemma enhancement
class EnhancedLiveCaptionsCubit extends LiveCaptionsCubit {
  final EnhancedSpeechProcessor _enhancedSpeechProcessor;
  final Logger _enhancedLogger = Logger();

  StreamSubscription<SpeechResult>? _speechSubscription;
  StreamSubscription<EnhancedCaption>? _enhancedCaptionSubscription;
  final List<EnhancedCaption> _captionHistory = [];
  final StringBuffer _accumulatedText = StringBuffer();
  Timer? _enhancementTimer;
  
  // Configuration
  final bool _useGemmaEnhancement;
  final bool _showEnhancementIndicator;

  EnhancedLiveCaptionsCubit({
    required EnhancedSpeechProcessor speechProcessor,
    required HybridLocalizationEngine hybridLocalizationEngine,
    required ContextualEnhancer contextualEnhancer,
    bool useGemmaEnhancement = true,
    bool showEnhancementIndicator = true,
  })  : _enhancedSpeechProcessor = speechProcessor,
        _useGemmaEnhancement = useGemmaEnhancement,
        _showEnhancementIndicator = showEnhancementIndicator,
        // Pass a dummy SpeechProcessor to parent since we override all methods
        super(
          speechProcessor: SpeechProcessor(),
          hybridLocalizationEngine: hybridLocalizationEngine,
          contextualEnhancer: contextualEnhancer,
        );

  @override
  Future<void> startCaptions() async {
    // Don't start if already listening
    if (state is LiveCaptionsActive && (state as LiveCaptionsActive).isListening) {
      _enhancedLogger.i('🎤 Live captions already listening, skipping start');
      return;
    }

    try {
      _enhancedLogger.i('🎤 Starting enhanced live captions...');
      
      // Emit loading state
      emit(const LiveCaptionsLoading());
      
      // Initialize if needed
      if (!_enhancedSpeechProcessor.isReady) {
        await _enhancedSpeechProcessor.initialize(enableGemmaEnhancement: _useGemmaEnhancement);
      }
      
      // Start speech processing
      await _enhancedSpeechProcessor.startProcessing();
      
      // Subscribe to streams based on configuration
      if (_useGemmaEnhancement && _enhancedSpeechProcessor.hasGemmaEnhancement) {
        // Use enhanced captions stream
        _enhancedCaptionSubscription = _enhancedSpeechProcessor.enhancedCaptions.listen(_handleEnhancedCaption);
        _enhancedLogger.i('✨ Using Gemma-enhanced captions');
      } else {
        // Fall back to regular speech results
        _speechSubscription = _enhancedSpeechProcessor.speechResults.listen(_handleSpeechResult);
        _enhancedLogger.i('📝 Using standard captions (no enhancement)');
      }
      
      _startEnhancementTimer();
      
      // Emit active state with listening = true
      emit(LiveCaptionsActive(
        captions: [],
        isListening: true,
        hasEnhancement: _enhancedSpeechProcessor.hasGemmaEnhancement,
      ));
      
      _enhancedLogger.i('✅ Enhanced live captions started successfully');
    } catch (e) {
      _enhancedLogger.e('❌ Failed to start enhanced live captions: $e');
      emit(LiveCaptionsError(
        message: 'Failed to start live captions',
        details: e.toString(),
      ));
      rethrow;
    }
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
      final enhancedText = await contextualEnhancer.enhanceText(text);
      await hybridLocalizationEngine.placeContextualSummary(enhancedText);
    } catch (e) {
      _enhancedLogger.e("Failed to run periodic enhancement: $e");
    }
  }

  void _handleEnhancedCaption(EnhancedCaption caption) {
    if (state is! LiveCaptionsActive) return;
    final currentState = state as LiveCaptionsActive;

    if (caption.isFinal) {
      _captionHistory.add(caption);
      if (_captionHistory.length > 50) _captionHistory.removeAt(0);
      
      // Use enhanced text if available, otherwise raw
      final displayText = caption.displayText;
      _accumulatedText.writeln(displayText);
      
      // Place the caption with enhancement indicator if configured
      if (_showEnhancementIndicator && caption.hasEnhancement) {
        hybridLocalizationEngine.placeRealtimeCaption("✨ $displayText");
      } else {
        hybridLocalizationEngine.placeRealtimeCaption(displayText);
      }
      
      // Convert enhanced captions to speech results for compatibility
      final speechResults = _captionHistory.map((ec) => SpeechResult(
        text: ec.displayText,
        confidence: ec.confidence,
        isFinal: ec.isFinal,
        timestamp: ec.timestamp,
      )).toList();
      
      emit(currentState.copyWith(
        captions: speechResults,
        currentCaption: null,
        hasEnhancement: caption.isEnhanced,
      ));
    } else {
      // Handle partial results
      final partialResult = SpeechResult(
        text: caption.raw,
        confidence: caption.confidence,
        isFinal: false,
        timestamp: caption.timestamp,
      );
      emit(currentState.copyWith(currentCaption: partialResult));
    }
  }

  void _handleSpeechResult(SpeechResult result) {
    if (state is! LiveCaptionsActive) return;
    final currentState = state as LiveCaptionsActive;

    if (result.isFinal) {
      // Convert to enhanced caption for history
      final enhancedCaption = EnhancedCaption.fallback(result.text);
      _captionHistory.add(enhancedCaption);
      if (_captionHistory.length > 50) _captionHistory.removeAt(0);
      
      _accumulatedText.writeln(result.text);
      hybridLocalizationEngine.placeRealtimeCaption(result.text);
      
      // Convert back to speech results for compatibility
      final speechResults = _captionHistory.map((ec) => SpeechResult(
        text: ec.displayText,
        confidence: ec.confidence,
        isFinal: ec.isFinal,
        timestamp: ec.timestamp,
      )).toList();
      
      emit(currentState.copyWith(captions: speechResults, currentCaption: null));
    } else {
      emit(currentState.copyWith(currentCaption: result));
    }
  }

  @override
  Future<void> stopCaptions() async {
    try {
      _enhancedLogger.i('⏹️ Stopping enhanced live captions...');
      
      await _speechSubscription?.cancel();
      await _enhancedCaptionSubscription?.cancel();
      _enhancementTimer?.cancel();
      
      await _enhancedSpeechProcessor.stopProcessing();
      
      emit(LiveCaptionsActive(
        captions: _captionHistory.map((ec) => SpeechResult(
          text: ec.displayText,
          confidence: ec.confidence,
          isFinal: ec.isFinal,
          timestamp: ec.timestamp,
        )).toList(),
        isListening: false,
      ));
      
      _enhancedLogger.i('✅ Enhanced live captions stopped');
    } catch (e) {
      _enhancedLogger.e('❌ Failed to stop enhanced live captions: $e');
      emit(LiveCaptionsError(
        message: 'Failed to stop live captions',
        details: e.toString(),
      ));
    }
  }

  /// Switch between speech engines
  Future<void> switchEngine(SpeechEngine engine) async {
    if (state is LiveCaptionsActive && (state as LiveCaptionsActive).isListening) {
      await stopCaptions();
      await _enhancedSpeechProcessor.switchEngine(engine);
      await startCaptions();
    } else {
      await _enhancedSpeechProcessor.switchEngine(engine);
    }
  }

  /// Get current engine statistics
  Map<String, dynamic> getStatistics() {
    return {
      'captionCount': _captionHistory.length,
      'isListening': state is LiveCaptionsActive ? (state as LiveCaptionsActive).isListening : false,
      'hasGemmaEnhancement': _enhancedSpeechProcessor.hasGemmaEnhancement,
      'engineStats': _enhancedSpeechProcessor.getStatistics(),
    };
  }

  @override
  Future<void> close() async {
    await stopCaptions();
    await _enhancedSpeechProcessor.dispose();
    return super.close();
  }
} 