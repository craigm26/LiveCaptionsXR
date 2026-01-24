import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'app_logger.dart';
import 'gemma_3n_service.dart';
import 'nexa_asr_service.dart';

/// Event class for Nexa LLM progress and status
/// Compatible with Gemma3nEnhancementEvent for seamless integration
class NexaLlmEvent {
  final double progress; // 0.0 to 1.0
  final String message;
  final bool isComplete;
  final Object? error;
  final String? enhancedText;

  const NexaLlmEvent({
    required this.progress,
    required this.message,
    this.isComplete = false,
    this.error,
    this.enhancedText,
  });

  /// Convert to Gemma3nEnhancementEvent for compatibility with existing code
  Gemma3nEnhancementEvent toGemma3nEvent() {
    return Gemma3nEnhancementEvent(
      progress: progress,
      message: message,
      isComplete: isComplete,
      error: error,
      enhancedText: enhancedText,
    );
  }
}

/// Service for handling Nexa SDK LLM (Large Language Model) integration
///
/// This service provides on-device text enhancement and inference using Nexa SDK with:
/// - NPU acceleration on Qualcomm Snapdragon devices (92 tokens/s on Snapdragon 8 Gen 4)
/// - GPU fallback for other Android devices
/// - CPU fallback for unsupported hardware
///
/// Recommended models:
/// - Granite-4.0-h-350M-NPU: Fast text enhancement
/// - OmniNeural-4B: Multimodal with vision+text
///
/// For the Qualcomm x Nexa On-Device AI Bounty Program.
class NexaLlmService {
  static final AppLogger _logger = AppLogger.instance;

  static const MethodChannel _methodChannel =
      MethodChannel('live_captions_xr/nexa_llm');
  static const EventChannel _eventChannel =
      EventChannel('live_captions_xr/nexa_llm_events');

  bool _isInitialized = false;
  String _currentModelName = 'granite-4.0-h-350m-npu';
  NexaInferenceMode _inferenceMode = NexaInferenceMode.cpu;
  bool _supportsVision = false;

  StreamSubscription? _eventSubscription;

  // Cache for common phrase enhancements
  final Map<String, String> _enhancementCache = {};
  static const int _maxCacheSize = 100;

  // Compatible event stream with Gemma3nEnhancementEvent
  final StreamController<Gemma3nEnhancementEvent> _enhancementEventController =
      StreamController<Gemma3nEnhancementEvent>.broadcast();

  // Native Nexa event stream
  final StreamController<NexaLlmEvent> _nexaEventController =
      StreamController<NexaLlmEvent>.broadcast();

  /// Stream of enhancement events (compatible with existing Gemma3nService)
  Stream<Gemma3nEnhancementEvent> get enhancementEvents =>
      _enhancementEventController.stream;

  /// Stream of Nexa-specific events
  Stream<NexaLlmEvent> get nexaEvents => _nexaEventController.stream;

  bool get isInitialized => _isInitialized;
  bool get isReady => _isInitialized;
  String get currentModelName => _currentModelName;
  NexaInferenceMode get inferenceMode => _inferenceMode;
  bool get supportsVision => _supportsVision;
  bool get isNpuAccelerated => _inferenceMode == NexaInferenceMode.npu;

  /// Check if Nexa LLM is available on this platform
  static bool get isAvailable => Platform.isAndroid;

  /// Check if NPU acceleration is available on this device
  Future<bool> isNpuAvailable() async {
    if (!Platform.isAndroid) return false;

    try {
      final result = await _methodChannel.invokeMethod<bool>('isNpuAvailable');
      return result ?? false;
    } catch (e) {
      _logger.e('Failed to check NPU availability', error: e);
      return false;
    }
  }

