import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../core/models/enhanced_caption.dart';
import '../../../core/models/speech_result.dart';
import '../../../core/models/speech_config.dart';
import '../../../core/services/enhanced_speech_processor.dart';
import '../../../core/services/hybrid_localization_engine.dart';
import '../../../core/services/spatial_caption_integration_service.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/services/speaker_attribution_store.dart';
import 'live_captions_state.dart';
import 'package:live_captions_xr/spatial_intel/streams/predictive_stream_hub.dart';
import 'package:live_captions_xr/spatial_intel/streams/context_stream.dart';
import 'package:live_captions_xr/spatial_intel/predict/predictive_caption_engine.dart';
import 'package:live_captions_xr/spatial_intel/predict/next_token_stream.dart';

class LiveCaptionsStartException implements Exception {
  final String message;
  final String? details;

  LiveCaptionsStartException(this.message, [this.details]);

  @override
  String toString() {
    if (details == null || details!.isEmpty) {
      return message;
    }
    return '$message: $details';
  }
}

/// A unified Cubit for managing live captions, with optional enhancement.
///
/// This Cubit handles the logic for starting, stopping, and processing
/// speech results, and can optionally use the enhanced caption stream
/// from the [EnhancedSpeechProcessor].
class LiveCaptionsCubit extends Cubit<LiveCaptionsState> {
  final EnhancedSpeechProcessor _speechProcessor;
  final SpatialCaptionIntegrationService _spatialCaptionIntegrationService;
  final SpeakerAttributionStore _speakerAttributionStore;
  final AppLogger _logger = AppLogger.instance;

  StreamSubscription? _captionSubscription;
  StreamSubscription<NextTokenState>? _predictiveSubscription;
  final List<EnhancedCaption> _captionHistory = [];
  final bool _useEnhancement;
  SpeechConfig? _speechConfig;
  NextTokenState? _latestPredictiveState;

  LiveCaptionsCubit({
    required EnhancedSpeechProcessor speechProcessor,
    required HybridLocalizationEngine hybridLocalizationEngine,
    required SpatialCaptionIntegrationService spatialCaptionIntegrationService,
    required SpeakerAttributionStore speakerAttributionStore,
    bool useEnhancement = true,
    SpeechConfig? speechConfig,
  }) : _speechProcessor = speechProcessor,
       _spatialCaptionIntegrationService = spatialCaptionIntegrationService,
       _speakerAttributionStore = speakerAttributionStore,
       _useEnhancement = useEnhancement,
       _speechConfig = speechConfig,
       super(const LiveCaptionsInitial()) {
    _logger.d(
      '🧭 Hybrid localization engine ready: ${hybridLocalizationEngine.runtimeType}',
      category: LogCategory.captions,
    );
    _initializePredictiveSubscription();
  }

