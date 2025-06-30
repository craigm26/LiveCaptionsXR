import 'dart:async';
import 'dart:typed_data';

import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/transcription_result.dart';
import '../utils/logger.dart';

/// Streaming Automatic Speech Recognition service using Gemma 3n
/// with multimodal (audio + visual) capabilities.
///
/// Implements the API defined in `prd/04_gemma_3n_streaming_asr.md`
/// and `prd/05_multimodal_fusion.md`.
/// Handles loading the Gemma 3n ASR model, managing a streaming
/// inference session, and exposing a `Stream<TranscriptionResult>`
/// of partial and final transcripts.
class GemmaASR {
  Interpreter? _interpreter;
  bool _initialized = false;
  bool _streaming = false;
  late StreamController<TranscriptionResult> _resultController;
  Uint8List? _visionContext;

  /// Initialize the Gemma 3n ASR model.
  ///
  /// [assetPath] is the path to the `.task` model bundled as a Flutter asset.
  /// This should be a multimodal-capable model.
  Future<void> initialize(
      [String assetPath = 'assets/models/gemma-3n-E4B-it-int4.task']) async {
    if (_initialized) return;
    try {
      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(assetPath, options: options);
      _initialized = true;
      log('✅ GemmaASR multimodal model loaded');
    } catch (e) {
      log('❌ Failed to load GemmaASR model: $e');
      rethrow;
    }
  }

  /// Start a new streaming transcription session.
  ///
  /// An optional [visionContext] image can be provided to improve
  /// transcription accuracy with visual cues.
  void startStream({Uint8List? visionContext}) {
    if (!_initialized) {
      throw StateError('GemmaASR not initialized');
    }
    if (_streaming) return;
    _streaming = true;
    _visionContext = visionContext;
    _resultController = StreamController<TranscriptionResult>.broadcast();
    if (_visionContext != null) {
      log('🖼️ GemmaASR stream started with vision context.');
    }
  }

  /// Updates the visual context for the current streaming session.
  ///
  /// [image] is a `Uint8List` representing the image data.
  void setVisionContext(Uint8List image) {
    if (!_streaming) return;
    _visionContext = image;
    log('🖼️ GemmaASR vision context updated.');
    // TODO: Feed the new image to the underlying inference engine.
  }

  /// Add an audio buffer to the current stream.
  ///
  /// [audioBuffer] should contain mono PCM samples (e.g. 16kHz Float32).
  /// If a vision context was provided, it will be used for inference.
  Future<void> addToStream(Float32List audioBuffer) async {
    if (!_streaming) return;
    try {
      // TODO: Replace this placeholder with actual Gemma 3n streaming inference.
      // This should handle both audio and the optional _visionContext.
      final energy = audioBuffer.fold<double>(0, (s, v) => s + v.abs());
      var text = energy > 1.0 ? '...' : '';
      if (_visionContext != null && text.isNotEmpty) {
        // Simulate vision context improving the transcription
        text = 'saw';
      }
      final result = TranscriptionResult(text: text, isFinal: false);
      _resultController.add(result);
    } catch (e) {
      log('⚠️ GemmaASR streaming error: $e');
    }
  }

  /// Stop the current streaming session and emit a final result.
  void stopStream() {
    if (!_streaming) return;
    // In a real implementation, this might do a final inference call.
    final text = _visionContext != null ? 'I saw the tool.' : 'I see the tool.';
    _resultController.add(TranscriptionResult(text: text, isFinal: true));
    _resultController.close();
    _streaming = false;
    _visionContext = null;
  }

  /// Stream of transcription results.
  Stream<TranscriptionResult> get results =>
      _streaming ? _resultController.stream : const Stream.empty();
}

