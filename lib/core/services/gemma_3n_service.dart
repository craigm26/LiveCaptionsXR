import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/model.dart' as gemma_model;
import 'model_download_manager.dart';
import 'app_logger.dart';
import 'ios_model_config_service.dart';

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
/// and multimodal inference, with iOS-specific optimizations to prevent XNNPACK crashes.
class Gemma3nService {
  final AppLogger _logger = AppLogger.instance;
  final IOSModelConfigService _iosConfig = IOSModelConfigService();

  final ModelDownloadManager _modelManager;
  InferenceModel? _inferenceModel;
  bool _isInitialized = false;
  IOSModelConfig? _currentConfig;

  // Cache for common phrase enhancements
  final Map<String, String> _enhancementCache = {};
  static const int _maxCacheSize = 100;

  // New: Enhancement progress event stream for AR session integration
  final StreamController<Gemma3nEnhancementEvent> _enhancementEventController =
      StreamController<Gemma3nEnhancementEvent>.broadcast();

  // New: Expose enhancement events stream
  Stream<Gemma3nEnhancementEvent> get enhancementEvents =>
      _enhancementEventController.stream;

  Gemma3nService({required ModelDownloadManager modelManager})
      : _modelManager = modelManager;

  /// Initializes the Gemma 3n model with iOS-specific optimizations and fallback mechanisms.
  Future<void> initialize() async {
    if (_isInitialized && _inferenceModel != null) {
      _logger.i('✅ Gemma3nService already initialized',
          category: LogCategory.gemma);
      return;
    }

    try {
      _logger.i('🚀 Initializing Gemma3nService with iOS optimizations...',
          category: LogCategory.gemma);

      // Clear XNNPack cache to fix version incompatibility issues
      await _clearXNNPackCache();

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
        _logger.w(
            '⚠️ Gemma 3n model not downloaded or incomplete - service will be disabled',
            category: LogCategory.gemma);

        // Emit enhancement event for model missing (not an error, just unavailable)
        _enhancementEventController.add(const Gemma3nEnhancementEvent(
          progress: 0.0,
          message: 'Gemma 3n model not available - enhancement disabled',
          error: 'Model not downloaded',
        ));

        // Don't throw error - just mark as not initialized so app can continue
        return;
      }

      // Emit enhancement event for model loading
      _enhancementEventController.add(const Gemma3nEnhancementEvent(
        progress: 0.5,
        message: 'Loading Gemma 3n model...',
      ));

      final modelPath = await _modelManager.getModelPath(modelKey);
      _logger.i('📁 Loading Gemma model from: $modelPath',
          category: LogCategory.gemma);

      final gemmaPlugin = FlutterGemmaPlugin.instance;
      await gemmaPlugin.modelManager.setModelPath(modelPath);

      // Emit enhancement event for model creation
      _enhancementEventController.add(const Gemma3nEnhancementEvent(
        progress: 0.8,
        message: 'Creating inference model...',
      ));

      // Get iOS-optimized configuration
      _currentConfig = _iosConfig.getOptimalConfig(modelKey);
      _iosConfig.logConfiguration(_currentConfig!, modelKey);

      // Try to create model with optimal configuration first
      _inferenceModel = await _createModelWithFallback(gemmaPlugin, modelKey);

      if (_inferenceModel != null) {
        _isInitialized = true;
        _logger.i('✅ Gemma3nService initialized successfully with optimal configuration',
            category: LogCategory.gemma);

        // Emit enhancement event for initialization complete
        _enhancementEventController.add(const Gemma3nEnhancementEvent(
          progress: 1.0,
          message: 'Gemma 3n service ready',
          isComplete: true,
        ));
      } else {
        throw Exception('Failed to initialize model with any configuration');
      }
    } on TimeoutException catch (e) {
      _logger.e('⏱️ Gemma3nService initialization timed out',
          category: LogCategory.gemma, error: e);

      // Emit enhancement event for timeout
      _enhancementEventController.add(const Gemma3nEnhancementEvent(
        progress: 0.0,
        message: 'Gemma 3n initialization timed out - enhancement disabled',
        error: 'Initialization timeout',
      ));

      // Don't rethrow timeout - let app continue without enhancement
      _isInitialized = false;
      _inferenceModel = null;
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to initialize Gemma3nService',
          category: LogCategory.gemma, error: e, stackTrace: stackTrace);

      // Emit enhancement event for initialization failure
      _enhancementEventController.add(Gemma3nEnhancementEvent(
        progress: 0.0,
        message: 'Failed to initialize Gemma 3n service - enhancement disabled',
        error: e,
      ));

