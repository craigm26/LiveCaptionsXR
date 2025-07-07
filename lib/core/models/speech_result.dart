/// Model representing a speech recognition result
class SpeechResult {
  final String text;
  final double confidence;
  final bool isFinal;
  final DateTime timestamp;
  final String? speakerDirection;
  final Map<String, dynamic>? metadata;

  const SpeechResult({
    required this.text,
    required this.confidence,
    required this.isFinal,
    required this.timestamp,
    this.speakerDirection,
    this.metadata,
  });

  /// Create a copy with modified properties
  SpeechResult copyWith({
    String? text,
    double? confidence,
    bool? isFinal,
    DateTime? timestamp,
    String? speakerDirection,
    Map<String, dynamic>? metadata,
  }) {
    return SpeechResult(
      text: text ?? this.text,
      confidence: confidence ?? this.confidence,
      isFinal: isFinal ?? this.isFinal,
      timestamp: timestamp ?? this.timestamp,
      speakerDirection: speakerDirection ?? this.speakerDirection,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'confidence': confidence,
      'isFinal': isFinal,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'speakerDirection': speakerDirection,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory SpeechResult.fromJson(Map<String, dynamic> json) {
    return SpeechResult(
      text: json['text'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      isFinal: json['isFinal'] as bool,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      speakerDirection: json['speakerDirection'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() {
    return 'SpeechResult(text: "$text", confidence: $confidence, isFinal: $isFinal, timestamp: $timestamp)';
  }

  /// Check if this is a language detection result
  bool get isLanguageDetection => metadata?['type'] == 'languageDetection';

  /// Get detected language if this is a language detection result
  String? get detectedLanguage => metadata?['language'] as String?;

  /// Get audio level if available
  double? get audioLevel => metadata?['audioLevel'] as double?;

  /// Get language confidence score if available
  double? get languageConfidence => metadata?['confidence'] as double?;

  /// Check if this result contains actual speech content
  bool get hasActualSpeech => !isLanguageDetection && text.trim().isNotEmpty && !text.startsWith('[');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpeechResult &&
        other.text == text &&
        other.confidence == confidence &&
        other.isFinal == isFinal &&
        other.timestamp == timestamp &&
        other.speakerDirection == speakerDirection;
  }

  @override
  int get hashCode {
    return Object.hash(
      text,
      confidence,
      isFinal,
      timestamp,
      speakerDirection,
    );
  }
}
