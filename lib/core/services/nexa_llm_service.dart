import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:nexa_ai_flutter/nexa_ai_flutter.dart';
import 'package:path_provider/path_provider.dart';

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
/// Uses the nexa_ai_flutter package for direct Flutter integration.
///
/// Recommended models:
/// - Granite-4.0-h-350M-NPU: Fast text enhancement
/// - OmniNeural-4B: Multimodal with vision+text
///
/// For the Qualcomm x Nexa On-Device AI Bounty Program.
class NexaLlmService {
  static final AppLogger _logger = AppLogger.instance;

  bool _isInitialized = false;
  bool _sdkInitialized = false;
  String _currentModelName = 'granite-4.0-h-350m-npu';
  NexaInferenceMode _inferenceMode = NexaInferenceMode.cpu;
  bool _supportsVision = false;

  // Nexa SDK wrappers
  LlmWrapper? _llmWrapper;
  VlmWrapper? _vlmWrapper;
  String? _modelPath;

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
      final models = await ModelDownloader.getAvailableModels();
      return models.any((m) => m.pluginId == 'npu');
    } catch (e) {
      _logger.e('Failed to check NPU availability', error: e);
      return false;
    }
  }

  /// Initialize the Nexa SDK
  Future<bool> _initializeSdk() async {
    if (_sdkInitialized) return true;

    try {
      _logger.i('🚀 Initializing Nexa SDK for LLM...', category: LogCategory.gemma);
      await NexaSdk.getInstance().init();
      _sdkInitialized = true;
      _logger.i('✅ Nexa SDK initialized', category: LogCategory.gemma);
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to initialize Nexa SDK',
          error: e, stackTrace: stackTrace, category: LogCategory.gemma);
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

      // Initialize Nexa SDK first
      final sdkReady = await _initializeSdk();
      if (!sdkReady) {
        _emitEvent(const NexaLlmEvent(
          progress: 0.0,
          message: 'Failed to initialize Nexa SDK',
          error: 'SDK initialization failed',
        ));
        return;
      }

      _emitEvent(const NexaLlmEvent(
        progress: 0.2,
        message: 'Checking NPU availability...',
      ));

      // Check NPU availability
      final npuAvailable = await isNpuAvailable();
      _inferenceMode = preferNpu && npuAvailable
          ? NexaInferenceMode.npu
          : NexaInferenceMode.cpu;

      _currentModelName = modelName;
      _supportsVision = modelName.contains('omni') ||
          modelName.contains('vlm') ||
          modelName.contains('vision');

      _logger.i(
          '🚀 Initializing Nexa LLM with model: $modelName (mode: ${_inferenceMode.name.toUpperCase()}, vision: $_supportsVision)',
          category: LogCategory.gemma);

      _emitEvent(NexaLlmEvent(
        progress: 0.4,
        message: 'Loading $modelName model...',
      ));

      // Get model path
      _modelPath = modelPath ?? await _getDefaultModelPath(modelName);

      // Create appropriate wrapper based on model type
      final pluginId = _inferenceMode == NexaInferenceMode.npu ? 'npu' : 'cpu_gpu';

      try {
        if (_supportsVision) {
          // Use VLM wrapper for vision models
          _vlmWrapper = await VlmWrapper.create(
            VlmCreateInput(
              modelName: modelName,
              modelPath: _modelPath!,
              config: ModelConfig(
                maxTokens: 2048,
                enableThinking: false,
              ),
              pluginId: pluginId,
            ),
          );
          _logger.i('✅ VLM wrapper created for vision support', category: LogCategory.gemma);
        } else {
          // Use LLM wrapper for text-only models
          _llmWrapper = await LlmWrapper.create(
            LlmCreateInput(
              modelPath: _modelPath!,
              config: ModelConfig(
                nCtx: 4096,
                maxTokens: 2048,
              ),
              pluginId: pluginId,
            ),
          );
          _logger.i('✅ LLM wrapper created', category: LogCategory.gemma);
        }

        _isInitialized = true;

        _emitEvent(NexaLlmEvent(
          progress: 1.0,
          message: 'Nexa LLM ready (${_inferenceMode.name.toUpperCase()}, vision: $_supportsVision)',
          isComplete: true,
        ));

        _logger.i(
            '✅ Nexa LLM initialized: model=$_currentModelName, mode=${_inferenceMode.name.toUpperCase()}, vision=$_supportsVision',
            category: LogCategory.gemma);
      } catch (e) {
        _logger.w('⚠️ Failed to create wrapper with $pluginId, trying fallback',
            error: e, category: LogCategory.gemma);

        // Try CPU fallback if NPU fails
        if (_inferenceMode == NexaInferenceMode.npu) {
          _inferenceMode = NexaInferenceMode.cpu;
          try {
            if (_supportsVision) {
              _vlmWrapper = await VlmWrapper.create(
                VlmCreateInput(
                  modelPath: _modelPath!,
                  config: ModelConfig(maxTokens: 2048),
                  pluginId: 'cpu_gpu',
                ),
              );
            } else {
              _llmWrapper = await LlmWrapper.create(
                LlmCreateInput(
                  modelPath: _modelPath!,
                  config: ModelConfig(nCtx: 4096, maxTokens: 2048),
                  pluginId: 'cpu_gpu',
                ),
              );
            }
            _isInitialized = true;
            _emitEvent(NexaLlmEvent(
              progress: 1.0,
              message: 'Nexa LLM ready (CPU fallback)',
              isComplete: true,
            ));
          } catch (fallbackError) {
            _logger.e('❌ LLM fallback also failed',
                error: fallbackError, category: LogCategory.gemma);
            rethrow;
          }
        } else {
          rethrow;
        }
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to initialize Nexa LLM',
          error: e, stackTrace: stackTrace, category: LogCategory.gemma);

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
      _logger.d('🔮 Enhancing text with Nexa LLM: "$rawText"', category: LogCategory.gemma);

      _emitEvent(const NexaLlmEvent(
        progress: 0.0,
        message: 'Starting text enhancement...',
      ));

      final prompt = _buildEnhancementPrompt(rawText);

      _emitEvent(const NexaLlmEvent(
        progress: 0.3,
        message: 'Running Nexa LLM inference...',
      ));

      String enhancedText = rawText;

      if (_llmWrapper != null) {
        // Use LLM streaming for text enhancement
        final buffer = StringBuffer();
        await for (final result in _llmWrapper!.generateStream(
          prompt,
          GenerationConfig(maxTokens: 128, temperature: 0.3),
        )) {
          if (result is LlmStreamToken) {
            buffer.write(result.text);
          } else if (result is LlmStreamCompleted) {
            break;
          } else if (result is LlmStreamError) {
            throw result.throwable;
          }
        }
        enhancedText = _cleanEnhancedText(buffer.toString());
      } else if (_vlmWrapper != null) {
        // Use VLM for text (without image)
        final chatMessage = VlmChatMessage('user', [
          VlmContent('text', prompt),
        ]);
        final template = await _vlmWrapper!.applyChatTemplate(
          [chatMessage],
          null,
          false,
        );

        final buffer = StringBuffer();
        await for (final result in _vlmWrapper!.generateStreamFlow(
          template.formattedText,
          GenerationConfig(maxTokens: 128, temperature: 0.3),
        )) {
          if (result is LlmStreamToken) {
            buffer.write(result.text);
          } else if (result is LlmStreamCompleted) {
            break;
          }
        }
        enhancedText = _cleanEnhancedText(buffer.toString());
      }

      if (enhancedText != rawText && enhancedText.isNotEmpty) {
        _addToCache(rawText, enhancedText);
      }

      _logger.d('✨ Enhanced text: "$enhancedText"', category: LogCategory.gemma);

      _emitEvent(NexaLlmEvent(
        progress: 1.0,
        message: 'Text enhancement complete',
        isComplete: true,
        enhancedText: enhancedText,
      ));

      return enhancedText;
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to enhance text',
          error: e, stackTrace: stackTrace, category: LogCategory.gemma);

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
      return await enhanceText(text);
    }

    if (_vlmWrapper == null) {
      _logger.w('VLM wrapper not available, using text-only enhancement');
      return await enhanceText(text);
    }

    try {
      _logger.d('🧠 Performing multimodal inference for text: "$text"', category: LogCategory.gemma);

      _emitEvent(const NexaLlmEvent(
        progress: 0.0,
        message: 'Starting multimodal enhancement...',
      ));

      // Save image to temp file if provided
      String? imagePath;
      File? tempImageFile;
      if (imageData != null) {
        final tempDir = await getTemporaryDirectory();
        tempImageFile = File('${tempDir.path}/nexa_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tempImageFile.writeAsBytes(imageData);
        imagePath = tempImageFile.path;
      }

      try {
        final contents = <VlmContent>[
          if (imagePath != null) VlmContent('image', imagePath),
          VlmContent('text', text),
        ];

        final chatMessage = VlmChatMessage('user', contents);
        final template = await _vlmWrapper!.applyChatTemplate(
          [chatMessage],
          null,
          false,
        );

        _emitEvent(const NexaLlmEvent(
          progress: 0.5,
          message: 'Running Nexa VLM inference...',
        ));

        final config = await _vlmWrapper!.injectMediaPathsToConfig(
          [chatMessage],
          GenerationConfig(maxTokens: 256, temperature: 0.5),
        );

        final buffer = StringBuffer();
        await for (final result in _vlmWrapper!.generateStreamFlow(
          template.formattedText,
          config,
        )) {
          if (result is LlmStreamToken) {
            buffer.write(result.text);
          } else if (result is LlmStreamCompleted) {
            break;
          }
        }

        final response = _cleanEnhancedText(buffer.toString());

        _logger.d('🔍 Multimodal inference response: $response', category: LogCategory.gemma);

        _emitEvent(NexaLlmEvent(
          progress: 1.0,
          message: 'Multimodal enhancement complete',
          isComplete: true,
          enhancedText: response,
        ));

        return response;
      } finally {
        // Clean up temp image file
        try {
          await tempImageFile?.delete();
        } catch (_) {}
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to perform multimodal inference',
          error: e, stackTrace: stackTrace, category: LogCategory.gemma);

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
    final prompt = '''Enhance this caption with visual context from the image:

Original: "$text"

Provide an enhanced caption that:
- Keeps the original meaning intact
- Adds relevant visual details from the image
- Mentions spatial context if applicable
- Remains natural and concise

Enhanced:''';

    return await multimodalInference(text: prompt, imageData: imageData) ?? text;
  }

  /// Analyze an image to provide scene description for visual context
  Future<String> analyzeImageForContext(Uint8List imageData) async {
    if (!_isInitialized || !_supportsVision) {
      _logger.w('Nexa LLM not ready for image analysis');
      return 'Service not ready for image analysis';
    }

    try {
      _logger.d('📸 Analyzing image for context (${imageData.length} bytes)', category: LogCategory.gemma);

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

  /// Clear the enhancement cache
  void clearCache() {
    _enhancementCache.clear();
    _logger.d('🧹 Enhancement cache cleared');
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      if (_llmWrapper != null) {
        await _llmWrapper!.destroy();
        _llmWrapper = null;
      }

      if (_vlmWrapper != null) {
        await _vlmWrapper!.destroy();
        _vlmWrapper = null;
      }

      _enhancementCache.clear();
      await _enhancementEventController.close();
      await _nexaEventController.close();

      _isInitialized = false;
      _logger.i('🗑️ Nexa LLM service disposed', category: LogCategory.gemma);
    } catch (e, stackTrace) {
      _logger.e('Error disposing Nexa LLM service',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Build enhancement prompt
  String _buildEnhancementPrompt(String rawText) {
    return '''Improve the following transcription by adding punctuation, correcting errors, and ensuring proper capitalization.
Raw: "$rawText"
Enhanced:''';
  }

  /// Clean enhanced text output
  String _cleanEnhancedText(String text) {
    var cleaned = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if ((cleaned.startsWith('"') && cleaned.endsWith('"')) ||
        (cleaned.startsWith("'") && cleaned.endsWith("'"))) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }
    return cleaned;
  }

  /// Get the default model path for the specified model
  Future<String> _getDefaultModelPath(String modelName) async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/models/$modelName';
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
}