  void _initializePredictiveSubscription() {
    if (!GetIt.I.isRegistered<PredictiveCaptionEngine>()) {
      _logger.w(
        '⚠️ PredictiveCaptionEngine not registered; predictive UI features disabled',
        category: LogCategory.captions,
      );
      return;
    }
    try {
      final engine = GetIt.I<PredictiveCaptionEngine>();
      engine.initialize();
      _predictiveSubscription = engine.nextTokenStates.listen(
        (predictiveState) {
          _latestPredictiveState = predictiveState;
          if (state is LiveCaptionsActive) {
            emit(
              (state as LiveCaptionsActive).copyWith(
                predictiveState: predictiveState,
              ),
            );
          }
        },
        onError: (error, stackTrace) {
          _logger.w(
            '⚠️ Predictive caption stream error: $error',
            category: LogCategory.captions,
            error: error,
            stackTrace: stackTrace,
          );
        },
      );
    } catch (e, stackTrace) {
      _logger.w(
        '⚠️ Failed to initialize predictive caption subscription',
        category: LogCategory.captions,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Update speech configuration (useful for changing whisper settings)
  void updateSpeechConfig(SpeechConfig config) {
    _speechConfig = config;
    _logger.i(
      '⚙️ Updated speech config: ${config.whisperModel}',
      category: LogCategory.captions,
    );
  }

  Future<void> startCaptions() async {
    if (state is LiveCaptionsActive &&
        (state as LiveCaptionsActive).isListening) {
      _logger.i(
        '🎤 Live captions already listening, skipping start',
        category: LogCategory.captions,
      );
      return;
    }

    try {
      _logger.i('🎤 Starting live captions...', category: LogCategory.captions);
      emit(
        const LiveCaptionsLoading(
          message: 'Initializing spatial caption system...',
        ),
      );

      // Note: Spatial caption integration service should be initialized
      // when AR services start, not when captions start
      _logger.i(
        'ℹ️ [CAPTIONS CUBIT] Spatial caption integration service should already be initialized by AR services',
        category: LogCategory.captions,
      );

      emit(
        const LiveCaptionsLoading(message: 'Initializing speech processing...'),
      );

      if (!_speechProcessor.isReady) {
        // Subscribe to Gemma enhancement events to show progress
        StreamSubscription? gemmaProgressSubscription;
        if (_useEnhancement) {
          gemmaProgressSubscription = _speechProcessor
              .gemma3nService
              .enhancementEvents
              .listen((event) {
                if (!event.isComplete && event.error == null) {
                  emit(
                    LiveCaptionsLoading(
                      message: event.message,
                      progress: event.progress,
                    ),
                  );
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
        _logger.i(
          '🔍 [CAPTIONS CUBIT] Setting up enhanced caption subscription...',
          category: LogCategory.captions,
        );
        _logger.i(
          '🔍 [CAPTIONS CUBIT] _useEnhancement: $_useEnhancement, hasGemmaEnhancement: ${_speechProcessor.hasGemmaEnhancement}',
          category: LogCategory.captions,
        );
        _captionSubscription = _speechProcessor.enhancedCaptions.listen(
          _handleEnhancedCaption,
          onError: (error, stackTrace) {
            _logger.e(
              '❌ [CAPTIONS CUBIT] Error in enhanced captions stream',
              category: LogCategory.captions,
              error: error,
              stackTrace: stackTrace,
            );
          },
          onDone: () {
            _logger.w(
              '⚠️ [CAPTIONS CUBIT] Enhanced captions stream closed',
              category: LogCategory.captions,
            );
          },
        );
        _logger.i(
          '✨ Subscribed to enhanced captions stream.',
          category: LogCategory.captions,
        );
      } else {
        _logger.i(
          '🔍 [CAPTIONS CUBIT] Setting up raw speech subscription (enhancement: $_useEnhancement, ready: ${_speechProcessor.isReady})',
          category: LogCategory.captions,
        );
        _captionSubscription = _speechProcessor.speechResults.listen(
          _handleRawSpeechResult,
          onError: (error, stackTrace) {
            _logger.e(
              '❌ [CAPTIONS CUBIT] Error in speech results stream',
              category: LogCategory.captions,
              error: error,
              stackTrace: stackTrace,
            );
          },
          onDone: () {
            _logger.w(
              '⚠️ [CAPTIONS CUBIT] Speech results stream closed',
              category: LogCategory.captions,
            );
          },
        );
        _logger.i(
          '📝 Subscribed to raw speech results stream.',
          category: LogCategory.captions,
        );
      }

      // Pass the speech config during processing start
      final started = await _speechProcessor.startProcessing(
        config: _speechConfig,
      );
      if (!started) {
        final Object? startError = _speechProcessor.lastStartProcessingError;
        final StackTrace? startErrorStackTrace =
            _speechProcessor.lastStartProcessingStackTrace;
        final String? errorDetails = startError?.toString();
        final bool permissionDenied =
            errorDetails != null &&
            errorDetails.contains('Microphone permission');

        final String userFacingMessage = permissionDenied
            ? 'Microphone access is required to start live captions. Please enable the microphone permission in Settings.'
            : 'Failed to start live captions';

        final exception = LiveCaptionsStartException(
          userFacingMessage,
          errorDetails,
        );

        _logger.e(
          '❌ Unable to start live captions because speech processing could not begin',
          category: LogCategory.captions,
          error: startError ?? exception,
          stackTrace: startErrorStackTrace,
        );

        await _captionSubscription?.cancel();
        _captionSubscription = null;

        emit(
          LiveCaptionsError(message: userFacingMessage, details: errorDetails),
        );
        throw exception;
      }

      // We no longer emit an "Active" state here immediately. The first
      // received caption will transition the state from Loading to Active.
      _logger.i(
        '✅ Live captions started successfully, waiting for first result...',
        category: LogCategory.captions,
      );
    } catch (e) {
      if (state is! LiveCaptionsError) {
        _logger.e(
          '❌ Failed to start live captions: $e',
          category: LogCategory.captions,
          error: e,
        );
        emit(
          LiveCaptionsError(
            message: 'Failed to start live captions',
            details: e.toString(),
          ),
        );
      }
      rethrow;
    }
  }

  void _handleEnhancedCaption(EnhancedCaption caption) async {
    _logger.i(
      '📋📥 [CAPTIONS CUBIT] Received enhanced caption: "${caption.displayText}" (final: ${caption.isFinal}, enhanced: ${caption.isEnhanced})',
      category: LogCategory.captions,
    );

    final currentState = state is LiveCaptionsActive
        ? (state as LiveCaptionsActive)
        : LiveCaptionsActive(
            isListening: true,
            hasEnhancement: _useEnhancement,
            captions: [],
            predictiveState: _latestPredictiveState,
          );

    if (caption.isFinal) {
      _captionHistory.add(caption);
      if (_captionHistory.length > 50) _captionHistory.removeAt(0);
      _logger.i(
        '📚 [CAPTIONS CUBIT] Added FINAL caption to history (${_captionHistory.length} total)',
        category: LogCategory.captions,
      );

      final displayText = caption.displayText;
      _logger.d(
        '🎯 Processing final caption through spatial integration: "$displayText"',
      );

      // Create speech result for spatial caption integration
      final speechResult = _buildSpeechResult(
        text: displayText,
        confidence: caption.confidence,
        isFinal: true,
        timestamp: caption.timestamp,
      );

      _publishContextFrame(speechResult);

      // Process through spatial caption integration service
      await _spatialCaptionIntegrationService.processFinalResult(speechResult);

      emit(
        currentState.copyWith(
          captions: _captionHistory
              .map(
                (c) => SpeechResult(
                  text: c.displayText,
                  confidence: c.confidence,
                  isFinal: c.isFinal,
                  timestamp: c.timestamp,
                ),
              )
              .toList(),
          currentCaption: null,
          hasEnhancement: caption.isEnhanced,
          predictiveState: _latestPredictiveState,
        ),
      );
      _logger.i(
        '📤 [CAPTIONS CUBIT] Emitted updated state with ${_captionHistory.length} captions - FINAL CAPTION SHOULD BE VISIBLE NOW',
        category: LogCategory.captions,
      );
    } else {
      _logger.i(
        '⏳ [CAPTIONS CUBIT] Processing partial caption: "${caption.displayText}"',
        category: LogCategory.captions,
      );

      // Use spatial_captions plugin for partial results (consistent with final results)
      final partialResult = _buildSpeechResult(
        text: caption.displayText,
        confidence: caption.confidence,
        isFinal: caption.isFinal,
        timestamp: caption.timestamp,
      );
      if (caption.displayText.isNotEmpty && caption.displayText.length > 3) {
        _logger.d(
          '⚡ [CAPTIONS CUBIT] Processing PARTIAL caption with spatial plugin: "${caption.displayText}"',
          category: LogCategory.captions,
        );
        try {
          _publishContextFrame(partialResult);
          // Process through spatial plugin (same as final results)
          await _spatialCaptionIntegrationService.processPartialResult(
            partialResult,
          );
          _logger.d(
            '✅ [CAPTIONS CUBIT] Partial caption processed through spatial plugin',
            category: LogCategory.captions,
          );
        } catch (e, stackTrace) {
          _logger.e(
            '❌ [CAPTIONS CUBIT] Failed to process partial caption through spatial plugin',
            category: LogCategory.captions,
            error: e,
            stackTrace: stackTrace,
          );
          // Note: No fallback - spatial plugin is the only caption system now
        }
      }

      emit(
        currentState.copyWith(
          currentCaption: partialResult,
          predictiveState: _latestPredictiveState,
        ),
      );
      _logger.i(
        '📤 [CAPTIONS CUBIT] Emitted state with partial caption - PARTIAL CAPTION SHOULD BE VISIBLE NOW',
        category: LogCategory.captions,
      );
    }
  }

  void _handleRawSpeechResult(SpeechResult result) {
    _logger.i(
      '🎤📥 [CAPTIONS CUBIT] Received raw speech result: "${result.text}" (final: ${result.isFinal})',
      category: LogCategory.captions,
    );
    final enhancedCaption = EnhancedCaption.fromSpeechResult(result);
    _handleEnhancedCaption(enhancedCaption);
  }

  SpeechResult _buildSpeechResult({
    required String text,
    required double confidence,
    required bool isFinal,
    required DateTime timestamp,
  }) {
    return SpeechResult(
      text: text,
      confidence: confidence,
      isFinal: isFinal,
      timestamp: timestamp,
      metadata: _buildSpeakerMetadata(),
    );
  }

  void _publishContextFrame(SpeechResult result) {
    if (!GetIt.I.isRegistered<PredictiveStreamHub>()) {
      return;
    }
    try {
      final hub = GetIt.I<PredictiveStreamHub>();
      final metadata = Map<String, dynamic>.from(result.metadata ?? const {});
      final dynamic faceId = metadata['speakerFaceId'];
      final speakerId = faceId != null
          ? 'face_$faceId'
          : result.speakerDirection ?? 'default';
      final confidence =
          (metadata['speakerConfidence'] as num?)?.toDouble() ??
              result.confidence;
      hub.context.publish(
        CaptionContextFrame(
          speakerId: speakerId,
          confidence: confidence.clamp(0.0, 1.0).toDouble(),
          metadata: metadata,
        ),
      );
    } catch (e, stackTrace) {
      _logger.w(
        '⚠️ Failed to publish caption context frame',
        category: LogCategory.captions,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Map<String, dynamic>? _buildSpeakerMetadata() {
    final speaker = _speakerAttributionStore.activeSpeaker;
    if (speaker == null) {
      return null;
    }
    final bbox = speaker.boundingBox;
    final metadata = <String, dynamic>{
      'speakerFaceId': speaker.faceId,
      'speakerConfidence': speaker.confidence,
      'speakerState': speaker.state.name,
      'speakerTimestamp': speaker.timestamp.toIso8601String(),
      'speakerBoundingBox': {
        'left': bbox.left,
        'top': bbox.top,
        'width': bbox.width,
        'height': bbox.height,
      },
    };
    final transform = speaker.worldTransform;
    if (transform != null) {
      metadata['speakerWorldTransform'] = transform;
    }
    return metadata;
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
      emit(
        (state as LiveCaptionsActive).copyWith(
          captions: [],
          currentCaption: null,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    stopCaptions();
    _predictiveSubscription?.cancel();
    _speechProcessor.dispose();
    return super.close();
  }
}
