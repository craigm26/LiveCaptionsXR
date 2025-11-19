import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart' as gemma;

import 'app_logger.dart';
import 'huggingface_token_service.dart';
import 'ios_model_config_service.dart';
import 'model_download_manager.dart';

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
class Gemma3nService {
  final AppLogger _logger = AppLogger.instance;
  final IOSModelConfigService _iosConfig = IOSModelConfigService();
  final HuggingFaceTokenService _tokenService = HuggingFaceTokenService.instance;

  final ModelDownloadManager _modelManager;
  gemma.InferenceModel? _model;
  bool _isInitialized = false;
  IOSModelConfig? _currentConfig;
  static bool _flutterGemmaInitialized = false;
  
  // HuggingFace repository URL mapping for Gemma models
  static const Map<String, String> _huggingFaceUrls = {
    'gemma-3n-E2B-it-int4': 'https://huggingface.co/google/gemma-3n-E2B-it/resolve/main/gemma-3n-E2B-it-int4.task',
    'gemma-3n-E4B-it-int4': 'https://huggingface.co/google/gemma-3n-E4B-it/resolve/main/gemma-3n-E4B-it-int4.task',
    'gemma-2b-it': 'https://huggingface.co/google/gemma-3n-E4B-it/resolve/main/gemma-3n-E4B-it-int4.task',
  };

  final Map<String, String> _enhancementCache = {};
  static const int _maxCacheSize = 100;

  final StreamController<Gemma3nEnhancementEvent> _enhancementEventController =
      StreamController<Gemma3nEnhancementEvent>.broadcast();

  Stream<Gemma3nEnhancementEvent> get enhancementEvents =>
      _enhancementEventController.stream;

  Gemma3nService({required ModelDownloadManager modelManager})
      : _modelManager = modelManager;

  Future<void> initialize({String modelKey = 'gemma-3n-E4B-it-int4'}) async {
    if (isReady) {
      _logger.i('? Gemma3nService already initialized',
          category: LogCategory.gemma);
      return;
    }

    try {
      _logger.i('?? Initializing Gemma3nService...',
          category: LogCategory.gemma);

      await _clearXNNPackCache();
      await _ensureFlutterGemmaInitialized();

      _enhancementEventController.add(const Gemma3nEnhancementEvent(
        progress: 0.0,
        message: 'Initializing Gemma 3n service...',
      ));

      _enhancementEventController.add(const Gemma3nEnhancementEvent(
        progress: 0.2,
        message: 'Checking Gemma 3n model...',
      ));

      if (!await _modelManager.modelIsComplete(modelKey)) {
        _logger.w(
            '?? Gemma 3n model not downloaded or incomplete - service will be disabled',
            category: LogCategory.gemma);
        _enhancementEventController.add(const Gemma3nEnhancementEvent(
          progress: 0.0,
          message: 'Gemma 3n model not available - enhancement disabled',
          error: 'Model not downloaded',
        ));
        return;
      }

      _enhancementEventController.add(const Gemma3nEnhancementEvent(
        progress: 0.5,
        message: 'Loading Gemma 3n model...',
      ));

      final modelPath = await _modelManager.getModelPath(modelKey);
      _logger.i('?? Loading Gemma model from: $modelPath',
          category: LogCategory.gemma);

      _currentConfig = _iosConfig.getOptimalConfig(modelKey);
      _iosConfig.logConfiguration(_currentConfig!, modelKey);

      // Check if we should install from HuggingFace network or local file
      final token = await _tokenService.getToken();
      final huggingFaceUrl = _huggingFaceUrls[modelKey];
      final useHuggingFace = token != null && 
                            token.isNotEmpty && 
                            huggingFaceUrl != null;

      if (useHuggingFace) {
        // huggingFaceUrl is guaranteed to be non-null here due to useHuggingFace check
        _logger.i('🔑 Installing model from HuggingFace: $huggingFaceUrl',
            category: LogCategory.gemma);
        final fileType = _resolveFileType(modelPath);
        await _installModelFromNetwork(
          url: huggingFaceUrl,
          fileType: fileType,
        );
      } else {
        final fileType = _resolveFileType(modelPath);
        await _installModelFromFile(
          modelPath: modelPath,
          fileType: fileType,
        );
      }

      final supportImage = _supportsVisionModel(modelKey);
      final preferredBackend = _resolvePreferredBackend(_currentConfig!);

      _model = await gemma.FlutterGemma.getActiveModel(
        maxTokens: _currentConfig!.maxTokens,
        preferredBackend: preferredBackend,
        supportImage: supportImage,
        maxNumImages: supportImage ? _currentConfig!.maxNumImages : null,
      );

      _isInitialized = true;
      _logger.i('? Gemma3nService initialized successfully',
          category: LogCategory.gemma);

      _enhancementEventController.add(const Gemma3nEnhancementEvent(
        progress: 1.0,
        message: 'Gemma 3n service ready',
        isComplete: true,
      ));
    } catch (e, stackTrace) {
      _logger.e('? Failed to initialize Gemma3nService',
          category: LogCategory.gemma, error: e, stackTrace: stackTrace);
      _enhancementEventController.add(Gemma3nEnhancementEvent(
        progress: 0.0,
        message: 'Failed to initialize Gemma 3n service - enhancement disabled',
        error: e,
      ));
      _isInitialized = false;
      _model = null;
    }
  }

