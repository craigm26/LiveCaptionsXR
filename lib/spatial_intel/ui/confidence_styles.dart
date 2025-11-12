import 'package:flutter/material.dart';
import 'package:live_captions_xr/spatial_intel/decoding/decode_policy.dart';
import 'package:live_captions_xr/spatial_intel/predict/next_token_stream.dart';

class ConfidenceStyles {
  ConfidenceStyles({
    required this.policy,
    required this.baseStyle,
  });

  final DecodePolicy policy;
  final TextStyle baseStyle;

  TextStyle committedStyle() {
    return baseStyle.copyWith(fontWeight: FontWeight.w600);
  }

  TextStyle previewStyle(PredictiveToken token) {
    final opacity = (policy.ghostAlpha +
            (token.probability * (1 - policy.ghostAlpha)))
        .clamp(policy.ghostAlpha, 1.0);
    Color color = (baseStyle.color ?? Colors.white).withOpacity(opacity);
    TextDecoration? decoration;
    Color? decorationColor;
    TextDecorationStyle? decorationStyle;
    if (token.entropy > policy.entropyMax) {
      decoration = TextDecoration.underline;
      decorationColor = Colors.orangeAccent.withOpacity(0.9);
      decorationStyle = TextDecorationStyle.wavy;
    } else if (token.probability < policy.tokenProbMin) {
      decoration = TextDecoration.underline;
      decorationColor = Colors.orangeAccent.withOpacity(0.6);
      decorationStyle = TextDecorationStyle.dotted;
    }
    return baseStyle.copyWith(
      color: color,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      fontStyle: token.entropy > policy.entropyMax ? FontStyle.italic : null,
    );
  }

  TextStyle revokedStyle(PredictiveToken token) {
    return baseStyle.copyWith(
      color: (baseStyle.color ?? Colors.white).withOpacity(0.3),
      decoration: TextDecoration.lineThrough,
      decorationColor: Colors.redAccent,
    );
  }
}