  /// Initialize the Nexa LLM service with configuration
  Future<void> initialize({
    String? modelPath,
    String modelName = 'granite-4.0-h-350m-npu',
    bool preferNpu = true,
  }) async {
    if (!Platform.isAndroid) {
      _logger.w('Nexa LLM is only available on Android');
      return;
    }

    if (_isInitialized) {
      _logger.i('Nexa LLM already initialized');
      return;
    }

    try {
      // Emit enhancement event for initialization start
      _emitEvent(const NexaLlmEvent(
        progress: 0.0,
        message: 'Initializing Nexa LLM service...',
      ));

      // Start listening to native events
      _startEventListening();

      _logger.i(
          '🚀 Initializing Nexa LLM service with model: $modelName (preferNpu: $preferNpu)');

      final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'initialize',
        {
          'modelPath': modelPath,
          'modelName': modelName,
          'preferNpu': preferNpu,
        },
      );

      if (result != null && result['success'] == true) {
        _isInitialized = true;
        _currentModelName = result['modelName'] as String? ?? modelName;
        _inferenceMode =
            _parseInferenceMode(result['inferenceMode'] as String?);
        _supportsVision = result['supportsVision'] as bool? ?? false;

        _logger.i(
            '✅ Nexa LLM initialized: model=$_currentModelName, mode=${_inferenceMode.name.toUpperCase()}, vision=$_supportsVision');

        _emitEvent(NexaLlmEvent(
          progress: 1.0,
          message:
              'Nexa LLM ready (${_inferenceMode.name.toUpperCase()}, vision: $_supportsVision)',
          isComplete: true,
        ));
      } else {
        throw Exception('Initialization returned failure');
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to initialize Nexa LLM',
          error: e, stackTrace: stackTrace);

      _emitEvent(NexaLlmEvent(
        progress: 0.0,
        message: 'Failed to initialize Nexa LLM - enhancement disabled',
        error: e,
      ));

      // Don't rethrow - let app continue without enhancement
      _isInitialized = false;
    }
  }

  /// Enhance transcribed text using the LLM
  Future<String> enhanceText(String rawText) async {
    if (!_isInitialized) {
      _logger.w('Nexa LLM not initialized, returning raw text');

      _emitEvent(const NexaLlmEvent(
        progress: 0.0,
        message: 'Nexa LLM service not ready',
        error: 'Service not initialized',
      ));

      return rawText;
    }

    // Check cache first
    final cachedResult = _enhancementCache[rawText];
    if (cachedResult != null) {
      _logger.d('💾 Using cached enhancement for: "$rawText"');

      _emitEvent(NexaLlmEvent(
        progress: 1.0,
        message: 'Using cached enhancement',
        isComplete: true,
        enhancedText: cachedResult,
      ));

      return cachedResult;
    }

    try {
      _logger.d('🔮 Enhancing text with Nexa LLM: "$rawText"');

      _emitEvent(const NexaLlmEvent(
        progress: 0.0,
        message: 'Starting text enhancement...',
      ));

      final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'enhanceText',
        {'text': rawText},
      );

      if (result != null) {
        final enhancedText = result['enhanced'] as String? ?? rawText;

        if (enhancedText != rawText && enhancedText.isNotEmpty) {
          _addToCache(rawText, enhancedText);
        }

        _logger.d('✨ Enhanced text: "$enhancedText"');

        _emitEvent(NexaLlmEvent(
          progress: 1.0,
          message: 'Text enhancement complete',
          isComplete: true,
          enhancedText: enhancedText,
        ));

        return enhancedText;
      } else {
        return rawText;
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to enhance text',
          error: e, stackTrace: stackTrace);

      _emitEvent(NexaLlmEvent(
        progress: 0.0,
        message: 'Failed to enhance text',
        error: e,
      ));

      return rawText;
    }
  }

  /// Perform multimodal inference with text and optional image
  Future<String?> multimodalInference({
    required String text,
    Uint8List? imageData,
  }) async {
    if (!_isInitialized) {
      _logger.w('Nexa LLM not initialized, cannot perform multimodal inference');
      return text;
    }

    if (imageData != null && !_supportsVision) {
      _logger.w("Current model doesn't support vision, using text-only inference");
    }

    try {
      _logger.d('🧠 Performing multimodal inference for text: "$text"');

      _emitEvent(const NexaLlmEvent(
        progress: 0.0,
        message: 'Starting multimodal enhancement...',
      ));

      final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'multimodalInference',
        {
          'text': text,
          'imageData': imageData,
        },
      );

      if (result != null) {
        final enhancedText = result['result'] as String? ?? text;

        _logger.d('🔍 Multimodal inference response: $enhancedText');

        _emitEvent(NexaLlmEvent(
          progress: 1.0,
          message: 'Multimodal enhancement complete',
          isComplete: true,
          enhancedText: enhancedText,
        ));

        return enhancedText;
      }

      return text;
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to perform multimodal inference',
          error: e, stackTrace: stackTrace);

      _emitEvent(NexaLlmEvent(
        progress: 0.0,
        message: 'Failed to perform multimodal inference',
        error: e,
      ));

      return text;
    }
  }

  /// Enhance text with visual context from image
  Future<String> enhanceTextWithVisualContext({
    required String text,
    required Uint8List imageData,
    String? spatialDirection,
  }) async {
    return await multimodalInference(text: text, imageData: imageData) ?? text;
  }

  /// Analyze an image to provide scene description for visual context
  Future<String> analyzeImageForContext(Uint8List imageData) async {
    if (!_isInitialized || !_supportsVision) {
      _logger.w('Nexa LLM not ready for image analysis');
      return 'Service not ready for image analysis';
    }

    try {
      _logger.d('📸 Analyzing image for context (${imageData.length} bytes)');

      final result = await multimodalInference(
        text: 'Describe this scene briefly in 1-2 sentences, focusing on main objects, activities, setting, and any visible text.',
        imageData: imageData,
      );

      return result ?? 'Error analyzing image';
    } catch (e) {
      _logger.e('❌ Failed to analyze image', error: e);
      return 'Error analyzing image';
    }
  }

  /// Generate a custom response from the LLM
  Future<String?> generateResponse({
    required String prompt,
    int maxTokens = 256,
    double temperature = 0.7,
  }) async {
    if (!_isInitialized) {
      _logger.w('Nexa LLM not initialized');
      return null;
    }

    try {
      _logger.d('💬 Generating response for prompt');

      _emitEvent(const NexaLlmEvent(
        progress: 0.0,
        message: 'Generating response...',
      ));

      final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'generateResponse',
        {
          'prompt': prompt,
          'maxTokens': maxTokens,
          'temperature': temperature,
        },
      );

      if (result != null) {
        final response = result['response'] as String?;

        _emitEvent(NexaLlmEvent(
          progress: 1.0,
          message: 'Response generated',
          isComplete: true,
          enhancedText: response,
        ));

        return response;
      }

      return null;
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to generate response',
          error: e, stackTrace: stackTrace);

      _emitEvent(NexaLlmEvent(
        progress: 0.0,
        message: 'Failed to generate response',
        error: e,
      ));

      return null;
    }
  }

  /// Clear the enhancement cache
  void clearCache() {
    _enhancementCache.clear();
    if (Platform.isAndroid && _isInitialized) {
      _methodChannel.invokeMethod('clearCache');
    }
    _logger.d('🧹 Enhancement cache cleared');
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      await _eventSubscription?.cancel();

      if (Platform.isAndroid) {
        await _methodChannel.invokeMethod('dispose');
      }

      _enhancementCache.clear();
      await _enhancementEventController.close();
      await _nexaEventController.close();

      _isInitialized = false;
      _logger.i('🗑️ Nexa LLM service disposed');
    } catch (e, stackTrace) {
      _logger.e('Error disposing Nexa LLM service',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Start listening to native events
  void _startEventListening() {
    _eventSubscription = _eventChannel
        .receiveBroadcastStream()
        .listen(_handleNativeEvent, onError: _handleNativeError);
  }

  /// Handle native events from Nexa SDK
  void _handleNativeEvent(dynamic event) {
    if (event is Map) {
      final type = event['type'] as String?;
      final data = event['data'] as Map<dynamic, dynamic>?;

      _logger.d('Nexa LLM event: $type');

      switch (type) {
        case 'status':
        case 'enhancing':
        case 'inference':
        case 'generating':
          _emitEvent(NexaLlmEvent(
            progress: (data?['progress'] as num?)?.toDouble() ?? 0.0,
            message: data?['message'] as String? ?? '',
            isComplete: data?['isComplete'] as bool? ?? false,
          ));
          break;

        case 'enhancement':
        case 'inferenceResult':
        case 'generated':
          final enhancedText = data?['enhanced'] as String? ??
              data?['result'] as String? ??
              data?['response'] as String?;

          _emitEvent(NexaLlmEvent(
            progress: 1.0,
            message: 'Processing complete',
            isComplete: true,
            enhancedText: enhancedText,
          ));
          break;

        case 'error':
          _emitEvent(NexaLlmEvent(
            progress: 0.0,
            message: data?['message'] as String? ?? 'Unknown error',
            error: data?['message'],
          ));
          break;
      }
    }
  }

  /// Handle native errors
  void _handleNativeError(dynamic error) {
    _logger.e('Nexa LLM native error', error: error);
    _emitEvent(NexaLlmEvent(
      progress: 0.0,
      message: 'Native error occurred',
      error: error,
    ));
  }

  /// Emit event to all streams
  void _emitEvent(NexaLlmEvent event) {
    _nexaEventController.add(event);
    _enhancementEventController.add(event.toGemma3nEvent());
  }

  /// Add enhanced text to cache with LRU eviction
  void _addToCache(String original, String enhanced) {
    if (_enhancementCache.length >= _maxCacheSize) {
      _enhancementCache.remove(_enhancementCache.keys.first);
    }
    _enhancementCache[original] = enhanced;
  }

  /// Parse inference mode from string
  NexaInferenceMode _parseInferenceMode(String? mode) {
    switch (mode?.toUpperCase()) {
      case 'NPU':
        return NexaInferenceMode.npu;
      case 'GPU':
        return NexaInferenceMode.gpu;
      default:
        return NexaInferenceMode.cpu;
    }
  }
}
