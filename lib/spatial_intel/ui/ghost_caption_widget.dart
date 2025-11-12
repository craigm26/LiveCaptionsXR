import 'package:flutter/material.dart';
import 'package:live_captions_xr/spatial_intel/decoding/decode_policy.dart';
import 'package:live_captions_xr/spatial_intel/predict/next_token_stream.dart';
import 'package:live_captions_xr/spatial_intel/ui/confidence_styles.dart';

class GhostCaptionWidget extends StatelessWidget {
  const GhostCaptionWidget({
    super.key,
    required this.state,
    required this.policy,
    required this.baseStyle,
  });

  final NextTokenState? state;
  final DecodePolicy policy;
  final TextStyle baseStyle;

  @override
  Widget build(BuildContext context) {
    if (state == null) {
      return const SizedBox.shrink();
    }
    final styles = ConfidenceStyles(policy: policy, baseStyle: baseStyle);
    final spans = <TextSpan>[];

    if (state!.stableText.isNotEmpty) {
      spans.add(
        TextSpan(
          text: state!.stableText,
          style: styles.committedStyle(),
        ),
      );
    }

    if (state!.preview.isNotEmpty) {
      if (state!.stableText.isNotEmpty &&
          !_shouldOmitSpace(
            state!.stableText[state!.stableText.length - 1],
          )) {
        spans.add(TextSpan(text: ' ', style: baseStyle));
      }
      String? previousToken;
      for (final token in state!.preview) {
        if (previousToken != null && _needsSpace(previousToken, token.value)) {
          spans.add(TextSpan(text: ' ', style: baseStyle));
        }
        spans.add(
          TextSpan(
            text: token.value,
            style: styles.previewStyle(token),
          ),
        );
        previousToken = token.value;
      }
    }

    if (state!.revoked.isNotEmpty) {
      spans.add(TextSpan(text: ' ', style: baseStyle));
      for (final token in state!.revoked) {
        spans.add(
          TextSpan(
            text: token.value,
            style: styles.revokedStyle(token),
          ),
        );
        spans.add(TextSpan(text: ' ', style: baseStyle));
      }
    }

    if (spans.isEmpty) {
      return const SizedBox.shrink();
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  bool _shouldOmitSpace(String char) {
    return RegExp(r'[^\w\s]').hasMatch(char);
  }

  bool _needsSpace(String previous, String current) {
    const punctuation = {
      '.',
      ',',
      '!',
      '?',
      ';',
      ':',
      '"',
      '\'',
    };
    if (punctuation.contains(current)) {
      return false;
    }
    if (previous.endsWith('-')) {
      return false;
    }
    return true;
  }
}