  Future<String> enhanceText(String rawText) async {
    if (!isReady) {
      _logger.w('?? Gemma3nService not initialized, returning raw text');
      return rawText;
    }

    final cachedResult = _enhancementCache[rawText];
    if (cachedResult != null) {
      return cachedResult;
    }

    try {
      final prompt = _buildEnhancementPrompt(rawText);
      final response = await _generateResponse(prompt: prompt);
      final enhancedText = _cleanEnhancedText(response);

      if (enhancedText != rawText && enhancedText.isNotEmpty) {
        _addToCache(rawText, enhancedText);
      }

      return enhancedText;
    } catch (e) {
      _logger.e('? Failed to enhance text', error: e);
      return rawText;
    }
  }

  Future<String?> multimodalInference({
    required String text,
    Uint8List? image,
  }) async {
    if (!isReady) {
      _logger.w(
          '?? Gemma3nService not initialized, cannot perform multimodal inference.');
      return 'Error: Service not initialized.';
    }

    try {
      final response = await _generateResponse(
        prompt: text,
        imageBytes: image,
      );
      return _cleanEnhancedText(response);
    } catch (e) {
      _logger.e('? Failed to perform multimodal inference', error: e);
      return text;
    }
  }

  /// Attempts to transcribe a chunk of PCM16 mono audio using Gemma 3n.
  Future<String?> transcribeAudioChunk({
    required Uint8List pcmBytes,
    int sampleRate = 16000,
    bool isFinalChunk = false,
  }) async {
    if (!isReady) {
      _logger.w(
        '?? Gemma3nService not initialized, cannot transcribe audio chunk.',
        category: LogCategory.gemma,
      );
      return null;
    }
    if (pcmBytes.isEmpty) {
      _logger.d(
        '?? Empty PCM chunk provided to Gemma transcription - skipping.',
        category: LogCategory.gemma,
      );
      return null;
    }

    try {
      final payload = base64Encode(pcmBytes);
      final prompt = '''
You are a streaming speech recognizer.
The user is providing 16-bit PCM mono audio (sample rate ${sampleRate}Hz) encoded as Base64.
Transcribe the spoken English words present in this chunk.
${isFinalChunk ? 'This is the final chunk for the utterance.' : 'More audio may follow.'}

Audio chunk (base64):
$payload

Transcript:''';

      _logger.d(
        '🎙️ [Gemma-STT] Transcribing PCM chunk (${pcmBytes.length} bytes)...',
        category: LogCategory.gemma,
      );
      final response = await _generateResponse(prompt: prompt);
      final cleaned = _cleanEnhancedText(response);
      _logger.d(
        '🗣️ [Gemma-STT] Gemma returned transcript: "$cleaned"',
        category: LogCategory.gemma,
      );
      return cleaned;
    } catch (e, stackTrace) {
      _logger.e(
        '❌ Failed to transcribe PCM chunk with Gemma',
        category: LogCategory.gemma,
        error: e,
        stackTrace: stackTrace,
      );
      return null;
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

  Future<String> _generateResponse({
    required String prompt,
    Uint8List? imageBytes,
  }) async {
    final model = _model;
    if (model == null) {
      throw StateError('Gemma model is not initialized');
    }

    final session = await model.createSession(
      enableVisionModality: imageBytes != null,
    );

    try {
      final message = imageBytes != null
          ? gemma.Message.withImage(
              text: prompt,
              imageBytes: imageBytes,
              isUser: true,
            )
          : gemma.Message.text(
              text: prompt,
              isUser: true,
            );

      await session.addQueryChunk(message);
      return await session.getResponse();
    } finally {
      await session.close();
    }
  }

  Future<void> dispose() async {
    _logger.i('?? Disposing Gemma3nService...');
    _isInitialized = false;
    _enhancementCache.clear();
    if (_model != null) {
      await _model!.close();
      _model = null;
    }
    await _enhancementEventController.close();
    _logger.i('? Gemma3nService disposed');
  }

  bool get isReady => _isInitialized && _model != null;

  Future<String> analyzeImageForContext(Uint8List imageData) async {
    if (!isReady) {
      _logger.w('?? Gemma3nService not initialized, cannot analyze image.');
      return 'Service not initialized';
    }

    try {
      const prompt =
          '''Describe this scene briefly in 1-2 sentences, focusing on:
- Main objects or people visible
- Activities happening
- Setting/environment
- Any text or signs visible

Provide a concise, helpful description that could enhance live captions.''';

      final response = await _generateResponse(
        prompt: prompt,
        imageBytes: imageData,
      );
      return _cleanEnhancedText(response);
    } catch (e) {
      _logger.e('? Failed to analyze image', error: e);
      return 'Error analyzing image';
    }
  }

  Future<List<String>> detectObjectsInImage(Uint8List imageData) async {
    if (!isReady) {
      _logger.w('?? Gemma3nService not initialized, cannot detect objects.');
      return [];
    }

    try {
      const prompt =
          '''List the main objects visible in this image, one per line:
- Focus on objects that could be relevant for live captions
- Include people, furniture, electronics, vehicles, signs, etc.
- Use simple, clear object names
- Maximum 10 objects

Objects:''';

      final response = await _generateResponse(
        prompt: prompt,
        imageBytes: imageData,
      );

      final objects = response
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty && !line.startsWith('Objects:'))
          .map((line) => line.replaceAll(RegExp(r'^[-\*]\s*'), ''))
          .take(10)
          .toList();

      return objects;
    } catch (e) {
      _logger.e('? Failed to detect objects', error: e);
      return [];
    }
  }

  Future<String> enhanceTextWithVisualContext({
    required String text,
    required Uint8List imageData,
    String? spatialDirection,
  }) async {
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
          text: enhancedPrompt,
          image: imageData,
        ) ??
        text;
  }

