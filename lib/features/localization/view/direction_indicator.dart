import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/localization_cubit.dart';

/// Animated direction indicator showing speaker location with confidence coloring
/// and support for multiple simultaneous speakers.
class DirectionIndicator extends StatefulWidget {
  final double size;
  final bool showLabel;

  const DirectionIndicator({
    Key? key,
    this.size = 80.0,
    this.showLabel = true,
  }) : super(key: key);

  @override
  State<DirectionIndicator> createState() => _DirectionIndicatorState();
}

class _DirectionIndicatorState extends State<DirectionIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _targetAngle = 0.0;
  double _currentAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addListener(() {
        setState(() {
          _currentAngle =
              _lerpAngle(_currentAngle, _targetAngle, _controller.value);
        });
      });
  }

  double _lerpAngle(double from, double to, double t) {
    double diff = to - from;
    if (diff > math.pi) diff -= 2 * math.pi;
    if (diff < -math.pi) diff += 2 * math.pi;
    return from + diff * t;
  }

  double _directionToAngle(String direction) {
    switch (direction) {
      case 'left':
        return -math.pi / 4;
      case 'right':
        return math.pi / 4;
      case 'center':
      default:
        return 0.0;
    }
  }

  Color _confidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.greenAccent;
    if (confidence >= 0.5) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LocalizationCubit, LocalizationState>(
      listener: (context, state) {
        if (state is LocalizationLoaded) {
          final newAngle = _directionToAngle(state.direction);
          if ((_targetAngle - newAngle).abs() > 0.01) {
            _targetAngle = newAngle;
            _controller.forward(from: 0.0);
          }
        }
      },
      builder: (context, state) {
        if (state is! LocalizationLoaded) {
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: Center(
              child: Icon(
                Icons.hearing_disabled,
                color: Colors.grey.withOpacity(0.4),
                size: widget.size * 0.4,
              ),
            ),
          );
        }

        final confidence = state.confidence;
        final color = _confidenceColor(confidence);
        final direction = state.direction;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _DirectionPainter(
                  angle: _currentAngle,
                  color: color,
                  confidence: confidence,
                ),
                child: Center(
                  child: Transform.rotate(
                    angle: _currentAngle,
                    child: Icon(
                      Icons.navigation,
                      color: color,
                      size: widget.size * 0.45,
                    ),
                  ),
                ),
              ),
            ),
            if (widget.showLabel) ...[
              const SizedBox(height: 4),
              Text(
                '${direction[0].toUpperCase()}${direction.substring(1)} · ${(confidence * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _DirectionPainter extends CustomPainter {
  final double angle;
  final Color color;
  final double confidence;

  _DirectionPainter({
    required this.angle,
    required this.color,
    required this.confidence,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Outer ring
    final ringPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, ringPaint);

    // Confidence arc
    final arcPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final sweepAngle = confidence * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + angle - sweepAngle / 2,
      sweepAngle,
      false,
      arcPaint,
    );

    // Direction dot at the edge
    final dotX = center.dx + radius * math.sin(angle);
    final dotY = center.dy - radius * math.cos(angle);
    final dotPaint = Paint()..color = color;
    canvas.drawCircle(Offset(dotX, dotY), 5, dotPaint);
  }

  @override
  bool shouldRepaint(_DirectionPainter old) =>
      old.angle != angle || old.color != color || old.confidence != confidence;
}
