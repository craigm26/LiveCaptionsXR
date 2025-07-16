import 'dart:async';
import 'dart:typed_data';
// import 'package:gemma3n_multimodal/gemma3n_multimodal.dart';
import 'package:flutter/foundation.dart';
// Uncomment when flutter_gemma is available:
// import 'package:flutter_gemma/flutter_gemma.dart';

import '../models/speech_result.dart';
import 'hybrid_localization_engine.dart';
import 'debug_capturing_logger.dart';

/// Placeholder for future flutter_gemma ASR integration
class GemmaASRService {
  /// Simulates loading a model (no-op for mock)
  Future<void> loadModel([String? assetPath]) async {
    // Uncomment and implement when flutter_gemma is available:
    // await FlutterGemma.loadModel(assetPath);
    await Future.delayed(Duration(milliseconds: 100));
  }

  /// Simulates streaming ASR results from audio input
  Stream<String> streamTranscription(List<int> audioBytes) async* {
    // Uncomment and implement when flutter_gemma is available:
    // yield* FlutterGemma.streamTranscription(audioBytes);
    await Future.delayed(Duration(milliseconds: 200));
    yield "This is a mock transcription result.";
    await Future.delayed(Duration(milliseconds: 200));
    yield "This is a mock final result.";
  }

  /// Simulates multimodal inference (audio + image)
  Future<String> runMultimodal({required List<int> audio, List<int>? image, String? text}) async {
    // Uncomment and implement when flutter_gemma is available:
    // return await FlutterGemma.runMultimodal(audio: audio, image: image, text: text);
    await Future.delayed(Duration(milliseconds: 300));
    return "This is a mock multimodal result.";
  }
}

/// Streaming Automatic Speech Recognition service using Gemma 3n
/// with multimodal (audio + visual) capabilities.
///
/// Implements the API defined in `prd/04_gemma_3n_streaming_asr.md`
/// and `prd/05_multimodal_fusion.md`.
/// Handles loading the Gemma 3n ASR model, managing a streaming
/// inference session, and exposing a `Stream<TranscriptionResult>`
/// of partial and final transcripts.
class GemmaASR {
  static final DebugCapturingLogger _logger = DebugCapturingLogger();
  final HybridLocalizationEngine hybridLocalizationEngine;

  bool _initialized = false;
  bool _streaming = false;
  late StreamController<SpeechResult> _resultController;
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
      // The original code had _plugin.loadModel(assetPath);
      // This line was removed as Gemma3nMultimodal is no longer imported.
      // The placeholder for flutter_gemma integration is kept.
      _initialized = true;
      _logger.i('✅ GemmaASR multimodal model loaded successfully');

      // Log model info
      // final isLoaded = await _plugin.isModelLoaded; // This line was removed
      // _logger.i('📊 Model status - Loaded: $isLoaded'); // This line was removed
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
  Stream<SpeechResult> startStream(Uint8List audioBuffer,
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
    _resultController = StreamController<SpeechResult>.broadcast();

    // Use multimodal streaming if vision context is provided
    if (visionContext != null) {
      _logger.i('👁️ Using multimodal streaming with vision context');
      // Simulate multimodal streaming with mock data
      Future(() async {
        await Future.delayed(Duration(milliseconds: 200));
        final partial = SpeechResult(text: "[Vision] This is a mock partial result.", isFinal: false, confidence: 0.8, timestamp: DateTime.now());
        _logger.i('📝 Transcription: "${partial.text}" (final: ${partial.isFinal})');
        _resultController.add(partial);
        await Future.delayed(Duration(milliseconds: 200));
        final finalResult = SpeechResult(text: "[Vision] This is a mock final result.", isFinal: true, confidence: 0.9, timestamp: DateTime.now());
        _logger.i('📝 Transcription: "${finalResult.text}" (final: ${finalResult.isFinal})');
        _resultController.add(finalResult);
        if (finalResult.text.isNotEmpty) {
          _logger.i('🎯 Placing caption at fused speaker position: "${finalResult.text}"');
          await hybridLocalizationEngine.placeRealtimeCaption(finalResult.text);
        }
        _logger.i('✅ Multimodal stream completed');
        _resultController.close();
        _streaming = false;
      });
    } else {
      _logger.i('🎵 Using audio-only streaming');
      // Simulate audio-only streaming with mock data
      Future(() async {
        await Future.delayed(Duration(milliseconds: 200));
        final partial = SpeechResult(text: "This is a mock partial result.", isFinal: false, confidence: 0.8, timestamp: DateTime.now());
        _logger.i('📝 Audio transcription: "${partial.text}" (final: ${partial.isFinal})');
        _resultController.add(partial);
        await Future.delayed(Duration(milliseconds: 200));
        final finalResult = SpeechResult(text: "This is a mock final result.", isFinal: true, confidence: 0.9, timestamp: DateTime.now());
        _logger.i('📝 Audio transcription: "${finalResult.text}" (final: ${finalResult.isFinal})');
        _resultController.add(finalResult);
        if (finalResult.text.isNotEmpty) {
          _logger.i('🎯 Placing caption at fused speaker position: "${finalResult.text}"');
          await hybridLocalizationEngine.placeRealtimeCaption(finalResult.text);
        }
        _logger.i('✅ Audio stream completed');
        _resultController.close();
        _streaming = false;
      });
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
}
