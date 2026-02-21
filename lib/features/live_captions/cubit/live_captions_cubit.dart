import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter/services.dart';

import '../../../core/models/enhanced_caption.dart';
import '../../../core/models/speech_result.dart';
import '../../../core/models/speech_config.dart';
import '../../../core/services/enhanced_speech_processor.dart';
import '../../../core/services/hybrid_localization_engine.dart';
import '../../../core/services/spatial_caption_integration_service.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/services/debug_logger_service.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/services/nexa_llm_service.dart';
import '../../../core/di/service_locator.dart';
import 'live_captions_state.dart';

/// A unified Cubit for managing live captions, with optional enhancement.
///
/// This Cubit handles the logic for starting, stopping, and processing
/// speech results, and can optionally use the enhanced caption stream
/// from the [EnhancedSpeechProcessor].
class LiveCaptionsCubit extends Cubit<LiveCaptionsState> {
  static const String _fallbackActivityText = 'Listening...';
  static const String _startupDebugWavDevicePath =
      '/storage/emulated/0/Download/king_injustice.wav';
  static const String _startupDebugWavAppExternalPath =
      '/storage/emulated/0/Android/data/com.livecaptionsxr.app/files/king_injustice.wav';
  static const String _startupDebugWavAppExternalPathAlt =
      '/sdcard/Android/data/com.livecaptionsxr.app/files/king_injustice.wav';
  static const String _startupDebugWavAppInternalPath =
      '/data/user/0/com.livecaptionsxr.app/files/king_injustice.wav';
  static const String _startupDebugWavAppInternalPathAlt =
      '/data/data/com.livecaptionsxr.app/files/king_injustice.wav';
  static const String _startupDebugWavHostPath =
      r'C:\Users\CraigM\Downloads\king_injustice.wav';
  static const MethodChannel _debugAudioChannel =
      MethodChannel('live_captions_xr/debug_audio');
  final EnhancedSpeechProcessor _speechProcessor;
  final HybridLocalizationEngine _hybridLocalizationEngine;
  final SpatialCaptionIntegrationService _spatialCaptionIntegrationService;
  final AppLogger _logger = AppLogger.instance;
  final FlutterSoundPlayer _startupDebugPlayer = FlutterSoundPlayer();

  StreamSubscription? _captionSubscription;
  final List<EnhancedCaption> _captionHistory = [];
  bool _useEnhancement;
  bool _enhancedCaptionsEnabled;
  bool _enhancedCaptionsActive = false;
  SpeechConfig? _speechConfig;
  bool _startupDebugPlayerReady = false;
  bool _startupDebugWhisperTriggered = false;

  /// Per-speaker angle in radians (from speakerPosition or speakerDirection).
  final Map<String, double> _speakerAngles = {};

  LiveCaptionsCubit({
    required EnhancedSpeechProcessor speechProcessor,
    required HybridLocalizationEngine hybridLocalizationEngine,
    required SpatialCaptionIntegrationService spatialCaptionIntegrationService,
    bool useEnhancement = true,
    bool enhancedCaptionsEnabled = false,
    SpeechConfig? speechConfig,
  })  : _speechProcessor = speechProcessor,
        _hybridLocalizationEngine = hybridLocalizationEngine,
        _spatialCaptionIntegrationService = spatialCaptionIntegrationService,
        _useEnhancement = useEnhancement,
        _enhancedCaptionsEnabled = enhancedCaptionsEnabled,
        _speechConfig = speechConfig,
        super(const LiveCaptionsInitial());

  /// Update speech configuration (useful for changing whisper settings)
  void updateSpeechConfig(SpeechConfig config) {
    _speechConfig = config;
    _logger.i('⚙️ Updated speech config: ${config.whisperModel}',
        category: LogCategory.captions);
  }

  void setEnhancementEnabled(bool enabled) {
    _useEnhancement = enabled;
    _speechProcessor.setEnhancementEnabled(enabled);
    _logger.i('✨ Caption enhancement ${enabled ? 'enabled' : 'disabled'}',
        category: LogCategory.captions);
  }

  void setEnhancedCaptionsEnabled(bool enabled) {
    _enhancedCaptionsEnabled = enabled;
    _logger.i('🎯 Enhanced captions ${enabled ? 'requested' : 'disabled'}',
        category: LogCategory.captions);
    if (!enabled) {
      _enhancedCaptionsActive = false;
    }
  }

