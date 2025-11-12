import 'package:live_captions_xr/spatial_intel/decoding/decode_policy.dart';

class OcclusionAvoidance {
  OcclusionAvoidance({required DecodePolicy policy})
      : _policy = policy;

  final DecodePolicy _policy;

  bool shouldRecenter({
    Map<String, dynamic>? speakerMetadata,
    double? estimatedOcclusionPct,
  }) {
    final occlusion = estimatedOcclusionPct ??
        (speakerMetadata?['bubbleOcclusionPct'] as num?)?.toDouble() ??
        0.0;
    return occlusion > _policy.faceOcclusionPctMax;
  }
}

