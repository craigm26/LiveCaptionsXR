import 'package:equatable/equatable.dart';
import 'package:live_captions_xr/core/models/speech_result.dart';

/// Model representing a caption that has been enhanced by Gemma 3n
class EnhancedCaption extends Equatable {
  final String raw;
  final String? enhanced;
  final double confidence;
  final bool isFinal;
  final bool isEnhanced;
  final DateTime timestamp;

  EnhancedCaption({
    required this.raw,
    this.enhanced,
    this.confidence = 1.0,
    this.isFinal = true,
    this.isEnhanced = true,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create a partial (non-final) caption
  factory EnhancedCaption.partial(String raw) {
    return EnhancedCaption(
      raw: raw,
      enhanced: null,
      isFinal: false,
      isEnhanced: false,
      timestamp: DateTime.now(),
    );
  }

  /// Create a fallback caption when enhancement fails
  factory EnhancedCaption.fallback(String raw) {
    return EnhancedCaption(
      raw: raw,
      enhanced: raw, // Use raw as enhanced
      isFinal: true,
      isEnhanced: false,
      confidence: 0.5,
      timestamp: DateTime.now(),
    );
  }

  /// Create an EnhancedCaption from a standard SpeechResult
  factory EnhancedCaption.fromSpeechResult(SpeechResult result) {
    return EnhancedCaption(
      raw: result.text,
      enhanced: result.text,
      confidence: result.confidence,
      isFinal: result.isFinal,
      isEnhanced: false,
      timestamp: result.timestamp,
    );
  }

  /// Get the best available text (enhanced if available, otherwise raw)
  String get displayText => enhanced ?? raw;

  /// Check if this caption has been successfully enhanced
  bool get hasEnhancement => enhanced != null && enhanced != raw && isEnhanced;

  @override
  List<Object?> get props => [raw, enhanced, confidence, isFinal, isEnhanced, timestamp];

  EnhancedCaption copyWith({
    String? raw,
    String? enhanced,
    double? confidence,
    bool? isFinal,
    bool? isEnhanced,
    DateTime? timestamp,
  }) {
    return EnhancedCaption(
      raw: raw ?? this.raw,
      enhanced: enhanced ?? this.enhanced,
      confidence: confidence ?? this.confidence,
      isFinal: isFinal ?? this.isFinal,
      isEnhanced: isEnhanced ?? this.isEnhanced,
      timestamp: timestamp ?? this.timestamp,
    );
  }
} 