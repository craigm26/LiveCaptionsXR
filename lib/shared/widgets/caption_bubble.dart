import 'package:flutter/material.dart';

class CaptionBubble extends StatelessWidget {
  final String text;
  final Alignment alignment;
  final bool visible;

  const CaptionBubble({
    required this.text,
    required this.alignment,
    this.visible = true,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: Duration(milliseconds: 300),
      child: Align(
        alignment: alignment,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha((255 * 0.7).round()),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(blurRadius: 2, color: Colors.black)],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
