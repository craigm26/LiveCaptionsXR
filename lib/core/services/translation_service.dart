import 'dart:async';

import 'package:nexa_ai_flutter/nexa_ai_flutter.dart';

import 'app_logger.dart';
import 'nexa_llm_service.dart';

/// Supported translation languages
enum TranslationLanguage {
  english('en', 'English'),
  spanish('es', 'Español'),
  french('fr', 'Français'),
  german('de', 'Deutsch'),
  italian('it', 'Italiano'),
  portuguese('pt', 'Português'),
  chinese('zh', '中文'),
  japanese('ja', '日本語'),
  korean('ko', '한국어'),
  arabic('ar', 'العربية'),
  hindi('hi', 'हिन्दी'),
  russian('ru', 'Русский'),
  vietnamese('vi', 'Tiếng Việt'),
  tagalog('tl', 'Tagalog'),
  ukrainian('uk', 'Українська');

  final String code;
  final String displayName;

  const TranslationLanguage(this.code, this.displayName);

  static TranslationLanguage fromCode(String code) {
    return TranslationLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => TranslationLanguage.english,
    );
  }
}

/// Translation result containing original and translated text
/// with optional speaker spatial mapping for 3D/4D positioning
class TranslationResult {
  final String originalText;
  final String translatedText;
  final TranslationLanguage sourceLanguage;
  final TranslationLanguage targetLanguage;
  final Duration processingTime;
  final bool isOnDevice;
  
  // Speaker spatial mapping (3D/4D intelligence)
  final String? speakerId;
  final String? speakerDisplayName;
  final int? speakerColor;
  final List<double>? speakerPosition; // [x, y, z]
  final double? speakerConfidence;

  const TranslationResult({
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.processingTime,
    this.isOnDevice = true,
    this.speakerId,
    this.speakerDisplayName,
    this.speakerColor,
    this.speakerPosition,
    this.speakerConfidence,
  });

  /// Check if translation actually occurred (different languages)
  bool get wasTranslated => sourceLanguage != targetLanguage;
  
  /// Check if this result has speaker spatial data
  bool get hasSpeakerData => speakerId != null;
  
  /// Get speaker label for display
  String get speakerLabel => speakerDisplayName ?? speakerId ?? 'Unknown';
  
  /// Create a copy with speaker data added
  TranslationResult withSpeakerData({
    String? speakerId,
    String? speakerDisplayName,
    int? speakerColor,
    List<double>? speakerPosition,
    double? speakerConfidence,
  }) {
    return TranslationResult(
      originalText: originalText,
      translatedText: translatedText,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      processingTime: processingTime,
      isOnDevice: isOnDevice,
      speakerId: speakerId ?? this.speakerId,
      speakerDisplayName: speakerDisplayName ?? this.speakerDisplayName,
      speakerColor: speakerColor ?? this.speakerColor,
      speakerPosition: speakerPosition ?? this.speakerPosition,
      speakerConfidence: speakerConfidence ?? this.speakerConfidence,
    );
  }

  @override
  String toString() =>
      'TranslationResult(${sourceLanguage.code} → ${targetLanguage.code}, speaker: ${speakerLabel}): "$translatedText"';
}

/// Event for translation progress
class TranslationEvent {
  final double progress;
  final String message;
  final bool isComplete;
  final Object? error;
  final TranslationResult? result;

  const TranslationEvent({
    required this.progress,
    required this.message,
    this.isComplete = false,
    this.error,
    this.result,
  });
}

/// On-device translation service using Nexa LLM
///
/// Provides real-time translation of captions for accessibility:
/// - 100% on-device processing via Nexa SDK
/// - NPU acceleration on Qualcomm devices
/// - No network required after model download
/// - Privacy-first: text never leaves device
///
/// For the Qualcomm x Nexa On-Device AI Bounty Program.
class TranslationService {
  static final AppLogger _logger = AppLogger.instance;

  final NexaLlmService _nexaLlmService;

  bool _isInitialized = false;
  TranslationLanguage _sourceLanguage = TranslationLanguage.english;
  TranslationLanguage _targetLanguage = TranslationLanguage.spanish;
  bool _enabled = false;
  bool _showOriginal = true; // Show original text alongside translation

  // Translation cache for repeated phrases
  final Map<String, TranslationResult> _translationCache = {};
  static const int _maxCacheSize = 200;

  // Event stream
  final StreamController<TranslationEvent> _eventController =
      StreamController<TranslationEvent>.broadcast();

  TranslationService({
    required NexaLlmService nexaLlmService,
  }) : _nexaLlmService = nexaLlmService;

  /// Stream of translation events
  Stream<TranslationEvent> get events => _eventController.stream;

  bool get isInitialized => _isInitialized;
  bool get isEnabled => _enabled;
  bool get showOriginal => _showOriginal;
  TranslationLanguage get sourceLanguage => _sourceLanguage;
  TranslationLanguage get targetLanguage => _targetLanguage;
  bool get isNpuAccelerated => _nexaLlmService.isNpuAccelerated;

