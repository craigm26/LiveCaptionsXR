import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/translation_service.dart';
import '../../../core/services/app_logger.dart';
import 'translation_state.dart';

/// Cubit for managing translation feature state
class TranslationCubit extends Cubit<TranslationState> {
  final TranslationService _translationService;
  final AppLogger _logger = AppLogger.instance;

  StreamSubscription? _eventSubscription;

  // Preference keys
  static const String _prefEnabled = 'translation_enabled';
  static const String _prefSourceLang = 'translation_source_lang';
  static const String _prefTargetLang = 'translation_target_lang';
  static const String _prefShowOriginal = 'translation_show_original';

  TranslationCubit({
    required TranslationService translationService,
  })  : _translationService = translationService,
        super(const TranslationInitial());

  TranslationService get service => _translationService;

  /// Initialize translation feature
  Future<void> initialize() async {
    try {
      emit(const TranslationLoading(message: 'Loading translation settings...'));

      // Load saved preferences
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_prefEnabled) ?? false;
      final sourceCode = prefs.getString(_prefSourceLang) ?? 'en';
      final targetCode = prefs.getString(_prefTargetLang) ?? 'en';
      final showOriginal = prefs.getBool(_prefShowOriginal) ?? true;

      // Apply saved settings
      _translationService.setSourceLanguage(
          TranslationLanguage.fromCode(sourceCode));
      _translationService.setTargetLanguage(
          TranslationLanguage.fromCode(targetCode));
      _translationService.setShowOriginal(showOriginal);

      emit(const TranslationLoading(
        progress: 0.5,
        message: 'Initializing translation engine...',
      ));

      // Initialize the translation service
      await _translationService.initialize();

      // Apply enabled state after initialization
      _translationService.setEnabled(enabled);

      // Subscribe to translation events
      _eventSubscription = _translationService.events.listen(_handleEvent);

      emit(TranslationReady(
        isEnabled: enabled,
        sourceLanguage: _translationService.sourceLanguage,
        targetLanguage: _translationService.targetLanguage,
        showOriginal: showOriginal,
        isNpuAccelerated: _translationService.isNpuAccelerated,
      ));

      _logger.i('✅ Translation cubit initialized', category: LogCategory.speech);
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to initialize translation',
          category: LogCategory.speech, error: e, stackTrace: stackTrace);
      emit(TranslationError(message: 'Failed to initialize translation', error: e));
    }
  }

  void _handleEvent(TranslationEvent event) {
    if (event.error != null) {
      _logger.w('⚠️ Translation event error: ${event.error}',
          category: LogCategory.speech);
    }
  }

  /// Toggle translation on/off
  Future<void> toggleEnabled() async {
    if (state is! TranslationReady) return;

    final currentState = state as TranslationReady;
    final newEnabled = !currentState.isEnabled;

    _translationService.setEnabled(newEnabled);

    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefEnabled, newEnabled);

    emit(currentState.copyWith(isEnabled: newEnabled));

    _logger.i('🌐 Translation ${newEnabled ? "enabled" : "disabled"}',
        category: LogCategory.speech);
  }

  /// Set source language
  Future<void> setSourceLanguage(TranslationLanguage language) async {
    if (state is! TranslationReady) return;

    final currentState = state as TranslationReady;
    _translationService.setSourceLanguage(language);

    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefSourceLang, language.code);

    emit(currentState.copyWith(sourceLanguage: language));
  }

  /// Set target language
  Future<void> setTargetLanguage(TranslationLanguage language) async {
    if (state is! TranslationReady) return;

    final currentState = state as TranslationReady;
    _translationService.setTargetLanguage(language);

    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefTargetLang, language.code);

    emit(currentState.copyWith(targetLanguage: language));
  }

  /// Toggle show original text
  Future<void> toggleShowOriginal() async {
    if (state is! TranslationReady) return;

    final currentState = state as TranslationReady;
    final newShowOriginal = !currentState.showOriginal;

    _translationService.setShowOriginal(newShowOriginal);

    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefShowOriginal, newShowOriginal);

    emit(currentState.copyWith(showOriginal: newShowOriginal));
  }

  /// Translate text using the current settings
  Future<TranslationResult> translate(String text) async {
    return _translationService.translate(text);
  }

  /// Get available languages
  List<TranslationLanguage> getAvailableLanguages() {
    return _translationService.getAvailableLanguages();
  }

  @override
  Future<void> close() {
    _eventSubscription?.cancel();
    _translationService.dispose();
    return super.close();
  }
}
