import 'package:vector_math/vector_math_64.dart';

/// Model representing a speech recognition result
class SpeechResult {
  final String text;
  final double confidence;
  final bool isFinal;
  final DateTime timestamp;
  final String? speakerDirection;
  final Map<String, dynamic>? metadata;
  
  // Speaker diarization fields
  final String? speakerId;
  final String? speakerDisplayName;
  final int? speakerColor;
  final Vector3? speakerPosition;
  final double? speakerConfidence;

  const SpeechResult({
    required this.text,
    required this.confidence,
    required this.isFinal,
    required this.timestamp,
    this.speakerDirection,
    this.metadata,
    this.speakerId,
    this.speakerDisplayName,
    this.speakerColor,
    this.speakerPosition,
    this.speakerConfidence,
  });

  /// Create a copy with modified properties
  SpeechResult copyWith({
    String? text,
    double? confidence,
    bool? isFinal,
    DateTime? timestamp,
    String? speakerDirection,
    Map<String, dynamic>? metadata,
    String? speakerId,
    String? speakerDisplayName,
    int? speakerColor,
    Vector3? speakerPosition,
    double? speakerConfidence,
  }) {
    return SpeechResult(
      text: text ?? this.text,
      confidence: confidence ?? this.confidence,
      isFinal: isFinal ?? this.isFinal,
      timestamp: timestamp ?? this.timestamp,
      speakerDirection: speakerDirection ?? this.speakerDirection,
      metadata: metadata ?? this.metadata,
      speakerId: speakerId ?? this.speakerId,
      speakerDisplayName: speakerDisplayName ?? this.speakerDisplayName,
      speakerColor: speakerColor ?? this.speakerColor,
      speakerPosition: speakerPosition ?? this.speakerPosition,
      speakerConfidence: speakerConfidence ?? this.speakerConfidence,
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
      'speakerId': speakerId,
      'speakerDisplayName': speakerDisplayName,
      'speakerColor': speakerColor,
      'speakerPosition': speakerPosition != null
          ? {'x': speakerPosition!.x, 'y': speakerPosition!.y, 'z': speakerPosition!.z}
          : null,
      'speakerConfidence': speakerConfidence,
    };
  }

  /// Create from JSON
  factory SpeechResult.fromJson(Map<String, dynamic> json) {
    Vector3? position;
    if (json['speakerPosition'] != null) {
      final pos = json['speakerPosition'] as Map<String, dynamic>;
      position = Vector3(
        (pos['x'] as num).toDouble(),
        (pos['y'] as num).toDouble(),
        (pos['z'] as num).toDouble(),
      );
    }
    
    return SpeechResult(
      text: json['text'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      isFinal: json['isFinal'] as bool,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      speakerDirection: json['speakerDirection'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      speakerId: json['speakerId'] as String?,
      speakerDisplayName: json['speakerDisplayName'] as String?,
      speakerColor: json['speakerColor'] as int?,
      speakerPosition: position,
      speakerConfidence: json['speakerConfidence'] as double?,
    );
  }
  
  /// Check if this result has speaker diarization data
  bool get hasSpeakerDiarization => speakerId != null;
  
  /// Get display name for speaker (falls back to ID or direction)
  String get speakerLabel => 
      speakerDisplayName ?? speakerId ?? speakerDirection ?? 'Unknown';

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
        other.speakerDirection == speakerDirection &&
        other.speakerId == speakerId;
  }

  @override
  int get hashCode {
    return Object.hash(
      text,
      confidence,
      isFinal,
      timestamp,
      speakerDirection,
      speakerId,
    );
  }
}
