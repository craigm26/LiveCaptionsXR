import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/enhanced_caption.dart';
import '../../../core/models/speech_result.dart';
import '../../../core/models/speech_config.dart';
import '../../../core/services/enhanced_speech_processor.dart';
import '../../../core/services/hybrid_localization_engine.dart';
import '../../../core/services/spatial_caption_integration_service.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/services/debug_logger_service.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/di/service_locator.dart';
import 'live_captions_state.dart';

/// A unified Cubit for managing live captions, with optional enhancement.
///
/// This Cubit handles the logic for starting, stopping, and processing
/// speech results, and can optionally use the enhanced caption stream
/// from the [EnhancedSpeechProcessor].
class LiveCaptionsCubit extends Cubit<LiveCaptionsState> {
  static const String _fallbackActivityText = 'Listening...';
  final EnhancedSpeechProcessor _speechProcessor;
  final HybridLocalizationEngine _hybridLocalizationEngine;
  final SpatialCaptionIntegrationService _spatialCaptionIntegrationService;
  final AppLogger _logger = AppLogger.instance;

  StreamSubscription? _captionSubscription;
  final List<EnhancedCaption> _captionHistory = [];
  bool _useEnhancement;
  SpeechConfig? _speechConfig;

  LiveCaptionsCubit({
    required EnhancedSpeechProcessor speechProcessor,
    required HybridLocalizationEngine hybridLocalizationEngine,
    required SpatialCaptionIntegrationService spatialCaptionIntegrationService,
    bool useEnhancement = true,
    SpeechConfig? speechConfig,
  })  : _speechProcessor = speechProcessor,
        _hybridLocalizationEngine = hybridLocalizationEngine,
        _spatialCaptionIntegrationService = spatialCaptionIntegrationService,
        _useEnhancement = useEnhancement,
        _speechConfig = speechConfig,
        super(const LiveCaptionsInitial());

  /// Update speech configuration (useful for changing whisper settings)
  void updateSpeechConfig(SpeechConfig config) {
    _speechConfig = config;
    _logger.i('⚙️ Updated speech config: ${config.whisperModel}', category: LogCategory.captions);
  }

  void setEnhancementEnabled(bool enabled) {
    _useEnhancement = enabled;
    _speechProcessor.setEnhancementEnabled(enabled);
    _logger.i('✨ Caption enhancement ${enabled ? 'enabled' : 'disabled'}', category: LogCategory.captions);
  }

