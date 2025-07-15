import 'package:equatable/equatable.dart';
import '../../../core/models/speech_result.dart';

/// State for live captions functionality
abstract class LiveCaptionsState extends Equatable {
  const LiveCaptionsState();

  @override
  List<Object?> get props => [];
}

/// Initial state - captions not started
class LiveCaptionsInitial extends LiveCaptionsState {
  const LiveCaptionsInitial();
}

/// Loading state - initializing speech processing
class LiveCaptionsLoading extends LiveCaptionsState {
  const LiveCaptionsLoading();
}

/// Active state - captions are being processed and displayed
class LiveCaptionsActive extends LiveCaptionsState {
  final List<SpeechResult> captions;
  final SpeechResult? currentCaption;
  final bool isListening;
  final String? error;
  final bool showOverlayFallback;
  final bool hasEnhancement;

  const LiveCaptionsActive({
    required this.captions,
    this.currentCaption,
    required this.isListening,
    this.error,
    this.showOverlayFallback = false,
    this.hasEnhancement = false,
  });

  @override
  List<Object?> get props => [captions, currentCaption, isListening, error, showOverlayFallback, hasEnhancement];

  LiveCaptionsActive copyWith({
    List<SpeechResult>? captions,
    SpeechResult? currentCaption,
    bool? isListening,
    String? error,
    bool? showOverlayFallback,
    bool? hasEnhancement,
  }) {
    return LiveCaptionsActive(
      captions: captions ?? this.captions,
      currentCaption: currentCaption ?? this.currentCaption,
      isListening: isListening ?? this.isListening,
      error: error ?? this.error,
      showOverlayFallback: showOverlayFallback ?? this.showOverlayFallback,
      hasEnhancement: hasEnhancement ?? this.hasEnhancement,
    );
  }
}

/// Error state - something went wrong with caption processing
class LiveCaptionsError extends LiveCaptionsState {
  final String message;
  final String? details;

  const LiveCaptionsError({
    required this.message,
    this.details,
  });

  @override
  List<Object?> get props => [message, details];
}
