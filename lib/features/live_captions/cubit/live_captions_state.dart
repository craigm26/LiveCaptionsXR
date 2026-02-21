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
  final String? message;
  final double? progress;
  
  const LiveCaptionsLoading({this.message, this.progress});
  
  @override
  List<Object?> get props => [message, progress];
}

/// Active state - captions are being processed and displayed
class LiveCaptionsActive extends LiveCaptionsState {
  final List<SpeechResult> captions;
  final SpeechResult? currentCaption;
  final bool isListening;
  final String? error;
  final bool showOverlayFallback;
  final bool hasEnhancement;
  final String? rawSttDebugText;

  /// Whether Enhanced Captions mode is active (OmniNeural downloaded + setting on).
  /// When true, sticky speaker labels are shown at the speaker's angular position.
  final bool enhancedCaptionsActive;

  /// Per-speaker angle (radians) for sticky label positioning.
  /// Key: speakerId, Value: angle (negative = left, 0 = center, positive = right).
  final Map<String, double> speakerAngles;

  const LiveCaptionsActive({
    required this.captions,
    this.currentCaption,
    required this.isListening,
    this.error,
    this.showOverlayFallback = false,
    this.hasEnhancement = false,
    this.rawSttDebugText,
    this.enhancedCaptionsActive = false,
    this.speakerAngles = const {},
  });

  @override
  List<Object?> get props => [
    captions, currentCaption, isListening, error,
    showOverlayFallback, hasEnhancement, rawSttDebugText,
    enhancedCaptionsActive, speakerAngles,
  ];

  LiveCaptionsActive copyWith({
    List<SpeechResult>? captions,
    SpeechResult? currentCaption,
    bool? isListening,
    String? error,
    bool? showOverlayFallback,
    bool? hasEnhancement,
    String? rawSttDebugText,
    bool? enhancedCaptionsActive,
    Map<String, double>? speakerAngles,
  }) {
    return LiveCaptionsActive(
      captions: captions ?? this.captions,
      currentCaption: currentCaption ?? this.currentCaption,
      isListening: isListening ?? this.isListening,
      error: error ?? this.error,
      showOverlayFallback: showOverlayFallback ?? this.showOverlayFallback,
      hasEnhancement: hasEnhancement ?? this.hasEnhancement,
      rawSttDebugText: rawSttDebugText ?? this.rawSttDebugText,
      enhancedCaptionsActive: enhancedCaptionsActive ?? this.enhancedCaptionsActive,
      speakerAngles: speakerAngles ?? this.speakerAngles,
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
