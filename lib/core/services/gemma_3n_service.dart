
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/core/model.dart';
import '../models/enhanced_caption.dart';
import '../models/speech_result.dart';
import 'model_download_manager.dart';
import 'debug_capturing_logger.dart';

/// A centralized service for all Gemma 3n model interactions.
///
/// This service is the single entry point for text, audio, image,
/// and multimodal inference, as outlined in the refactoring plan in
/// `prd/19_livecaptionsxr_multistage_captioning_pipeline.md`.
class Gemma3nService {
  static final DebugCapturingLogger _logger = DebugCapturingLogger();

  final ModelDownloadManager _modelManager;
  InferenceModel? _inferenceModel;
  bool _isInitialized = false;

  // Cache for common phrase enhancements
  final Map<String, String> _enhancementCache = {};
  static const int _maxCacheSize = 100;

  Gemma3nService({required ModelDownloadManager modelManager})
      : _modelManager = modelManager;

  /// Initializes the Gemma 3n model.
  Future<void> initialize() async {
    if (_isInitialized && _inferenceModel != null) {
      _logger.i('✅ Gemma3nService already initialized');
      return;
    }

    try {
      _logger.i('🚀 Initializing Gemma3nService...');
      
      if (!await _modelManager.modelIsComplete()) {
        throw Exception('Gemma 3n model not downloaded or incomplete');
      }
      
      final modelPath = await _modelManager.getModelPath();
      _logger.i('📁 Loading Gemma model from: $modelPath');
      
      final gemmaPlugin = FlutterGemmaPlugin.instance;
      await gemmaPlugin.modelManager.setModelPath(modelPath);
      
      _inferenceModel = await gemmaPlugin.createModel(
        modelType: ModelType.gemmaIt,
        maxTokens: 2048,
      );
      
      _isInitialized = true;
      _logger.i('✅ Gemma3nService initialized successfully');
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to initialize Gemma3nService', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Enhances a raw text string using the Gemma model.
  Future<String> enhanceText(String rawText) async {
    if (!_isInitialized || _inferenceModel == null) {
      _logger.w('⚠️ Gemma3nService not initialized, returning raw text');
      return rawText;
    }

    final cachedResult = _enhancementCache[rawText];
    if (cachedResult != null) {
      _logger.d('💾 Using cached enhancement for: "$rawText"');
      return cachedResult;
    }

    try {
      _logger.d('🔮 Enhancing text: "$rawText"');
      final prompt = _buildEnhancementPrompt(rawText);
      final session = await _inferenceModel!.createSession();
      await session.addQueryChunk(Message.text(text: prompt, isUser: true));
      final response = await session.getResponse();
      await session.close();
      
      final enhancedText = _cleanEnhancedText(response);
      
      if (enhancedText != rawText && enhancedText.isNotEmpty) {
        _addToCache(rawText, enhancedText);
      }
      
      _logger.d('✨ Enhanced text: "$enhancedText"');
      return enhancedText;
    } catch (e) {
      _logger.e('❌ Failed to enhance text', error: e);
      return rawText;
    }
  }

  /// Performs streaming audio-to-text transcription.
  Stream<SpeechResult> streamTranscription(Stream<Uint8List> audioStream) async* {
    if (!_isInitialized || _inferenceModel == null) {
      _logger.e('Gemma3nService not initialized, cannot perform transcription.');
      throw StateError('Service not initialized');
    }

    _logger.i('🎙️ Starting Gemma streaming transcription...');
    final session = await _inferenceModel!.createSession();
    
    await for (final audioChunk in audioStream) {
      try {
        final response = await session.addQueryChunk(Message(parts: [Part.audio(audioChunk)]));
        yield SpeechResult(
          text: response,
          confidence: 0.9, // Placeholder
          isFinal: false, // Placeholder
          timestamp: DateTime.now(),
        );
      } catch (e) {
        _logger.e('❌ Error during Gemma streaming transcription', error: e);
        yield SpeechResult(
          text: 'Error during transcription',
          confidence: 0.0,
          isFinal: true,
          timestamp: DateTime.now(),
        );
      }
    }
    await session.close();
    _logger.i('✅ Gemma streaming transcription finished.');
  }

  /// Performs multimodal inference with image and text context.
  Future<String?> multimodalInference({
    required String text,
    Uint8List? image,
  }) async {
    if (!_isInitialized || _inferenceModel == null) {
      _logger.w('⚠️ Gemma3nService not initialized, cannot perform multimodal inference.');
      return 'Error: Service not initialized.';
    }

    try {
      _logger.d('🧠 Performing multimodal inference for text: "$text"');
      final session = await _inferenceModel!.createSession();
      
      final response = await session.addQueryChunk(Message(
        parts: [
          if (image != null) Part.image(image),
          Part.text('Context: $text. Describe the scene.'),
        ],
      ));

      await session.close();

      _logger.d('✅ Multimodal inference successful.');
      return response;
    } catch (e) {
      _logger.e('❌ Failed to perform multimodal inference', error: e);
      return 'Error performing multimodal inference.';
    }
  }

  String _buildEnhancementPrompt(String rawText) {
    return '''Improve the following transcription by adding punctuation, correcting errors, and ensuring proper capitalization.
Raw: "$rawText"
Enhanced:''';
  }

  String _cleanEnhancedText(String text) {
    var cleaned = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if ((cleaned.startsWith('"') && cleaned.endsWith('"')) ||
        (cleaned.startsWith("'") && cleaned.endsWith("'"))) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }
    return cleaned;
  }

  void _addToCache(String raw, String enhanced) {
    if (_enhancementCache.length >= _maxCacheSize) {
      _enhancementCache.remove(_enhancementCache.keys.first);
    }
    _enhancementCache[raw] = enhanced;
  }

  Future<void> dispose() async {
    _logger.i('🧹 Disposing Gemma3nService...');
    _isInitialized = false;
    _enhancementCache.clear();
    if (_inferenceModel != null) {
      await _inferenceModel!.close();
      _inferenceModel = null;
    }
    _logger.i('✅ Gemma3nService disposed');
  }

  bool get isReady => _isInitialized && _inferenceModel != null;

  Future transcribeAudio(Uint8List audioData) async {}
}
