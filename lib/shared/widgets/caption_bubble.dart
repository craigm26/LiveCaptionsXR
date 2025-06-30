import 'package:flutter/material.dart';

class CaptionBubble extends StatefulWidget {
  final String text;
  final Duration animationDuration;
  final VoidCallback onComplete;

  const CaptionBubble({
    Key? key,
    required this.text,
    this.animationDuration = const Duration(milliseconds: 300),
    required this.onComplete,
  }) : super(key: key);

  @override
  _CaptionBubbleState createState() => _CaptionBubbleState();
}

class _CaptionBubbleState extends State<CaptionBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 5), () {
          _controller.reverse().then((_) {
            widget.onComplete();
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          widget.text,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
