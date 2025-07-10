import 'package:flutter/material.dart';
import 'caption_bubble.dart';

class CaptionData {
  final String text;
  final Alignment alignment;
  final bool visible;
  final DateTime timestamp;

  CaptionData({
    required this.text,
    required this.alignment,
    this.visible = true,
    required this.timestamp,
  });
}

class CaptionOverlay extends StatefulWidget {
  final List<CaptionData> captions;
  final Duration fadeDuration;
  final Duration displayDuration;

  const CaptionOverlay({
    required this.captions,
    this.fadeDuration = const Duration(milliseconds: 300),
    this.displayDuration = const Duration(seconds: 4),
    Key? key,
  }) : super(key: key);

  @override
  State<CaptionOverlay> createState() => _CaptionOverlayState();
}

class _CaptionOverlayState extends State<CaptionOverlay> {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Stack(
      children: widget.captions.map((caption) {
        final timeSince = now.difference(caption.timestamp);
        final isVisible = timeSince < widget.displayDuration;
        return CaptionBubble(
          text: caption.text,
          alignment: caption.alignment,
          visible: isVisible,
        );
      }).toList(),
    );
  }
} 