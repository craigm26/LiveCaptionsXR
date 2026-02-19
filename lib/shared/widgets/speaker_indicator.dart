import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vec;
import '../../core/models/speaker_profile.dart';

/// Widget that displays a speaker indicator with position and activity status
class SpeakerIndicator extends StatelessWidget {
  final SpeakerProfile speaker;
  final bool isActive;
  final VoidCallback? onTap;
  final bool showPosition;
  
  const SpeakerIndicator({
    super.key,
    required this.speaker,
    this.isActive = false,
    this.onTap,
    this.showPosition = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final color = Color(speaker.colorValue);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive 
              ? color.withAlpha((255 * 0.3).round())
              : color.withAlpha((255 * 0.1).round()),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : color.withAlpha((255 * 0.5).round()),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Speaker avatar/indicator
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getInitial(speaker),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            
            // Speaker name and info
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  speaker.displayName ?? 'Speaker ${_getSpeakerNumber(speaker.id)}',
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white70,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
                if (showPosition) ...[
                  Text(
                    _formatPosition(speaker.currentPosition),
                    style: TextStyle(
                      color: Colors.white.withAlpha((255 * 0.5).round()),
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
            
            // Activity indicator
            if (isActive) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  String _getInitial(SpeakerProfile speaker) {
    if (speaker.displayName != null && speaker.displayName!.isNotEmpty) {
      return speaker.displayName![0].toUpperCase();
    }
    return _getSpeakerNumber(speaker.id).toString();
  }
  
  int _getSpeakerNumber(String id) {
    // Extract number from speaker ID (e.g., "speaker_1_..." → 1)
    final match = RegExp(r'speaker_(\d+)').firstMatch(id);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '1') ?? 1;
    }
    return id.hashCode % 10;
  }
  
  String _formatPosition(vec.Vector3 pos) {
    final direction = _getDirection(pos);
    final distance = pos.length.toStringAsFixed(1);
    return '$direction, ${distance}m';
  }
  
  String _getDirection(vec.Vector3 pos) {
    final angle = atan2(pos.x, -pos.z);
    if (angle < -0.5) return '← Left';
    if (angle > 0.5) return 'Right →';
    return 'Center';
  }
}

/// Widget that displays a horizontal list of all tracked speakers
class SpeakerTracker extends StatelessWidget {
  final List<SpeakerProfile> speakers;
  final String? activeSpeakerId;
  final void Function(SpeakerProfile)? onSpeakerTap;
  
  const SpeakerTracker({
    super.key,
    required this.speakers,
    this.activeSpeakerId,
    this.onSpeakerTap,
  });
  
  @override
  Widget build(BuildContext context) {
    if (speakers.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Sort by most recent activity
    final sortedSpeakers = List<SpeakerProfile>.from(speakers)
      ..sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
    
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sortedSpeakers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final speaker = sortedSpeakers[index];
          return SpeakerIndicator(
            speaker: speaker,
            isActive: speaker.id == activeSpeakerId,
            showPosition: true,
            onTap: onSpeakerTap != null 
                ? () => onSpeakerTap!(speaker)
                : null,
          );
        },
      ),
    );
  }
}

/// Widget that shows spatial positioning of speakers in a radar-like view
class SpeakerRadar extends StatelessWidget {
  final List<SpeakerProfile> speakers;
  final String? activeSpeakerId;
  final double size;
  
  const SpeakerRadar({
    super.key,
    required this.speakers,
    this.activeSpeakerId,
    this.size = 200,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black.withAlpha((255 * 0.3).round()),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24),
      ),
      child: Stack(
        children: [
          // Grid lines
          CustomPaint(
            size: Size(size, size),
            painter: _RadarGridPainter(),
          ),
          
          // User position (center)
          Positioned(
            left: size / 2 - 6,
            top: size / 2 - 6,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          // Field of view indicator
          CustomPaint(
            size: Size(size, size),
            painter: _FieldOfViewPainter(),
          ),
          
          // Speaker positions
          ...speakers.map((speaker) => _buildSpeakerDot(speaker)),
        ],
      ),
    );
  }
  
  Widget _buildSpeakerDot(SpeakerProfile speaker) {
    final pos = speaker.currentPosition;
    
    // Convert 3D position to 2D radar position
    // x goes right, z goes forward (negative z = in front)
    final maxRange = 5.0; // 5 meters max display range
    final normalizedX = (pos.x / maxRange).clamp(-1.0, 1.0);
    final normalizedZ = (-pos.z / maxRange).clamp(-1.0, 1.0);
    
    // Convert to screen coordinates (center is 0.5, 0.5)
    final screenX = size * (0.5 + normalizedX * 0.4);
    final screenY = size * (0.5 - normalizedZ * 0.4);
    
    final isActive = speaker.id == activeSpeakerId;
    final color = Color(speaker.colorValue);
    final dotSize = isActive ? 16.0 : 12.0;
    
    return Positioned(
      left: screenX - dotSize / 2,
      top: screenY - dotSize / 2,
      child: Container(
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isActive 
              ? Border.all(color: Colors.white, width: 2)
              : null,
          boxShadow: isActive ? [
            BoxShadow(
              color: color.withAlpha((255 * 0.5).round()),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ] : null,
        ),
        child: Center(
          child: Text(
            speaker.displayName?[0].toUpperCase() ?? 
                _getSpeakerNumber(speaker.id).toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: isActive ? 10 : 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
  
  int _getSpeakerNumber(String id) {
    final match = RegExp(r'speaker_(\d+)').firstMatch(id);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '1') ?? 1;
    }
    return id.hashCode % 10;
  }
}

class _RadarGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha((255 * 0.1).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw concentric circles
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, size.width / 2 * i / 3, paint);
    }
    
    // Draw cross lines
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FieldOfViewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withAlpha((255 * 0.1).round())
      ..style = PaintingStyle.fill;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw 120-degree field of view cone pointing up (forward)
    final path = Path();
    path.moveTo(center.dx, center.dy);
    path.lineTo(center.dx - radius * 0.87, center.dy - radius * 0.5);
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      -2.618, // -150 degrees
      1.047,  // 60 degrees
      false,
    );
    path.lineTo(center.dx + radius * 0.87, center.dy - radius * 0.5);
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
