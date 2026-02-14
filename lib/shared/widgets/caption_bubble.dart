import 'package:flutter/material.dart';

/// Simple caption bubble styled after TLOU2: dark semi-transparent backdrop,
/// clean white text, minimal border radius, no decorative borders or shadows.
class CaptionBubble extends StatelessWidget {
  final String text;
  final Alignment alignment;
  final bool visible;
  final String? speakerName;
  final Color? speakerColor;
  final String? direction; // 'left', 'right', or null for center

  const CaptionBubble({
    required this.text,
    required this.alignment,
    this.visible = true,
    this.speakerName,
    this.speakerColor,
    this.direction,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Align(
        alignment: alignment,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha((255 * 0.75).round()),
            borderRadius: BorderRadius.circular(4),
          ),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                // Direction arrow for offscreen speakers
                if (direction == 'left')
                  TextSpan(
                    text: '\u25C0 ', // ◀
                    style: TextStyle(
                      color: Colors.white.withAlpha((255 * 0.7).round()),
                      fontSize: 18,
                    ),
                  ),
                if (direction == 'right')
                  TextSpan(
                    text: '\u25B6 ', // ▶
                    style: TextStyle(
                      color: Colors.white.withAlpha((255 * 0.7).round()),
                      fontSize: 18,
                    ),
                  ),
                // Speaker name with color
                if (speakerName != null)
                  TextSpan(
                    text: '$speakerName: ',
                    style: TextStyle(
                      color: speakerColor ?? const Color(0xFF4FC3F7),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                // Caption text
                TextSpan(
                  text: text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
