import 'multimodal_event.dart';

/// Model representing a detected sound event with multimodal context
///
/// This model demonstrates how we structure data for Gemma 3n integration,
/// combining audio analysis with spatial and visual context for accessibility.
///
/// For Google Gemma 3n Hackathon: Shows comprehensive event modeling
/// that leverages Gemma 3n's multimodal understanding capabilities.
class SoundEvent extends MultimodalEvent {
  /// Type of sound detected (e.g., 'doorbell', 'fire alarm', 'voice')
  final String type;

  /// Timestamp when the sound was detected
  final DateTime timestamp;

  /// Spatial direction of sound source (e.g., 'front', 'left', 'behind')
  final String sourceDirection;

  /// Whether this event was processed through multimodal Gemma 3n analysis
  /// True: Full audio+visual+context analysis
  /// False: Audio-only analysis
  final bool isMultimodal;

  /// Priority level for accessibility feedback
  /// emergency: Fire alarm, medical alert, etc.
  /// high: Doorbell, phone, timer
  /// medium: Conversations, notifications
  /// low: Background noise, ambient sounds
  final String priority;

  SoundEvent({
    required this.type,
    required double confidence,
    required this.timestamp,
    this.sourceDirection = 'unknown',
    String description = '',
    this.isMultimodal = false,
    this.priority = 'medium',
    Map<String, dynamic> metadata = const {},
  }) : super(
          confidence: confidence,
          description: description,
          metadata: metadata,
        );
  
  /// Create a copy with updated fields
  SoundEvent copyWith({
    String? type,
    double? confidence,
    DateTime? timestamp,
    String? sourceDirection,
    String? description,
    bool? isMultimodal,
    String? priority,
    Map<String, dynamic>? metadata,
  }) {
    return SoundEvent(
      type: type ?? this.type,
      confidence: confidence ?? this.confidence,
      timestamp: timestamp ?? this.timestamp,
      sourceDirection: sourceDirection ?? this.sourceDirection,
      description: description ?? this.description,
      isMultimodal: isMultimodal ?? this.isMultimodal,
      priority: priority ?? this.priority,
      metadata: metadata ?? this.metadata,
    );
  }
  
  /// Convert to JSON for storage or transmission
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
      'sourceDirection': sourceDirection,
      'description': description,
      'isMultimodal': isMultimodal,
      'priority': priority,
      'metadata': metadata,
    };
  }
  
  /// Create from JSON
  factory SoundEvent.fromJson(Map<String, dynamic> json) {
    return SoundEvent(
      type: json['type'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      sourceDirection: json['sourceDirection'] as String? ?? 'unknown',
      description: json['description'] as String? ?? '',
      isMultimodal: json['isMultimodal'] as bool? ?? false,
      priority: json['priority'] as String? ?? 'medium',
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }
  
  /// Human-readable string representation
  @override
  String toString() {
    return 'SoundEvent(type: $type, confidence: ${confidence.toStringAsFixed(2)}, '
           'direction: $sourceDirection, multimodal: $isMultimodal)';
  }
  
  /// Check if this is an emergency-level sound requiring immediate attention
  bool get isEmergency => priority == 'emergency';
  
  /// Check if confidence is high enough for reliable action
  bool get isReliable => confidence >= 0.7;
  
  /// Get appropriate haptic pattern based on sound type and priority
  List<int> get hapticPattern {
    switch (priority) {
      case 'emergency':
        return [200, 100, 200, 100, 300]; // Urgent pattern
      case 'high':
        return [150, 50, 150]; // Alert pattern
      case 'medium':
        return [100, 50]; // Standard pattern
      default:
        return [50]; // Gentle pattern
    }
  }
} 