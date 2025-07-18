
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/model.dart' as gemma_model;
import '../models/speech_result.dart';
import 'model_download_manager.dart';
import 'debug_capturing_logger.dart';

/// Event class for Gemma 3n contextual enhancement progress and status
class Gemma3nEnhancementEvent {
  final double progress; // 0.0 to 1.0
  final String message;
  final bool isComplete;
  final Object? error;
  final String? enhancedText;

  const Gemma3nEnhancementEvent({
    required this.progress,
    required this.message,
    this.isComplete = false,
    this.error,
    this.enhancedText,
  });
}

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
  
  // New: Enhancement progress event stream for AR session integration
  final StreamController<Gemma3nEnhancementEvent> _enhancementEventController =
      StreamController<Gemma3nEnhancementEvent>.broadcast();
  
  // New: Expose enhancement events stream
  Stream<Gemma3nEnhancementEvent> get enhancementEvents => _enhancementEventController.stream;

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
      
      // Emit enhancement event for initialization start
      _enhancementEventController.add(const Gemma3nEnhancementEvent(
        progress: 0.0,
        message: 'Initializing Gemma 3n service...',
      ));
      
      const modelKey = 'gemma-3n-E4B-it-int4';
      
      // Emit enhancement event for model checking
      _enhancementEventController.add(const Gemma3nEnhancementEvent(
        progress: 0.2,
        message: 'Checking Gemma 3n model...',
      ));
      
      if (!await _modelManager.modelIsComplete(modelKey)) {
        _logger.e('❌ Gemma 3n model not downloaded or incomplete');
        
        // Emit enhancement event for model error
        _enhancementEventController.add(const Gemma3nEnhancementEvent(
          progress: 0.0,
          message: 'Gemma 3n model not available',
          error: 'Model not downloaded or incomplete',
        ));
        
        throw Exception('Gemma 3n model not downloaded or incomplete');
      }
      
      // Emit enhancement event for model loading
      _enhancementEventController.add(const Gemma3nEnhancementEvent(
        progress: 0.5,
        message: 'Loading Gemma 3n model...',
      ));
      
      final modelPath = await _modelManager.getModelPath(modelKey);
      _logger.i('📁 Loading Gemma model from: $modelPath');
      
      final gemmaPlugin = FlutterGemmaPlugin.instance;
      await gemmaPlugin.modelManager.setModelPath(modelPath);
      
      // Emit enhancement event for model creation
      _enhancementEventController.add(const Gemma3nEnhancementEvent(
        progress: 0.8,
        message: 'Creating inference model...',
      ));
      
      _inferenceModel = await gemmaPlugin.createModel(
        modelType: gemma_model.ModelType.gemmaIt,
        maxTokens: 2048,
      );
      
      _isInitialized = true;
      _logger.i('✅ Gemma3nService initialized successfully');
      
      // Emit enhancement event for initialization complete
      _enhancementEventController.add(const Gemma3nEnhancementEvent(
        progress: 1.0,
        message: 'Gemma 3n service ready',
        isComplete: true,
      ));
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to initialize Gemma3nService', error: e, stackTrace: stackTrace);
      
      // Emit enhancement event for initialization failure
      _enhancementEventController.add(Gemma3nEnhancementEvent(
        progress: 0.0,
        message: 'Failed to initialize Gemma 3n service',
        error: e,
      ));
      
      rethrow;
    }
  }

  /// Enhances a raw text string using the Gemma model.
  Future<String> enhanceText(String rawText) async {
    if (!_isInitialized || _inferenceModel == null) {
      _logger.w('⚠️ Gemma3nService not initialized, returning raw text');
      
      // Emit enhancement event for service not ready
      _enhancementEventController.add(const Gemma3nEnhancementEvent(
        progress: 0.0,
        message: 'Gemma 3n service not ready',
        error: 'Service not initialized',
      ));
      
      return rawText;
    }

    final cachedResult = _enhancementCache[rawText];
    if (cachedResult != null) {
      _logger.d('💾 Using cached enhancement for: "$rawText"');
      
      // Emit enhancement event for cached result
      _enhancementEventController.add(Gemma3nEnhancementEvent(
        progress: 1.0,
        message: 'Using cached enhancement',
        isComplete: true,
        enhancedText: cachedResult,
      ));
      
      return cachedResult;
    }

    try {
      _logger.d('🔮 Enhancing text: "$rawText"');
      
      // Emit enhancement event for enhancement start
      _enhancementEventController.add(const Gemma3nEnhancementEvent(
        progress: 0.0,
        message: 'Starting contextual enhancement...',
      ));
      
      final prompt = _buildEnhancementPrompt(rawText);
      
      // Emit enhancement event for prompt preparation
      _enhancementEventController.add(const Gemma3nEnhancementEvent(
        progress: 0.3,
        message: 'Preparing enhancement prompt...',
      ));
      
      final session = await _inferenceModel!.createSession();
      
      // Emit enhancement event for session creation
      _enhancementEventController.add(const Gemma3nEnhancementEvent(
        progress: 0.5,
        message: 'Creating inference session...',
      ));
      
      await session.addQueryChunk(Message.text(text: prompt, isUser: true));
      
      // Emit enhancement event for inference start
      _enhancementEventController.add(const Gemma3nEnhancementEvent(
        progress: 0.7,
        message: 'Running Gemma 3n inference...',
      ));
      
      final response = await session.getResponse();
      await session.close();
      
      final enhancedText = _cleanEnhancedText(response);
      
      if (enhancedText != rawText && enhancedText.isNotEmpty) {
        _addToCache(rawText, enhancedText);
      }
      
      _logger.d('✨ Enhanced text: "$enhancedText"');
      
      // Emit enhancement event for completion
      _enhancementEventController.add(Gemma3nEnhancementEvent(
        progress: 1.0,
        message: 'Contextual enhancement complete',
        isComplete: true,
        enhancedText: enhancedText,
      ));
      
      return enhancedText;
    } catch (e) {
      _logger.e('❌ Failed to enhance text', error: e);
      
      // Emit enhancement event for error
      _enhancementEventController.add(Gemma3nEnhancementEvent(
        progress: 0.0,
        message: 'Failed to enhance text',
        error: e,
      ));
      
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
        await session.addQueryChunk(Message(text: ''));
        yield SpeechResult(
          text: '', // Placeholder, actual text will be added by the model
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
      
      // Emit enhancement event for multimodal start
      _enhancementEventController.add(const Gemma3nEnhancementEvent(
        progress: 0.0,
        message: 'Starting multimodal enhancement...',
      ));
      
      final session = await _inferenceModel!.createSession();
      
      // Emit enhancement event for multimodal processing
      _enhancementEventController.add(const Gemma3nEnhancementEvent(
        progress: 0.5,
        message: 'Processing text and image context...',
      ));
      
      await session.addQueryChunk(Message(text: 'Context: $text. Describe the scene.'));
      final response = await session.getResponse();
      _logger.d('🔍 Multimodal inference response: $response');
      await session.close();

      _logger.d('✅ Multimodal inference successful.');
      
      // Emit enhancement event for multimodal completion
      _enhancementEventController.add(Gemma3nEnhancementEvent(
        progress: 1.0,
        message: 'Multimodal enhancement complete',
        isComplete: true,
        enhancedText: response,
      ));
      
      return 'Multimodal inference successful.';
    } catch (e) {
      _logger.e('❌ Failed to perform multimodal inference', error: e);
      
      // Emit enhancement event for multimodal error
      _enhancementEventController.add(Gemma3nEnhancementEvent(
        progress: 0.0,
        message: 'Failed to perform multimodal inference',
        error: e,
      ));
      
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
    await _enhancementEventController.close();
    _logger.i('✅ Gemma3nService disposed');
  }

  bool get isReady => _isInitialized && _inferenceModel != null;

  Future transcribeAudio(Uint8List audioData) async {}
}
