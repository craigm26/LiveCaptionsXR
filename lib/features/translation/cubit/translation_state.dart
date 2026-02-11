import 'package:equatable/equatable.dart';

import '../../../core/services/translation_service.dart';

/// State for translation feature
abstract class TranslationState extends Equatable {
  const TranslationState();

  @override
  List<Object?> get props => [];
}

/// Initial state before translation is configured
class TranslationInitial extends TranslationState {
  const TranslationInitial();
}

/// Translation is loading/initializing
class TranslationLoading extends TranslationState {
  final double progress;
  final String message;

  const TranslationLoading({
    this.progress = 0.0,
    this.message = 'Initializing translation...',
  });

  @override
  List<Object?> get props => [progress, message];
}

/// Translation is ready and configured
class TranslationReady extends TranslationState {
  final bool isEnabled;
  final TranslationLanguage sourceLanguage;
  final TranslationLanguage targetLanguage;
  final bool showOriginal;
  final bool isNpuAccelerated;

  const TranslationReady({
    required this.isEnabled,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.showOriginal,
    this.isNpuAccelerated = false,
  });

  TranslationReady copyWith({
    bool? isEnabled,
    TranslationLanguage? sourceLanguage,
    TranslationLanguage? targetLanguage,
    bool? showOriginal,
    bool? isNpuAccelerated,
  }) {
    return TranslationReady(
      isEnabled: isEnabled ?? this.isEnabled,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      showOriginal: showOriginal ?? this.showOriginal,
      isNpuAccelerated: isNpuAccelerated ?? this.isNpuAccelerated,
    );
  }

  @override
  List<Object?> get props =>
      [isEnabled, sourceLanguage, targetLanguage, showOriginal, isNpuAccelerated];
}

/// Translation error state
class TranslationError extends TranslationState {
  final String message;
  final Object? error;

  const TranslationError({
    required this.message,
    this.error,
  });

  @override
  List<Object?> get props => [message, error];
}
