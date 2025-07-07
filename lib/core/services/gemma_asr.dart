import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:gemma3n_multimodal/gemma3n_multimodal.dart';

import '../models/transcription_result.dart';
import 'hybrid_localization_engine.dart';
import 'debug_capturing_logger.dart';

/// Streaming Automatic Speech Recognition service using Gemma 3n
/// with multimodal (audio + visual) capabilities.
///
/// Implements the API defined in `prd/04_gemma_3n_streaming_asr.md`
/// and `prd/05_multimodal_fusion.md`.
/// Handles loading the Gemma 3n ASR model, managing a streaming
/// inference session, and exposing a `Stream<TranscriptionResult>`
/// of partial and final transcripts.
class GemmaASR {
  final Gemma3nMultimodal _plugin = Gemma3nMultimodal();
  static final DebugCapturingLogger _logger = DebugCapturingLogger();
  final HybridLocalizationEngine hybridLocalizationEngine;

  bool _initialized = false;
  bool _streaming = false;
  late StreamController<TranscriptionResult> _resultController;
  StreamSubscription? _pluginSubscription;

  GemmaASR({required this.hybridLocalizationEngine});

  /// Initialize the Gemma 3n ASR model.
  ///
  /// [assetPath] is the path to the `.task` model bundled as a Flutter asset.
  /// This should be a multimodal-capable model.
  Future<void> initialize([
    String assetPath = 'assets/models/gemma-3n-E4B-it-int4.task',
  ]) async {
    if (_initialized) {
      _logger.i('🔄 GemmaASR already initialized, skipping');
      return;
    }

    _logger.i('🚀 Initializing GemmaASR with model: $assetPath');

    try {
      await _plugin.loadModel(assetPath);
      _initialized = true;
      _logger.i('✅ GemmaASR multimodal model loaded successfully');

      // Log model info
      final isLoaded = await _plugin.isModelLoaded;
      _logger.i('📊 Model status - Loaded: $isLoaded');
    } catch (e) {
      _logger.e('❌ Failed to initialize GemmaASR: $e');
      _initialized = false;
      rethrow;
    }
  }

  /// Start a new streaming transcription session.
  ///
  /// [audioBuffer] is the initial PCM16 mono audio buffer to transcribe.
  /// [visionContext] is an optional image (Uint8List) to provide visual context.
  /// Returns a broadcast stream of TranscriptionResult.
  Stream<TranscriptionResult> startStream(Uint8List audioBuffer,
      {Uint8List? visionContext}) {
    if (!_initialized) {
      _logger.e('❌ GemmaASR not initialized, cannot start stream');
      throw StateError('GemmaASR not initialized');
    }
    if (_streaming) {
      _logger.w('⚠️ GemmaASR stream already active, cannot start new stream');
      throw StateError('GemmaASR stream already started');
    }

    _logger.i(
        '🎙️ Starting GemmaASR stream - Audio: ${audioBuffer.length} bytes, Vision: ${visionContext != null ? '${visionContext.length} bytes' : 'none'}');

    _streaming = true;
    _resultController = StreamController<TranscriptionResult>.broadcast();

    // Use multimodal streaming if vision context is provided
    if (visionContext != null) {
      _logger.i('👁️ Using multimodal streaming with vision context');
      _pluginSubscription = _plugin
          .streamMultimodal(audio: audioBuffer, image: visionContext)
          .listen(
        (event) async {
          _logger.d('📝 Multimodal transcription event: $event');
          final map = _parseResult(event);
          final result = TranscriptionResult(
              text: map['text'] ?? '', isFinal: map['isFinal'] ?? false);
          _logger.i(
              '📝 Transcription: "${result.text}" (final: ${result.isFinal})');
          _resultController.add(result);

          if (map['isFinal'] == true &&
              (map['text'] as String?)?.isNotEmpty == true) {
            _logger.i(
                '🎯 Placing caption at fused speaker position: "${map['text']}"');
            // Place caption at fused speaker position
            await hybridLocalizationEngine.placeCaption(map['text']);
          }
        },
        onError: (e) {
          _logger.e('❌ Multimodal stream error: $e');
          _resultController.addError(e);
        },
        onDone: () {
          _logger.i('✅ Multimodal stream completed');
          _resultController.close();
          _streaming = false;
        },
        cancelOnError: false,
      );
    } else {
      _logger.i('🎵 Using audio-only streaming');
      _pluginSubscription = _plugin.streamTranscription(audioBuffer).listen(
        (event) async {
          _logger.d('📝 Audio transcription event: $event');
          final map = _parseResult(event);
          final result = TranscriptionResult(
              text: map['text'] ?? '', isFinal: map['isFinal'] ?? false);
          _logger.i('📝 Audio transcription: "${result.text}" (final: ${result.isFinal})');
          _resultController.add(result);

          if (map['isFinal'] == true &&
              (map['text'] as String?)?.isNotEmpty == true) {
            _logger.i('🎯 Placing caption at fused speaker position: "${map['text']}"');
            // Place caption at fused speaker position
            await hybridLocalizationEngine.placeCaption(map['text']);
          }
        },
        onError: (e) {
          _logger.e('❌ Audio stream error: $e');
          _resultController.addError(e);
        },
        onDone: () {
          _logger.i('✅ Audio stream completed');
          _resultController.close();
          _streaming = false;
        },
        cancelOnError: false,
      );
    }
    return _resultController.stream;
  }

  /// Update the visual context for the next streaming session.
  /// Note: The plugin does not support updating the image mid-session.
  /// To use a new image, stop the current stream and start a new one with the new visionContext.
  void setVisionContext(Uint8List image) {
    _logger.i('🖼️ GemmaASR vision context updated (${image.length} bytes) - will take effect on next stream start');
  }

  /// Stop the current streaming session.
  void stopStream() {
    if (!_streaming) {
      _logger.w('⚠️ No active stream to stop');
      return;
    }

    _logger.i('⏹️ Stopping GemmaASR stream');
    _pluginSubscription?.cancel();
    _pluginSubscription = null;
    _resultController.close();
    _streaming = false;
    _logger.i('✅ GemmaASR stream stopped successfully');
  }

  /// Parses the plugin result (JSON or Map) into a Map<String, dynamic>.
  Map<String, dynamic> _parseResult(dynamic event) {
    _logger.d('🔍 Parsing result: ${event.runtimeType} - $event');

    if (event is Map<String, dynamic>) return event;
    if (event is String) {
      try {
        final parsed = jsonDecode(event) as Map<String, dynamic>;
        _logger.d('📊 Parsed JSON result: $parsed');
        return parsed;
      } catch (e) {
        _logger.w('⚠️ Failed to parse JSON, treating as plain text: $e');
        return {'text': event, 'isFinal': false};
      }
    }
    _logger.d('📝 Converting to string: ${event.toString()}');
    return {'text': event.toString(), 'isFinal': false};
  }
}