  Future<void> startCaptions() async {
    if (state is LiveCaptionsActive && (state as LiveCaptionsActive).isListening) {
      _logger.i('🎤 Live captions already listening, skipping start', category: LogCategory.captions);
      return;
    }

    try {
      _logger.i('🎤 Starting live captions...', category: LogCategory.captions);
      _logger.d('🧭 Localization engine active: ${_hybridLocalizationEngine.runtimeType}', category: LogCategory.captions);
      _speechProcessor.setEnhancementEnabled(_useEnhancement);
      emit(const LiveCaptionsLoading(message: 'Initializing spatial caption system...'));

      // Note: Spatial caption integration service should be initialized 
      // when AR services start, not when captions start
      _logger.i('ℹ️ [CAPTIONS CUBIT] Spatial caption integration service should already be initialized by AR services', category: LogCategory.captions);

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

      if (_useEnhancement && !_speechProcessor.hasEnhancement) {
        _logger.w('⚠️ Enhancement requested but no enhancement backend is ready; auto-disabling enhancement for this session', category: LogCategory.captions);
        _useEnhancement = false;
        _speechProcessor.setEnhancementEnabled(false);
      }
      
      final useEnhancedStream = _useEnhancement;

      // The UI will remain in the "loading" state until the first caption is received.
      if (useEnhancedStream) {
        _logger.i('🔍 [CAPTIONS CUBIT] Setting up enhanced caption subscription...', category: LogCategory.captions);
        _logger.i('🔍 [CAPTIONS CUBIT] _useEnhancement: $_useEnhancement, hasEnhancement: ${_speechProcessor.hasEnhancement}, hasGemmaEnhancement: ${_speechProcessor.hasGemmaEnhancement}', category: LogCategory.captions);
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
        _logger.i('🔍 [CAPTIONS CUBIT] Setting up raw speech subscription (enhancement requested: $_useEnhancement, enhancement ready: ${_speechProcessor.hasEnhancement}, processor ready: ${_speechProcessor.isReady})', category: LogCategory.captions);
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
      
      emit(LiveCaptionsActive(
        captions: List<SpeechResult>.from(_captionHistory.map((c) => SpeechResult(
          text: c.displayText,
          confidence: c.confidence,
          isFinal: c.isFinal,
          timestamp: c.timestamp,
        ))),
        isListening: true,
        hasEnhancement: _useEnhancement,
        rawSttDebugText: null,
      ));

      await _injectStartupCaptionVisibilityTest();

      _logger.i('✅ Live captions started successfully', category: LogCategory.captions);
    } catch (e) {
      _logger.e('❌ Failed to start live captions: $e', category: LogCategory.captions, error: e);
      emit(LiveCaptionsError(message: 'Failed to start live captions', details: e.toString()));
      rethrow;
    }
  }

  Future<void> _injectStartupCaptionVisibilityTest() async {
    final isEmulator = await isAndroidEmulator();
    if (!isEmulator) {
      return;
    }

    const testPhrase = 'Caption visibility test: this is an injected startup phrase.';
    _logger.i('🧪 Injecting startup caption visibility test phrase for emulator', category: LogCategory.captions);

    _handleRawSpeechResult(SpeechResult(
      text: testPhrase,
      confidence: 1.0,
      isFinal: true,
      timestamp: DateTime.now(),
      metadata: const {'source': 'startup_visibility_test'},
    ));
  }

  void _handleEnhancedCaption(EnhancedCaption caption) async {
    _logger.i('📋📥 [CAPTIONS CUBIT] Received enhanced caption: "${caption.displayText}" (final: ${caption.isFinal}, enhanced: ${caption.isEnhanced})', category: LogCategory.captions);
    
    final currentState = state is LiveCaptionsActive
        ? (state as LiveCaptionsActive)
        : LiveCaptionsActive(isListening: true, hasEnhancement: _useEnhancement, captions: []);

    if (caption.isFinal) {
      _captionHistory.add(caption);
      if (_captionHistory.length > 50) _captionHistory.removeAt(0);
      _logger.i('📚 [CAPTIONS CUBIT] Added FINAL caption to history (${_captionHistory.length} total)', category: LogCategory.captions);

      var displayText = caption.displayText;
      
      // Apply translation if enabled
      if (sl.isRegistered<TranslationService>()) {
        final translationService = sl<TranslationService>();
        if (translationService.isEnabled) {
          try {
            _logger.d('🌐 Translating caption: "$displayText"', category: LogCategory.captions);
            final result = await translationService.translate(displayText);
            if (result.wasTranslated) {
              // Format: show translation, optionally with original
              if (translationService.showOriginal) {
                displayText = '${result.translatedText}\n[${result.originalText}]';
              } else {
                displayText = result.translatedText;
              }
              _logger.i('🌐 Translated: "${result.originalText}" → "${result.translatedText}"', category: LogCategory.captions);
            }
          } catch (e) {
            _logger.w('⚠️ Translation failed, using original: $e', category: LogCategory.captions);
          }
        }
      }
      
      _logger.d('🎯 Processing final caption through spatial integration: "$displayText"');
      
      // Create speech result for spatial caption integration
      final speechResult = SpeechResult(
        text: displayText,
        confidence: caption.confidence,
        isFinal: true,
        timestamp: caption.timestamp,
      );
      
      // Process through spatial caption integration service
      var spatialFinalizationFailed = false;
      try {
        await _spatialCaptionIntegrationService.processFinalResult(speechResult);
      } catch (e, stackTrace) {
        spatialFinalizationFailed = true;
        _logger.w('⚠️ Spatial finalization failed; keeping Flutter caption pipeline active: $e', category: LogCategory.captions);
        _logger.d('ℹ️ Spatial finalization stack', category: LogCategory.captions, error: e, stackTrace: stackTrace);
      }

      emit(currentState.copyWith(
        captions: _captionHistory.map((c) => SpeechResult(
          text: c.displayText,
          confidence: c.confidence,
          isFinal: c.isFinal,
          timestamp: c.timestamp,
        )).toList(),
        currentCaption: null,
        hasEnhancement: caption.isEnhanced,
        showOverlayFallback: currentState.showOverlayFallback || spatialFinalizationFailed,
      ));
      _logger.i('📤 [CAPTIONS CUBIT] Emitted updated state with ${_captionHistory.length} captions - FINAL CAPTION SHOULD BE VISIBLE NOW', category: LogCategory.captions);
    } else {
      _logger.i('⏳ [CAPTIONS CUBIT] Processing partial caption: "${caption.displayText}"', category: LogCategory.captions);
      
      // Use spatial_captions plugin for partial results (consistent with final results)
      if (caption.displayText.isNotEmpty && caption.displayText.length > 3) {
        _logger.d('⚡ [CAPTIONS CUBIT] Processing PARTIAL caption with spatial plugin: "${caption.displayText}"', category: LogCategory.captions);
        try {
          // Create SpeechResult for spatial processing
          final speechResult = SpeechResult(
            text: caption.displayText,
            confidence: caption.confidence,
            isFinal: caption.isFinal,
            timestamp: caption.timestamp,
          );
          
          // Process through spatial plugin (same as final results)
          await _spatialCaptionIntegrationService.processPartialResult(speechResult);
          _logger.d('✅ [CAPTIONS CUBIT] Partial caption processed through spatial plugin', category: LogCategory.captions);
        } catch (e, stackTrace) {
          _logger.e('❌ [CAPTIONS CUBIT] Failed to process partial caption through spatial plugin', category: LogCategory.captions, error: e, stackTrace: stackTrace);
          // Note: No fallback - spatial plugin is the only caption system now
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

    if (state is LiveCaptionsActive) {
      final currentState = state as LiveCaptionsActive;
      emit(currentState.copyWith(rawSttDebugText: result.text));
    }

    final normalized = result.text.trim();
    if (normalized.isEmpty || normalized == _fallbackActivityText) {
      _emitActivityFallback(result);
      return;
    }

    final enhancedCaption = EnhancedCaption.fromSpeechResult(result);
    _handleEnhancedCaption(enhancedCaption);
  }

  void _emitActivityFallback(SpeechResult source) {
    final activityCaption = SpeechResult(
      text: _fallbackActivityText,
      confidence: source.confidence,
      isFinal: false,
      timestamp: DateTime.now(),
      speakerDirection: source.speakerDirection,
      metadata: source.metadata,
    );

    if (state is LiveCaptionsActive) {
      final currentState = state as LiveCaptionsActive;
      emit(currentState.copyWith(
        currentCaption: activityCaption,
        showOverlayFallback: true,
        rawSttDebugText: source.text,
      ));
      return;
    }

    emit(LiveCaptionsActive(
      captions: const [],
      currentCaption: activityCaption,
      isListening: true,
      showOverlayFallback: true,
      hasEnhancement: false,
      rawSttDebugText: source.text,
    ));
  }

  Future<void> stopCaptions() async {
    await _captionSubscription?.cancel();
    _captionSubscription = null;
    await _speechProcessor.stopProcessing();

    if (state is LiveCaptionsActive) {
      final currentState = state as LiveCaptionsActive;
      emit(currentState.copyWith(isListening: false, currentCaption: null, rawSttDebugText: null));
      return;
    }

    emit(const LiveCaptionsInitial());
  }

  void clearCaptions() {
    _captionHistory.clear();
    if (state is LiveCaptionsActive) {
      emit((state as LiveCaptionsActive).copyWith(captions: [], currentCaption: null, rawSttDebugText: null));
    }
  }

  @override
  Future<void> close() {
    stopCaptions();
    _speechProcessor.dispose();
    return super.close();
  }
}