      // Don't rethrow error - let app continue without enhancement
      _isInitialized = false;
      _inferenceModel = null;
    }
  }

  /// Create model with fallback configurations to handle iOS XNNPACK crashes
  Future<InferenceModel?> _createModelWithFallback(
    FlutterGemmaPlugin gemmaPlugin,
    String modelKey,
  ) async {
    final configs = [
      _currentConfig!,
      _iosConfig.getDeviceOptimizedConfig(),
      _iosConfig.getFallbackConfig(),
    ];

    for (int i = 0; i < configs.length; i++) {
      final config = configs[i];
      try {
        _logger.i('🔄 Trying configuration ${i + 1}/${configs.length} for $modelKey',
            category: LogCategory.gemma);
        _iosConfig.logConfiguration(config, modelKey);

        // Add timeout to prevent freezing during model creation
        final model = await gemmaPlugin
            .createModel(
              modelType: gemma_model.ModelType.gemmaIt,
              maxTokens: config.maxTokens,
              supportImage: config.maxNumImages > 0,
              maxNumImages: config.maxNumImages,
            )
            .timeout(Duration(seconds: 300)); // 5 minutes timeout

        _logger.i('✅ Model created successfully with configuration ${i + 1}',
            category: LogCategory.gemma);
        _currentConfig = config;
        return model;
      } catch (e) {
        _logger.w('⚠️ Configuration ${i + 1} failed: $e', category: LogCategory.gemma);
        
        // If this is the last configuration, rethrow the error
        if (i == configs.length - 1) {
          rethrow;
        }
        
        // Otherwise, continue to next configuration
        await Future.delayed(Duration(seconds: 2)); // Brief delay between attempts
      }
    }

    return null;
  }

  /// Enhances a raw text string using the Gemma model.
  Future<String> enhanceText(String rawText) async {
    _logger.d('🔍 [DEBUG] enhanceText method called',
        category: LogCategory.gemma);
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
      _logger.d('💾 Using cached enhancement for: "$rawText"',
          category: LogCategory.gemma);

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
      _logger.d('🔮 Enhancing text: "$rawText"', category: LogCategory.gemma);

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
      _logger.e('✨ Not enhanced text: "$prompt"', category: LogCategory.gemma);
      final response = await session.getResponse();
      _logger.e('✨ Enhanced text 1: "$response"', category: LogCategory.gemma);

      await session.close();

      final enhancedText = _cleanEnhancedText(response);

      if (enhancedText != rawText && enhancedText.isNotEmpty) {
        _addToCache(rawText, enhancedText);
      }

      _logger.d('✨ Enhanced text: "$enhancedText"',
          category: LogCategory.gemma);

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

  // Audio transcription removed - handled by Whisper service instead

  /// Performs multimodal inference with image and text context.
  Future<String?> multimodalInference({
    required String text,
    required image,
  }) async {
    if (!_isInitialized || _inferenceModel == null) {
      _logger.w(
          '⚠️ Gemma3nService not initialized, cannot perform multimodal inference.');
      return 'Error: Service not initialized.';
    }

    try {
      _logger.d('🧠 Performing multimodal inference for text: "$text"',
          category: LogCategory.gemma);

      // Emit enhancement event for multimodal start
      _enhancementEventController.add(const Gemma3nEnhancementEvent(
        progress: 0.0,
        message: 'Starting multimodal enhancement...',
      ));

      // Create session for single inference
      final session = await _inferenceModel!.createSession();

      // Emit enhancement event for multimodal processing
      _enhancementEventController.add(const Gemma3nEnhancementEvent(
        progress: 0.3,
        message: 'Processing text and image context...',
      ));

      Message message;

      message = Message.withImage(
        text: text,
        imageBytes: image,
        isUser: true,
      );

      _logger.d('📸 Processing with image (${image.length} bytes)',
          category: LogCategory.gemma);

      // Emit enhancement event for inference
      _enhancementEventController.add(const Gemma3nEnhancementEvent(
        progress: 0.6,
        message: 'Running Gemma 3n multimodal inference...',
      ));

      // Single inference request
      _logger.d('📸 Add query chunk: $message', category: LogCategory.gemma);
      await session.addQueryChunk(message);
      _logger.d('📸 Request response', category: LogCategory.gemma);
      final response = await session.getResponse();
      _logger.d('📸 Response is $response', category: LogCategory.gemma);

      await session.close();
      _logger.d('📸 Session closed', category: LogCategory.gemma);

      final enhancedText = _cleanEnhancedText(response);

      _logger.d('🔍 Multimodal inference response: $enhancedText',
          category: LogCategory.gemma);

      // Emit enhancement event for multimodal completion
      _enhancementEventController.add(Gemma3nEnhancementEvent(
        progress: 1.0,
        message: 'Multimodal enhancement complete',
        isComplete: true,
        enhancedText: enhancedText,
      ));

      return enhancedText;
    } catch (e) {
      _logger.e('❌ Failed to perform multimodal inference', error: e);

      // Emit enhancement event for multimodal error
      _enhancementEventController.add(Gemma3nEnhancementEvent(
        progress: 0.0,
        message: 'Failed to perform multimodal inference',
        error: e,
      ));

      // Return original text as fallback
      return text;
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

  /// Analyzes an image to provide scene description for visual context
  Future<String> analyzeImageForContext(Uint8List imageData) async {
    if (!_isInitialized || _inferenceModel == null) {
      _logger.w('⚠️ Gemma3nService not initialized, cannot analyze image.');
      return 'Service not initialized';
    }

    try {
      _logger.d('📸 Analyzing image for context (${imageData.length} bytes)',
          category: LogCategory.gemma);

      // Create session for single image analysis
      final session = await _inferenceModel!.createSession();

      const prompt =
          '''Describe this scene briefly in 1-2 sentences, focusing on:
- Main objects or people visible
- Activities happening
- Setting/environment
- Any text or signs visible

Provide a concise, helpful description that could enhance live captions.''';

      final message = Message.withImage(
        text: prompt,
        imageBytes: imageData,
        isUser: true,
      );

      await session.addQueryChunk(message);
      final response = await session.getResponse();
      await session.close();
      final cleanedResponse = _cleanEnhancedText(response);

      _logger.d('🔍 Image analysis result: $cleanedResponse',
          category: LogCategory.gemma);
      return cleanedResponse;
    } catch (e) {
      _logger.e('❌ Failed to analyze image', error: e);
      return 'Error analyzing image';
    }
  }

  /// Detects and describes objects in an image for spatial context
  Future<List<String>> detectObjectsInImage(Uint8List imageData) async {
    if (!_isInitialized || _inferenceModel == null) {
      _logger.w('⚠️ Gemma3nService not initialized, cannot detect objects.');
      return [];
    }

    try {
      _logger.d('🔍 Detecting objects in image (${imageData.length} bytes)',
          category: LogCategory.gemma);

      // Create session for single object detection
      final session = await _inferenceModel!.createSession();

      const prompt =
          '''List the main objects visible in this image, one per line:
- Focus on objects that could be relevant for live captions
- Include people, furniture, electronics, vehicles, signs, etc.
- Use simple, clear object names
- Maximum 10 objects

Objects:''';

      final message = Message.withImage(
        text: prompt,
        imageBytes: imageData,
        isUser: true,
      );

      await session.addQueryChunk(message);
      final response = await session.getResponse();
      await session.close();

      // Parse response into list of objects
      final objects = response
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty && !line.startsWith('Objects:'))
          .map((line) => line.replaceAll(RegExp(r'^[-•*]\s*'), ''))
          .take(10)
          .toList();

      _logger.d('🔍 Detected objects: $objects', category: LogCategory.gemma);
      return objects;
    } catch (e) {
      _logger.e('❌ Failed to detect objects', error: e);
      return [];
    }
  }

  /// Enhances text with visual context from image
  Future<String> enhanceTextWithVisualContext({
    required String text,
    required Uint8List imageData,
    String? spatialDirection,
  }) async {
    /*final contextInfo = spatialDirection != null
        ? 'The speaker is located $spatialDirection.'
        : ''; */

    final enhancedPrompt =
        '''Enhance this caption with visual context from the image:

Original: "$text"

Provide an enhanced caption that:
- Keeps the original meaning intact
- Adds relevant visual details from the image
- Mentions spatial context if applicable
- Remains natural and concise

Enhanced:''';

    return await multimodalInference(
          text: "What do you see at the image?",
          image: imageData,
        ) ??
        text;
  }

  /// Clear XNNPack cache to fix version incompatibility issues
  Future<void> _clearXNNPackCache() async {
    try {
      _logger.i('🧹 Clearing XNNPack cache to fix version issues...');

      // Get app temp directory where XNNPack cache is stored
      final Directory tempDir = Directory.systemTemp;
      final String cachePath = '${tempDir.path}';

      // Look for XNNPack cache files and delete them
      final Directory cacheDir = Directory(cachePath);
      if (await cacheDir.exists()) {
        await for (final FileSystemEntity entity in cacheDir.list()) {
          if (entity.path.contains('xnnpack') ||
              entity.path.contains('tflite')) {
            try {
              await entity.delete(recursive: true);
              _logger.d('🗑️ Deleted cache file: ${entity.path}',
                  category: LogCategory.gemma);
            } catch (e) {
              _logger.w('⚠️ Could not delete cache file ${entity.path}: $e');
            }
          }
        }
      }

      _logger.i('✅ XNNPack cache cleared');
    } catch (e) {
      _logger.w('⚠️ Error clearing XNNPack cache (continuing anyway): $e');
    }
  }

  // Audio transcription removed - handled by Whisper service instead
}
