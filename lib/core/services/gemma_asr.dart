import 'dart:async';
import 'dart:typed_data';

import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/transcription_result.dart';
import '../utils/logger.dart';

/// Streaming Automatic Speech Recognition service using Gemma 3n
///
/// Implements the API defined in `prd/04_gemma_3n_streaming_asr.md`.
/// Handles loading the Gemma 3n ASR model, managing a streaming
/// inference session, and exposing a `Stream<TranscriptionResult>`
/// of partial and final transcripts.
class GemmaASR {
  Interpreter? _interpreter;
  bool _initialized = false;
  bool _streaming = false;
  late StreamController<TranscriptionResult> _resultController;

  /// Initialize the Gemma 3n ASR model.
  ///
  /// [assetPath] is the path to the `.task` model bundled as a Flutter asset.
  Future<void> initialize([String assetPath = 'assets/models/gemma3n_asr.task']) async {
    if (_initialized) return;
    try {
      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(assetPath, options: options);
      _initialized = true;
      log('✅ GemmaASR model loaded');
    } catch (e) {
      log('❌ Failed to load GemmaASR model: $e');
      rethrow;
    }
  }

  /// Start a new streaming transcription session.
  void startStream() {
    if (!_initialized) {
      throw StateError('GemmaASR not initialized');
    }
    if (_streaming) return;
    _streaming = true;
    _resultController = StreamController<TranscriptionResult>.broadcast();
  }

  /// Add an audio buffer to the current stream.
  ///
  /// [audioBuffer] should contain mono PCM samples (e.g. 16kHz Float32).
  Future<void> addToStream(Float32List audioBuffer) async {
    if (!_streaming) return;
    try {
      // TODO: Replace this placeholder with actual Gemma 3n streaming inference.
      // Here we simply emit a fake partial result based on audio energy.
      final energy = audioBuffer.fold<double>(0, (s, v) => s + v.abs());
      final text = energy > 1.0 ? '...' : '';
      final result = TranscriptionResult(text: text, isFinal: false);
      _resultController.add(result);
    } catch (e) {
      log('⚠️ GemmaASR streaming error: $e');
    }
  }

  /// Stop the current streaming session and emit a final result.
  void stopStream() {
    if (!_streaming) return;
    _resultController.add(const TranscriptionResult(text: '', isFinal: true));
    _resultController.close();
    _streaming = false;
  }

  /// Stream of transcription results.
  Stream<TranscriptionResult> get results =>
      _streaming ? _resultController.stream : const Stream.empty();
}