  Future<void> startCaptions() async {
    if (state is LiveCaptionsActive &&
        (state as LiveCaptionsActive).isListening) {
      _logger.i('🎤 Live captions already listening, skipping start',
          category: LogCategory.captions);
      return;
    }

    try {
      _logger.i('🎤 Starting live captions...', category: LogCategory.captions);
      _logger.d(
          '🧭 Localization engine active: ${_hybridLocalizationEngine.runtimeType}',
          category: LogCategory.captions);
      _speechProcessor.setEnhancementEnabled(_useEnhancement);
      emit(const LiveCaptionsLoading(
          message: 'Initializing spatial caption system...'));

      // Note: Spatial caption integration service should be initialized
      // when AR services start, not when captions start
      _logger.i(
          'ℹ️ [CAPTIONS CUBIT] Spatial caption integration service should already be initialized by AR services',
          category: LogCategory.captions);

      emit(const LiveCaptionsLoading(
          message: 'Initializing speech processing...'));

      if (!_speechProcessor.isReady) {
        // Subscribe to Gemma enhancement events to show progress
        StreamSubscription? gemmaProgressSubscription;
        if (_useEnhancement) {
          gemmaProgressSubscription =
              _speechProcessor.gemma3nService.enhancementEvents.listen((event) {
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
        _logger.w(
            '⚠️ Enhancement requested but no enhancement backend is ready; auto-disabling enhancement for this session',
            category: LogCategory.captions);
        _useEnhancement = false;
        _speechProcessor.setEnhancementEnabled(false);
      }

      final useEnhancedStream = _useEnhancement;

      // The UI will remain in the "loading" state until the first caption is received.
      if (useEnhancedStream) {
        _logger.i(
            '🔍 [CAPTIONS CUBIT] Setting up enhanced caption subscription...',
            category: LogCategory.captions);
        _logger.i(
            '🔍 [CAPTIONS CUBIT] _useEnhancement: $_useEnhancement, hasEnhancement: ${_speechProcessor.hasEnhancement}, hasGemmaEnhancement: ${_speechProcessor.hasGemmaEnhancement}',
            category: LogCategory.captions);
        _captionSubscription = _speechProcessor.enhancedCaptions.listen(
          _handleEnhancedCaption,
          onError: (error, stackTrace) {
            _logger.e('❌ [CAPTIONS CUBIT] Error in enhanced captions stream',
                category: LogCategory.captions,
                error: error,
                stackTrace: stackTrace);
          },
          onDone: () {
            _logger.w('⚠️ [CAPTIONS CUBIT] Enhanced captions stream closed',
                category: LogCategory.captions);
          },
        );
        _logger.i('✨ Subscribed to enhanced captions stream.',
            category: LogCategory.captions);
      } else {
        _logger.i(
            '🔍 [CAPTIONS CUBIT] Setting up raw speech subscription (enhancement requested: $_useEnhancement, enhancement ready: ${_speechProcessor.hasEnhancement}, processor ready: ${_speechProcessor.isReady})',
            category: LogCategory.captions);
        _captionSubscription = _speechProcessor.speechResults.listen(
          _handleRawSpeechResult,
          onError: (error, stackTrace) {
            _logger.e('❌ [CAPTIONS CUBIT] Error in speech results stream',
                category: LogCategory.captions,
                error: error,
                stackTrace: stackTrace);
          },
          onDone: () {
            _logger.w('⚠️ [CAPTIONS CUBIT] Speech results stream closed',
                category: LogCategory.captions);
          },
        );
        _logger.i('📝 Subscribed to raw speech results stream.',
            category: LogCategory.captions);
      }

      // Pass the speech config during processing start
      await _speechProcessor.startProcessing(config: _speechConfig);

      // Check if Enhanced Captions mode can activate (requires OmniNeural-4B).
      if (_enhancedCaptionsEnabled) {
        try {
          _enhancedCaptionsActive = await NexaLlmService.isOmniNeuralDownloaded();
          _logger.i(
              '🎯 Enhanced Captions: OmniNeural downloaded = $_enhancedCaptionsActive',
              category: LogCategory.captions);
        } catch (_) {
          _enhancedCaptionsActive = false;
        }
      } else {
        _enhancedCaptionsActive = false;
      }

      emit(LiveCaptionsActive(
        captions:
            List<SpeechResult>.from(_captionHistory.map((c) => SpeechResult(
                  text: c.displayText,
                  confidence: c.confidence,
                  isFinal: c.isFinal,
                  timestamp: c.timestamp,
                ))),
        isListening: true,
        hasEnhancement: _useEnhancement,
        rawSttDebugText: null,
        enhancedCaptionsActive: _enhancedCaptionsActive,
        speakerAngles: Map.from(_speakerAngles),
      ));

      await _injectStartupCaptionVisibilityTest();

      _logger.i('✅ Live captions started successfully',
          category: LogCategory.captions);
    } catch (e) {
      _logger.e('❌ Failed to start live captions: $e',
          category: LogCategory.captions, error: e);
      emit(LiveCaptionsError(
          message: 'Failed to start live captions', details: e.toString()));
      rethrow;
    }
  }

  Future<void> _injectStartupCaptionVisibilityTest() async {
    final isEmulator = await isAndroidEmulator();
    if (!isEmulator) {
      return;
    }

    const testPhrase =
        'Caption visibility test: this is an injected startup phrase.';
    _logger.i(
        '🧪 Injecting startup caption visibility test phrase for emulator',
        category: LogCategory.captions);

    _handleRawSpeechResult(SpeechResult(
      text: testPhrase,
      confidence: 1.0,
      isFinal: true,
      timestamp: DateTime.now(),
      metadata: const {'source': 'startup_visibility_test'},
    ));

    await Future<void>.delayed(const Duration(milliseconds: 350));
    unawaited(_playStartupDebugWavOnEmulator());
    unawaited(_runStartupDebugWhisperTranscriptionOnEmulator());
  }

  Future<void> _runStartupDebugWhisperTranscriptionOnEmulator() async {
    if (!Platform.isAndroid || _startupDebugWhisperTriggered) {
      return;
    }

    _startupDebugWhisperTriggered = true;

    try {
      final candidatePaths = <String>[
        _startupDebugWavAppInternalPath,
        _startupDebugWavAppInternalPathAlt,
        _startupDebugWavAppExternalPath,
        _startupDebugWavAppExternalPathAlt,
        _startupDebugWavDevicePath,
      ];

      String? selectedPath;
      for (final path in candidatePaths) {
        try {
          if (await File(path).exists()) {
            selectedPath = path;
            break;
          }
        } catch (_) {
          // ignore inaccessible paths and continue
        }
      }

      if (selectedPath == null) {
        _logger.w(
          '⚠️ Startup debug Whisper transcription skipped: no readable WAV candidate found',
          category: LogCategory.captions,
        );
        return;
      }

      _logger.i(
          '🧪 Running startup debug Whisper transcription from $selectedPath',
          category: LogCategory.captions);
      final result =
          await _speechProcessor.debugTranscribeWavFile(selectedPath);
      if (result == null) {
        return;
      }
      _logger.i(
          '🧪 Startup debug Whisper transcription completed with text: "${result.text}"',
          category: LogCategory.captions);
    } catch (e, stackTrace) {
      _logger.w(
        '⚠️ Startup debug Whisper transcription failed: $e',
        category: LogCategory.captions,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _playStartupDebugWavOnEmulator() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      if (!_startupDebugPlayerReady) {
        await _startupDebugPlayer.openPlayer();
        _startupDebugPlayerReady = true;
      }

      if (_startupDebugPlayer.isPlaying) {
        await _startupDebugPlayer.stopPlayer();
      }

      final nativePlayed = await _tryNativeDebugAudioPlayback();
      if (nativePlayed) {
        return;
      }

      final wavFile = File(_startupDebugWavDevicePath);
      final exists = await wavFile.exists();
      if (!exists) {
        _logger.w(
          '⚠️ Startup debug WAV not found on fallback path $_startupDebugWavDevicePath. '
          'Try either:\n'
          '1) adb push "$_startupDebugWavHostPath" "$_startupDebugWavDevicePath"\n'
          '2) adb push "$_startupDebugWavHostPath" /data/local/tmp/king_injustice.wav && adb shell run-as com.livecaptionsxr.app cp /data/local/tmp/king_injustice.wav $_startupDebugWavAppInternalPath',
          category: LogCategory.captions,
        );
        return;
      }

      final fileSize = await wavFile.length();
      _logger.i(
        '🔊 Playing startup debug WAV from $_startupDebugWavDevicePath (${fileSize} bytes)',
        category: LogCategory.captions,
      );

      final whenFinished = () {
        _logger.i('✅ Startup debug WAV playback finished',
            category: LogCategory.captions);
      };

      try {
        await _startupDebugPlayer.startPlayer(
          fromURI: _startupDebugWavDevicePath,
          whenFinished: whenFinished,
        );
        return;
      } catch (_) {
        // try additional forms below
      }

      final fileUri = Uri.file(_startupDebugWavDevicePath).toString();
      try {
        await _startupDebugPlayer.startPlayer(
          fromURI: fileUri,
          whenFinished: whenFinished,
        );
        return;
      } catch (_) {
        // final attempt below
      }

      final wavBytes = await wavFile.readAsBytes();
      await _startupDebugPlayer.startPlayer(
        fromDataBuffer: wavBytes,
        codec: Codec.pcm16WAV,
        whenFinished: whenFinished,
      );
    } catch (e, stackTrace) {
      _logger.w(
        '⚠️ Failed to play startup debug WAV: $e',
        category: LogCategory.captions,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> _tryNativeDebugAudioPlayback() async {
    try {
      final candidatePaths = <String>[
        _startupDebugWavAppInternalPath,
        _startupDebugWavAppInternalPathAlt,
        _startupDebugWavAppExternalPath,
        _startupDebugWavAppExternalPathAlt,
        _startupDebugWavDevicePath,
      ];

      final didPlay =
          await _debugAudioChannel.invokeMethod<bool>('playDebugWav', {
        'paths': candidatePaths,
      });

      if (didPlay == true) {
        _logger.i(
          '🔊 Native debug WAV playback started. Preferred path: $_startupDebugWavAppExternalPath',
          category: LogCategory.captions,
        );
        return true;
      }
    } catch (e) {
      _logger.w(
        '⚠️ Native debug WAV playback unavailable, falling back to FlutterSound: $e. '
        'Recommended adb push target: $_startupDebugWavAppExternalPath',
        category: LogCategory.captions,
      );
    }

    return false;
  }

  Future<void> _disposeStartupDebugPlayer() async {
    if (!_startupDebugPlayerReady) {
      return;
    }

    try {
      if (_startupDebugPlayer.isPlaying) {
        await _startupDebugPlayer.stopPlayer();
      }
    } catch (_) {
      // ignore stop errors during teardown
    }

    await _startupDebugPlayer.closePlayer();
    _startupDebugPlayerReady = false;
  }

  /// Compute the angle in radians for a speech result.
  /// Uses speakerPosition.x / z if available, falls back to direction string.
  static double _angleFromResult(SpeechResult result) {
    if (result.speakerPosition != null) {
      final pos = result.speakerPosition!;
      if (pos.z != 0 || pos.x != 0) {
        return pos.x.sign * (pos.x.abs() / (pos.x.abs() + pos.z.abs().clamp(0.1, double.infinity))) * 1.5708; // ≈ π/2
      }
    }
    switch (result.speakerDirection) {
      case 'left': return -0.785; // ~-π/4
      case 'right': return 0.785;
      default: return 0.0;
    }
  }

  void _handleEnhancedCaption(EnhancedCaption caption) async {
    _logger.i(
        '📋📥 [CAPTIONS CUBIT] Received enhanced caption: "${caption.displayText}" (final: ${caption.isFinal}, enhanced: ${caption.isEnhanced})',
        category: LogCategory.captions);

    final currentState = state is LiveCaptionsActive
        ? (state as LiveCaptionsActive)
        : LiveCaptionsActive(
            isListening: true, hasEnhancement: _useEnhancement, captions: [],
            enhancedCaptionsActive: _enhancedCaptionsActive,
            speakerAngles: Map.from(_speakerAngles));

    if (caption.isFinal) {
      _captionHistory.add(caption);
      if (_captionHistory.length > 50) _captionHistory.removeAt(0);
      _logger.i(
          '📚 [CAPTIONS CUBIT] Added FINAL caption to history (${_captionHistory.length} total)',
          category: LogCategory.captions);

      var displayText = caption.displayText;

      // Apply translation if enabled
      if (sl.isRegistered<TranslationService>()) {
        final translationService = sl<TranslationService>();
        if (translationService.isEnabled) {
          try {
            _logger.d('🌐 Translating caption: "$displayText"',
                category: LogCategory.captions);
            final result = await translationService.translate(displayText);
            if (result.wasTranslated) {
              // Format: show translation, optionally with original
              if (translationService.showOriginal) {
                displayText =
                    '${result.translatedText}\n[${result.originalText}]';
              } else {
                displayText = result.translatedText;
              }
              _logger.i(
                  '🌐 Translated: "${result.originalText}" → "${result.translatedText}"',
                  category: LogCategory.captions);
            }
          } catch (e) {
            _logger.w('⚠️ Translation failed, using original: $e',
                category: LogCategory.captions);
          }
        }
      }

      _logger.d(
          '🎯 Processing final caption through spatial integration: "$displayText"');

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
        await _spatialCaptionIntegrationService
            .processFinalResult(speechResult);
      } catch (e, stackTrace) {
        spatialFinalizationFailed = true;
        _logger.w(
            '⚠️ Spatial finalization failed; keeping Flutter caption pipeline active: $e',
            category: LogCategory.captions);
        _logger.d('ℹ️ Spatial finalization stack',
            category: LogCategory.captions, error: e, stackTrace: stackTrace);
      }

      emit(currentState.copyWith(
        captions: _captionHistory
            .map((c) => SpeechResult(
                  text: c.displayText,
                  confidence: c.confidence,
                  isFinal: c.isFinal,
                  timestamp: c.timestamp,
                ))
            .toList(),
        currentCaption: null,
        hasEnhancement: caption.isEnhanced,
        showOverlayFallback:
            currentState.showOverlayFallback || spatialFinalizationFailed,
        enhancedCaptionsActive: _enhancedCaptionsActive,
        speakerAngles: Map.from(_speakerAngles),
      ));
      _logger.i(
          '📤 [CAPTIONS CUBIT] Emitted updated state with ${_captionHistory.length} captions - FINAL CAPTION SHOULD BE VISIBLE NOW',
          category: LogCategory.captions);
    } else {
      _logger.i(
          '⏳ [CAPTIONS CUBIT] Processing partial caption: "${caption.displayText}"',
          category: LogCategory.captions);

      // Use spatial_captions plugin for partial results (consistent with final results)
      if (caption.displayText.isNotEmpty && caption.displayText.length > 3) {
        _logger.d(
            '⚡ [CAPTIONS CUBIT] Processing PARTIAL caption with spatial plugin: "${caption.displayText}"',
            category: LogCategory.captions);
        try {
          // Create SpeechResult for spatial processing
          final speechResult = SpeechResult(
            text: caption.displayText,
            confidence: caption.confidence,
            isFinal: caption.isFinal,
            timestamp: caption.timestamp,
          );

          // Process through spatial plugin (same as final results)
          await _spatialCaptionIntegrationService
              .processPartialResult(speechResult);
          _logger.d(
              '✅ [CAPTIONS CUBIT] Partial caption processed through spatial plugin',
              category: LogCategory.captions);
        } catch (e, stackTrace) {
          _logger.e(
              '❌ [CAPTIONS CUBIT] Failed to process partial caption through spatial plugin',
              category: LogCategory.captions,
              error: e,
              stackTrace: stackTrace);
          // Note: No fallback - spatial plugin is the only caption system now
        }
      }

      emit(currentState.copyWith(
          currentCaption: SpeechResult(
        text: caption.displayText,
        confidence: caption.confidence,
        isFinal: caption.isFinal,
        timestamp: caption.timestamp,
      )));
      _logger.i(
          '📤 [CAPTIONS CUBIT] Emitted state with partial caption - PARTIAL CAPTION SHOULD BE VISIBLE NOW',
          category: LogCategory.captions);
    }
  }

  void _handleRawSpeechResult(SpeechResult result) {
    _logger.i(
        '🎤📥 [CAPTIONS CUBIT] Received raw speech result: "${result.text}" (final: ${result.isFinal})',
        category: LogCategory.captions);

    // Track speaker angle for Enhanced Captions sticky labels.
    if (_enhancedCaptionsActive && result.speakerId != null) {
      _speakerAngles[result.speakerId!] = _angleFromResult(result);
    }

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
    await _disposeStartupDebugPlayer();
    _startupDebugWhisperTriggered = false;

    if (state is LiveCaptionsActive) {
      final currentState = state as LiveCaptionsActive;
      emit(currentState.copyWith(
          isListening: false, currentCaption: null, rawSttDebugText: null));
      return;
    }

    emit(const LiveCaptionsInitial());
  }

  void clearCaptions() {
    _captionHistory.clear();
    if (state is LiveCaptionsActive) {
      emit((state as LiveCaptionsActive)
          .copyWith(captions: [], currentCaption: null, rawSttDebugText: null));
    }
  }

  @override
  Future<void> close() async {
    await stopCaptions();
    _speechProcessor.dispose();
    return super.close();
  }
}
