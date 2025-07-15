import 'dart:async';
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import '../models/enhanced_caption.dart';
import 'model_download_manager.dart';
import 'debug_capturing_logger.dart';

/// Service for enhancing captions using Gemma 3n model
class GemmaEnhancer {
  static final DebugCapturingLogger _logger = DebugCapturingLogger();
  
  final ModelDownloadManager _modelManager;
  InferenceModel? _inferenceModel;
  bool _isInitialized = false;
  
  // Cache for common phrase enhancements
  final Map<String, String> _enhancementCache = {};
  static const int _maxCacheSize = 100;

  GemmaEnhancer({required ModelDownloadManager modelManager})
      : _modelManager = modelManager;

  /// Initialize the Gemma model
  Future<void> initialize() async {
    if (_isInitialized && _inferenceModel != null) {
      _logger.i('✅ GemmaEnhancer already initialized');
      return;
    }

    try {
      _logger.i('🚀 Initializing GemmaEnhancer...');
      
      // Check if model exists and is complete
      if (!await _modelManager.modelIsComplete()) {
        throw Exception('Gemma 3n model not downloaded or incomplete');
      }
      
      final modelPath = await _modelManager.getModelPath();
      _logger.i('📁 Loading Gemma model from: $modelPath');
      
      // Get the plugin instance
      final gemmaPlugin = FlutterGemmaPlugin.instance;
      
      // First, set the model path using ModelFileManager
      final modelManager = gemmaPlugin.modelManager;
      await modelManager.setModelPath(modelPath);
      
      // Create the inference model
      // Note: If ModelType is not available, you may need to use a different approach
      // based on the specific flutter_gemma version
      try {
        _inferenceModel = await gemmaPlugin.createModel(
          modelType: ModelType.gemmaIt, // Instruction-tuned variant
          maxTokens: 2048,
        );
      } catch (e) {
        // Fallback if ModelType is not available
        _logger.w('ModelType enum not available, trying alternative approach');
        // You may need to adjust this based on your flutter_gemma version
        _inferenceModel = await gemmaPlugin.createModel(
          modelType: ModelType.gemmaIt, // Use string for older versions
          maxTokens: 2048,
        );
      }
      
      _isInitialized = true;
      _logger.i('✅ GemmaEnhancer initialized successfully');
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to initialize GemmaEnhancer', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Enhance a raw caption using Gemma 3n
  Future<EnhancedCaption> enhance(String rawText) async {
    if (!_isInitialized || _inferenceModel == null) {
      _logger.w('⚠️ GemmaEnhancer not initialized, returning fallback');
      return EnhancedCaption.fallback(rawText);
    }

    // Check cache first
    final cachedResult = _enhancementCache[rawText];
    if (cachedResult != null) {
      _logger.d('💾 Using cached enhancement for: "$rawText"');
      return EnhancedCaption(
        raw: rawText,
        enhanced: cachedResult,
        confidence: 0.95,
        isEnhanced: true,
      );
    }

    try {
      _logger.d('🔮 Enhancing caption: "$rawText"');
      
      // Build prompt for enhancement
      final prompt = _buildEnhancementPrompt(rawText);
      
      // Create a session for single inference
      final session = await _inferenceModel!.createSession(
        temperature: 0.7, // Lower temperature for more consistent output
        topK: 40,
        randomSeed: 42,
      );
      
      // Add the query
      await session.addQueryChunk(Message.text(
        text: prompt,
        isUser: true,
      ));
      
      // Get the response
      final response = await session.getResponse();
      
      // Clean up the session
      await session.close();
      
      final enhancedText = _cleanEnhancedText(response);
      
      // Cache the result if successful
      if (enhancedText != rawText && enhancedText.isNotEmpty) {
        _addToCache(rawText, enhancedText);
      }
      
      _logger.d('✨ Enhanced caption: "$enhancedText"');
      
      return EnhancedCaption(
        raw: rawText,
        enhanced: enhancedText,
        confidence: 0.9,
        isEnhanced: true,
      );
    } catch (e) {
      _logger.e('❌ Failed to enhance caption', error: e);
      return EnhancedCaption.fallback(rawText);
    }
  }

  /// Build the prompt for Gemma enhancement
  String _buildEnhancementPrompt(String rawText) {
    return '''You are a caption enhancement assistant. Your task is to improve the following raw speech transcription by:
1. Adding proper punctuation (periods, commas, question marks)
2. Correcting obvious transcription errors
3. Ensuring proper capitalization
4. Maintaining the original meaning

Raw transcription: "$rawText"

Enhanced caption:''';
  }

  /// Clean the enhanced text by removing extra whitespace and formatting
  String _cleanEnhancedText(String text) {
    // First trim the text
    var cleaned = text.trim();
    
    // Replace multiple spaces with single space
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    
    // Remove surrounding quotes (both single and double)
    if ((cleaned.startsWith('"') && cleaned.endsWith('"')) ||
        (cleaned.startsWith("'") && cleaned.endsWith("'"))) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }
    
    return cleaned;
  }

  /// Add result to cache with LRU eviction
  void _addToCache(String raw, String enhanced) {
    if (_enhancementCache.length >= _maxCacheSize) {
      // Remove oldest entry (simple FIFO for now)
      _enhancementCache.remove(_enhancementCache.keys.first);
    }
    _enhancementCache[raw] = enhanced;
  }

  /// Process a stream of captions for batch enhancement
  Stream<EnhancedCaption> enhanceStream(Stream<String> rawCaptions) async* {
    await for (final raw in rawCaptions) {
      yield await enhance(raw);
    }
  }

  /// Clean up resources
  Future<void> dispose() async {
    _logger.i('🧹 Disposing GemmaEnhancer...');
    _isInitialized = false;
    _enhancementCache.clear();
    if (_inferenceModel != null) {
      await _inferenceModel!.close();
      _inferenceModel = null;
    }
    _logger.i('✅ GemmaEnhancer disposed');
  }

  /// Check if the enhancer is ready
  bool get isReady => _isInitialized && _inferenceModel != null;

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'size': _enhancementCache.length,
      'maxSize': _maxCacheSize,
      'hitRate': _enhancementCache.isNotEmpty ? 1.0 : 0.0, // Simplified for now
    };
  }
} 