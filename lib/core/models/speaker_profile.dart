import 'dart:math';
import 'dart:typed_data';
import 'package:vector_math/vector_math_64.dart';

/// Represents a unique speaker identified through voice embedding analysis
class SpeakerProfile {
  final String id;
  final String? displayName;
  final Float32List voiceEmbedding;
  final DateTime firstSeen;
  DateTime lastSeen;
  
  // Spatial tracking (3D position + temporal history = 4D)
  final List<SpatialObservation> spatialHistory;
  static const int maxHistorySize = 50;
  
  // Voice characteristics
  double? pitchMean;
  double? pitchStd;
  double? energyMean;
  int utteranceCount;
  
  // Color for UI display (assigned when created)
  final int colorValue;
  
  SpeakerProfile({
    required this.id,
    this.displayName,
    required this.voiceEmbedding,
    required this.firstSeen,
    DateTime? lastSeen,
    List<SpatialObservation>? spatialHistory,
    this.pitchMean,
    this.pitchStd,
    this.energyMean,
    this.utteranceCount = 1,
    int? colorValue,
  })  : lastSeen = lastSeen ?? firstSeen,
        spatialHistory = spatialHistory ?? [],
        colorValue = colorValue ?? _generateColor(id);
  
  /// Generate a consistent color from speaker ID
  static int _generateColor(String id) {
    final hash = id.hashCode;
    final hue = (hash % 360).abs().toDouble();
    // Convert HSL to RGB (saturation 0.7, lightness 0.5)
    return _hslToRgb(hue, 0.7, 0.5);
  }
  
  static int _hslToRgb(double h, double s, double l) {
    final c = (1 - (2 * l - 1).abs()) * s;
    final x = c * (1 - ((h / 60) % 2 - 1).abs());
    final m = l - c / 2;
    
    double r, g, b;
    if (h < 60) {
      r = c; g = x; b = 0;
    } else if (h < 120) {
      r = x; g = c; b = 0;
    } else if (h < 180) {
      r = 0; g = c; b = x;
    } else if (h < 240) {
      r = 0; g = x; b = c;
    } else if (h < 300) {
      r = x; g = 0; b = c;
    } else {
      r = c; g = 0; b = x;
    }
    
    final ri = ((r + m) * 255).round();
    final gi = ((g + m) * 255).round();
    final bi = ((b + m) * 255).round();
    
    return 0xFF000000 | (ri << 16) | (gi << 8) | bi;
  }
  
  /// Get the current estimated 3D position (weighted average of recent observations)
  Vector3 get currentPosition {
    if (spatialHistory.isEmpty) {
      return Vector3(0, 0, -2); // Default: 2m in front
    }
    
    // Weighted average with exponential decay (recent observations matter more)
    final now = DateTime.now();
    double totalWeight = 0;
    double x = 0, y = 0, z = 0;
    
    for (final obs in spatialHistory) {
      final age = now.difference(obs.timestamp).inMilliseconds;
      // Decay with half-life of 2 seconds
      final weight = exp(-age / 2000.0) * obs.confidence;
      totalWeight += weight;
      x += obs.position.x * weight;
      y += obs.position.y * weight;
      z += obs.position.z * weight;
    }
    
    if (totalWeight < 0.001) {
      return spatialHistory.last.position;
    }
    
    return Vector3(x / totalWeight, y / totalWeight, z / totalWeight);
  }
  
  /// Get position velocity (movement direction)
  Vector3 get velocity {
    if (spatialHistory.length < 2) return Vector3.zero();
    
    final recent = spatialHistory.take(5).toList();
    if (recent.length < 2) return Vector3.zero();
    
    // Calculate average velocity from recent observations
    double vx = 0, vy = 0, vz = 0;
    int count = 0;
    
    for (int i = 1; i < recent.length; i++) {
      final dt = recent[i-1].timestamp.difference(recent[i].timestamp).inMilliseconds / 1000.0;
      if (dt > 0.01) {
        vx += (recent[i-1].position.x - recent[i].position.x) / dt;
        vy += (recent[i-1].position.y - recent[i].position.y) / dt;
        vz += (recent[i-1].position.z - recent[i].position.z) / dt;
        count++;
      }
    }
    
    if (count == 0) return Vector3.zero();
    return Vector3(vx / count, vy / count, vz / count);
  }
  