  /// Initialize the translation service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.i('🌐 Initializing translation service...',
          category: LogCategory.speech);

      _eventController.add(const TranslationEvent(
        progress: 0.1,
        message: 'Initializing Nexa LLM for translation...',
      ));

      // Ensure Nexa LLM is initialized
      if (!_nexaLlmService.isInitialized) {
        await _nexaLlmService.initialize();
      }

      _isInitialized = true;

      _eventController.add(const TranslationEvent(
        progress: 1.0,
        message: 'Translation service ready',
        isComplete: true,
      ));

      _logger.i('✅ Translation service initialized',
          category: LogCategory.speech);
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to initialize translation service',
          category: LogCategory.speech, error: e, stackTrace: stackTrace);

      _eventController.add(TranslationEvent(
        progress: 0.0,
        message: 'Translation initialization failed',
        isComplete: true,
        error: e,
      ));

      rethrow;
    }
  }

  /// Enable or disable translation
  void setEnabled(bool enabled) {
    _enabled = enabled;
    _logger.i(
        '🌐 Translation ${enabled ? "enabled" : "disabled"}: ${_sourceLanguage.code} → ${_targetLanguage.code}',
        category: LogCategory.speech);
  }

  /// Set whether to show original text alongside translation
  void setShowOriginal(bool show) {
    _showOriginal = show;
  }

  /// Set the source language (language being spoken)
  void setSourceLanguage(TranslationLanguage language) {
    _sourceLanguage = language;
    _translationCache.clear(); // Clear cache when language changes
    _logger.i('🌐 Source language set to: ${language.displayName}',
        category: LogCategory.speech);
  }

  /// Set the target language (language to translate to)
  void setTargetLanguage(TranslationLanguage language) {
    _targetLanguage = language;
    _translationCache.clear(); // Clear cache when language changes
    _logger.i('🌐 Target language set to: ${language.displayName}',
        category: LogCategory.speech);
  }

  /// Translate text from source to target language
  ///
  /// Returns the translation result, or the original text if:
  /// - Translation is disabled
  /// - Source and target languages are the same
  /// - Translation fails
  Future<TranslationResult> translate(String text) async {
    final stopwatch = Stopwatch()..start();

    // Return original if disabled or same language
    if (!_enabled || _sourceLanguage == _targetLanguage) {
      return TranslationResult(
        originalText: text,
        translatedText: text,
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
        processingTime: Duration.zero,
        isOnDevice: true,
      );
    }

    // Check cache first
    final cacheKey = '${_sourceLanguage.code}:${_targetLanguage.code}:$text';
    if (_translationCache.containsKey(cacheKey)) {
      _logger.d('📦 Translation cache hit: "$text"',
          category: LogCategory.speech);
      return _translationCache[cacheKey]!;
    }

    try {
      _logger.i(
          '🌐 Translating: "$text" (${_sourceLanguage.code} → ${_targetLanguage.code})',
          category: LogCategory.speech);

      // Build translation prompt for Nexa LLM
      final prompt = _buildTranslationPrompt(text);

      // Use Nexa LLM for translation
      final translatedText = await _nexaLlmService.enhanceText(prompt);

      stopwatch.stop();

      // Clean up the response (remove any prompt artifacts)
      final cleanedTranslation = _cleanTranslationResponse(translatedText);

      final result = TranslationResult(
        originalText: text,
        translatedText: cleanedTranslation,
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
        processingTime: stopwatch.elapsed,
        isOnDevice: true,
      );

      // Cache the result
      _addToCache(cacheKey, result);

      _logger.i(
          '✅ Translation complete in ${stopwatch.elapsedMilliseconds}ms: "$cleanedTranslation"',
          category: LogCategory.speech);

      _eventController.add(TranslationEvent(
        progress: 1.0,
        message: 'Translation complete',
        isComplete: true,
        result: result,
      ));

      return result;
    } catch (e, stackTrace) {
      _logger.e('❌ Translation failed: $e',
          category: LogCategory.speech, error: e, stackTrace: stackTrace);

      stopwatch.stop();

      // Return original text on failure
      return TranslationResult(
        originalText: text,
        translatedText: text, // Fallback to original
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
        processingTime: stopwatch.elapsed,
        isOnDevice: true,
      );
    }
  }

  /// Build the translation prompt for Nexa LLM
  String _buildTranslationPrompt(String text) {
    return '''Translate the following ${_sourceLanguage.displayName} text to ${_targetLanguage.displayName}. 
Only output the translation, nothing else.

Text: $text

Translation:''';
  }

  /// Clean up the LLM response to extract just the translation
  String _cleanTranslationResponse(String response) {
    // Remove common prefixes
    var cleaned = response.trim();

    // Remove "Translation:" prefix if present
    if (cleaned.toLowerCase().startsWith('translation:')) {
      cleaned = cleaned.substring(12).trim();
    }

    // Remove quotes if the entire response is quoted
    if ((cleaned.startsWith('"') && cleaned.endsWith('"')) ||
        (cleaned.startsWith("'") && cleaned.endsWith("'"))) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }

    return cleaned;
  }

  /// Add translation to cache with LRU eviction
  void _addToCache(String key, TranslationResult result) {
    if (_translationCache.length >= _maxCacheSize) {
      // Remove oldest entry
      _translationCache.remove(_translationCache.keys.first);
    }
    _translationCache[key] = result;
  }

  /// Clear the translation cache
  void clearCache() {
    _translationCache.clear();
    _logger.i('🗑️ Translation cache cleared', category: LogCategory.speech);
  }

  /// Get list of available target languages
  List<TranslationLanguage> getAvailableLanguages() {
    return TranslationLanguage.values.toList();
  }

  /// Dispose of resources
  void dispose() {
    _eventController.close();
    _translationCache.clear();
  }
}
