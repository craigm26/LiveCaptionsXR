import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:gemma3n_multimodal/gemma3n_multimodal.dart';

import '../models/transcription_result.dart';
import '../utils/logger.dart';
import '../services/hybrid_localization_engine.dart';
import '../../features/home/cubit/home_cubit.dart';

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
  bool _initialized = false;
  bool _streaming = false;
  late StreamController<TranscriptionResult> _resultController;
  StreamSubscription? _pluginSubscription;
  Uint8List? _currentVisionContext;

  /// Initialize the Gemma 3n ASR model.
  ///
  /// [assetPath] is the path to the `.task` model bundled as a Flutter asset.
  /// This should be a multimodal-capable model.
  Future<void> initialize([
    String assetPath = 'assets/models/gemma-3n-E4B-it-int4.task',
  ]) async {
    if (_initialized) return;
    try {
      await _plugin.loadModel(assetPath);
      _initialized = true;
      log('✅ GemmaASR multimodal model loaded');
    } catch (e) {
      log('❌ Failed to load GemmaASR model: $e');
      rethrow;
    }
  }

  /// Start a new streaming transcription session.
  ///
  /// [audioBuffer] is the initial PCM16 mono audio buffer to transcribe.
  /// [visionContext] is an optional image (Uint8List) to provide visual context.
  /// Returns a broadcast stream of TranscriptionResult.
  Stream<TranscriptionResult> startStream(Uint8List audioBuffer, {Uint8List? visionContext}) {
    if (!_initialized) {
      throw StateError('GemmaASR not initialized');
    }
    if (_streaming) {
      throw StateError('GemmaASR stream already started');
    }
    _streaming = true;
    _resultController = StreamController<TranscriptionResult>.broadcast();
    _currentVisionContext = visionContext;
    // Use multimodal streaming if vision context is provided
    if (visionContext != null) {
      _pluginSubscription = _plugin.streamMultimodal(audio: audioBuffer, image: visionContext).listen(
        (event) async {
          final map = _parseResult(event);
          _resultController.add(TranscriptionResult(text: map['text'] ?? '', isFinal: map['isFinal'] ?? false));
          if (map['isFinal'] == true && (map['text'] as String?)?.isNotEmpty == true) {
            // Place caption at fused speaker position
            await HomeCubit().hybridLocalizationEngine.placeCaption(map['text']);
          }
        },
        onError: (e) {
          _resultController.addError(e);
        },
        onDone: () {
          _resultController.close();
          _streaming = false;
        },
        cancelOnError: false,
      );
    } else {
      _pluginSubscription = _plugin.streamTranscription(audioBuffer).listen(
        (event) async {
          final map = _parseResult(event);
          _resultController.add(TranscriptionResult(text: map['text'] ?? '', isFinal: map['isFinal'] ?? false));
          if (map['isFinal'] == true && (map['text'] as String?)?.isNotEmpty == true) {
            // Place caption at fused speaker position
            await HomeCubit().hybridLocalizationEngine.placeCaption(map['text']);
          }
        },
        onError: (e) {
          _resultController.addError(e);
        },
        onDone: () {
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
    _currentVisionContext = image;
    log('🖼️ GemmaASR vision context updated (will take effect on next stream start).');
  }

  /// Stop the current streaming session.
  void stopStream() {
    if (!_streaming) return;
    _pluginSubscription?.cancel();
    _pluginSubscription = null;
    _resultController.close();
    _streaming = false;
  }

  /// Parses the plugin result (JSON or Map) into a Map<String, dynamic>.
  Map<String, dynamic> _parseResult(dynamic event) {
    if (event is Map<String, dynamic>) return event;
    if (event is String) {
      try {
        return jsonDecode(event) as Map<String, dynamic>;
      } catch (_) {
        return {'text': event, 'isFinal': false};
      }
    }
    return {'text': event.toString(), 'isFinal': false};
  }
}

