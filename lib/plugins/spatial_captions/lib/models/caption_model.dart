import 'package:vector_math/vector_math_64.dart';
import '../spatial_captions.dart';

class CaptionModel {
  final String id;
  final String text;
  final Vector3 position;
  final CaptionType type;
  final String? speakerId;
  final DateTime timestamp;
  final double confidence;
  
  // For tracking caption lifecycle
  final String? replacesId;  // ID of caption this one replaces
  final bool isActive;
  
  CaptionModel({
    required this.id,
    required this.text,
    required this.position,
    this.type = CaptionType.partial,
    this.speakerId,
    DateTime? timestamp,
    this.confidence = 1.0,
    this.replacesId,
    this.isActive = true,
  }) : timestamp = timestamp ?? DateTime.now();

  CaptionModel copyWith({
    String? id,
    String? text,
    Vector3? position,
    CaptionType? type,
    String? speakerId,
    DateTime? timestamp,
    double? confidence,
    String? replacesId,
    bool? isActive,
  }) {
    return CaptionModel(
      id: id ?? this.id,
      text: text ?? this.text,
      position: position ?? this.position,
      type: type ?? this.type,
      speakerId: speakerId ?? this.speakerId,
      timestamp: timestamp ?? this.timestamp,
      confidence: confidence ?? this.confidence,
      replacesId: replacesId ?? this.replacesId,
      isActive: isActive ?? this.isActive,
    );
  }

  bool get isPartial => type == CaptionType.partial;
  bool get isFinal => type == CaptionType.final_;
  bool get isEnhanced => type == CaptionType.enhanced;
  
  /// Check if this caption should be replaced by another
  bool shouldBeReplacedBy(CaptionModel other) {
    // A partial caption should be replaced by a final one with the same speaker
    if (isPartial && other.isFinal && speakerId == other.speakerId) {
      return true;
    }
    
    // A final caption should be replaced by an enhanced one
    if (isFinal && other.isEnhanced && other.replacesId == id) {
      return true;
    }
    
    return false;
  }
} 