  Future<void> _installModelFromFile({
    required String modelPath,
    required gemma.ModelFileType fileType,
  }) async {
    await gemma.FlutterGemma.installModel(
      modelType: gemma.ModelType.gemmaIt,
      fileType: fileType,
    ).fromFile(modelPath).install();
  }

  Future<void> _installModelFromNetwork({
    required String url,
    required gemma.ModelFileType fileType,
  }) async {
    await gemma.FlutterGemma.installModel(
      modelType: gemma.ModelType.gemmaIt,
      fileType: fileType,
    ).fromNetwork(url).install();
  }

  Future<void> _ensureFlutterGemmaInitialized() async {
    if (_flutterGemmaInitialized) {
      return;
    }
    
    // Get HuggingFace token if available
    final token = await _tokenService.getToken();
    
    if (token != null && token.isNotEmpty) {
      _logger.i('🔑 Initializing FlutterGemma with HuggingFace token',
          category: LogCategory.gemma);
      gemma.FlutterGemma.initialize(huggingFaceToken: token);
    } else {
      _logger.i('🔧 Initializing FlutterGemma without HuggingFace token',
          category: LogCategory.gemma);
      gemma.FlutterGemma.initialize();
    }
    
    _flutterGemmaInitialized = true;
  }

  gemma.ModelFileType _resolveFileType(String modelPath) {
    final lower = modelPath.toLowerCase();
    if (lower.endsWith('.bin') || lower.endsWith('.tflite')) {
      return gemma.ModelFileType.binary;
    }
    return gemma.ModelFileType.task;
  }

  gemma.PreferredBackend? _resolvePreferredBackend(IOSModelConfig config) {
    if (!Platform.isIOS) {
      return null;
    }
    return config.useMetalDelegate
        ? gemma.PreferredBackend.gpu
        : gemma.PreferredBackend.cpu;
  }

  bool _supportsVisionModel(String modelKey) {
    final normalized = modelKey.toLowerCase();
    return normalized.contains('3n') ||
        normalized.contains('vision') ||
        normalized.contains('multimodal');
  }

  Future<void> _clearXNNPackCache() async {
    try {
      _logger.i('?? Clearing XNNPack cache to fix version issues...');

      final Directory tempDir = Directory.systemTemp;
      final String cachePath = tempDir.path;

      final Directory cacheDir = Directory(cachePath);
      if (await cacheDir.exists()) {
        await for (final FileSystemEntity entity in cacheDir.list()) {
          if (entity.path.contains('xnnpack') ||
              entity.path.contains('tflite')) {
            try {
              await entity.delete(recursive: true);
              _logger.d(
                '??? Deleted cache file: ${entity.path}',
                category: LogCategory.gemma,
              );
            } catch (e) {
              _logger.w('?? Could not delete cache file ${entity.path}: $e');
            }
          }
        }
      }

      _logger.i('? XNNPack cache cleared');
    } catch (e) {
      _logger.w('?? Error clearing XNNPack cache (continuing anyway): $e');
    }
  }
}