  /// Predict position at a future time
  Vector3 predictPosition(Duration ahead) {
    final current = currentPosition;
    final vel = velocity;
    final dt = ahead.inMilliseconds / 1000.0;
    
    return Vector3(
      current.x + vel.x * dt,
      current.y + vel.y * dt,
      current.z + vel.z * dt,
    );
  }
  
  /// Add a new spatial observation
  void addSpatialObservation(Vector3 position, {double confidence = 1.0}) {
    spatialHistory.insert(0, SpatialObservation(
      position: position,
      timestamp: DateTime.now(),
      confidence: confidence,
    ));
    
    // Trim old observations
    while (spatialHistory.length > maxHistorySize) {
      spatialHistory.removeLast();
    }
    
    lastSeen = DateTime.now();
  }
  
  /// Calculate similarity to another voice embedding (cosine similarity)
  double similarityTo(Float32List otherEmbedding) {
    if (voiceEmbedding.length != otherEmbedding.length) return 0.0;
    
    double dotProduct = 0;
    double normA = 0;
    double normB = 0;
    
    for (int i = 0; i < voiceEmbedding.length; i++) {
      dotProduct += voiceEmbedding[i] * otherEmbedding[i];
      normA += voiceEmbedding[i] * voiceEmbedding[i];
      normB += otherEmbedding[i] * otherEmbedding[i];
    }
    
    if (normA < 1e-10 || normB < 1e-10) return 0.0;
    
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }
  
  /// Update voice characteristics with new observation
  void updateVoiceCharacteristics({
    double? pitch,
    double? energy,
  }) {
    utteranceCount++;
    
    if (pitch != null) {
      if (pitchMean == null) {
        pitchMean = pitch;
        pitchStd = 0;
      } else {
        // Online mean and variance update (Welford's algorithm)
        final delta = pitch - pitchMean!;
        pitchMean = pitchMean! + delta / utteranceCount;
        final delta2 = pitch - pitchMean!;
        pitchStd = sqrt(((pitchStd! * pitchStd! * (utteranceCount - 1)) + delta * delta2) / utteranceCount);
      }
    }
    
    if (energy != null) {
      if (energyMean == null) {
        energyMean = energy;
      } else {
        final delta = energy - energyMean!;
        energyMean = energyMean! + delta / utteranceCount;
      }
    }
  }
  
  /// Check if speaker was recently active
  bool get isRecentlyActive {
    return DateTime.now().difference(lastSeen).inSeconds < 30;
  }
  
  /// Get display color as Color-compatible integer
  int get color => colorValue;
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'voiceEmbedding': voiceEmbedding.toList(),
    'firstSeen': firstSeen.millisecondsSinceEpoch,
    'lastSeen': lastSeen.millisecondsSinceEpoch,
    'pitchMean': pitchMean,
    'pitchStd': pitchStd,
    'energyMean': energyMean,
    'utteranceCount': utteranceCount,
    'colorValue': colorValue,
    'currentPosition': {
      'x': currentPosition.x,
      'y': currentPosition.y,
      'z': currentPosition.z,
    },
  };
  
  factory SpeakerProfile.fromJson(Map<String, dynamic> json) {
    return SpeakerProfile(
      id: json['id'] as String,
      displayName: json['displayName'] as String?,
      voiceEmbedding: Float32List.fromList(
        (json['voiceEmbedding'] as List).cast<double>(),
      ),
      firstSeen: DateTime.fromMillisecondsSinceEpoch(json['firstSeen'] as int),
      lastSeen: DateTime.fromMillisecondsSinceEpoch(json['lastSeen'] as int),
      pitchMean: json['pitchMean'] as double?,
      pitchStd: json['pitchStd'] as double?,
      energyMean: json['energyMean'] as double?,
      utteranceCount: json['utteranceCount'] as int? ?? 1,
      colorValue: json['colorValue'] as int?,
    );
  }
  
  @override
  String toString() => 'SpeakerProfile($id, pos=${currentPosition.toString()}, utterances=$utteranceCount)';
}

/// A single spatial observation of a speaker
class SpatialObservation {
  final Vector3 position;
  final DateTime timestamp;
  final double confidence;
  
  const SpatialObservation({
    required this.position,
    required this.timestamp,
    this.confidence = 1.0,
  });
  
  Map<String, dynamic> toJson() => {
    'position': {'x': position.x, 'y': position.y, 'z': position.z},
    'timestamp': timestamp.millisecondsSinceEpoch,
    'confidence': confidence,
  };
}
