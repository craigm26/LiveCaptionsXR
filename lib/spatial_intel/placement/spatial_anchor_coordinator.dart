import 'package:live_captions_xr/spatial_intel/decoding/decode_policy.dart';
import 'package:live_captions_xr/spatial_intel/fusion/doa_localizer.dart';
import 'package:live_captions_xr/spatial_intel/fusion/kalman_anchor.dart';
import 'package:live_captions_xr/spatial_intel/placement/anchor_policy.dart';
import 'package:live_captions_xr/spatial_intel/placement/occlusion_avoidance.dart';
import 'package:live_captions_xr/spatial_intel/streams/predictive_stream_hub.dart';
import 'package:vector_math/vector_math_64.dart';

class SpatialAnchorCoordinator {
  SpatialAnchorCoordinator({
    required PredictiveStreamHub streamHub,
    required DecodePolicy policy,
  })  : _doaLocalizer = DoaLocalizer(sensorBus: streamHub.sensors),
        _kalmanAnchor = KalmanAnchor(),
        _occlusionAvoidance = OcclusionAvoidance(policy: policy) {
    _anchorPolicy = AnchorPolicy(
      policy: policy,
      doaLocalizer: _doaLocalizer,
      kalmanAnchor: _kalmanAnchor,
    );
  }

  late final DoaLocalizer _doaLocalizer;
  late final KalmanAnchor _kalmanAnchor;
  late AnchorPolicy _anchorPolicy;
  final OcclusionAvoidance _occlusionAvoidance;

  AnchorDecision chooseAnchor({
    Vector3? fusedTransformPosition,
    Map<String, dynamic>? speakerMetadata,
    double spatialConfidence = 0.0,
  }) {
    final doa = _doaLocalizer.currentEstimate;
    final occluded =
        _occlusionAvoidance.shouldRecenter(speakerMetadata: speakerMetadata);
    return _anchorPolicy.decide(
      fusedTransformPosition: fusedTransformPosition,
      doaEstimate: doa,
      spatialConfidence: spatialConfidence,
      occludingFace: occluded,
    );
  }

  Future<void> dispose() async {
    await _doaLocalizer.dispose();
  }

  void updatePolicy(DecodePolicy policy) {
    _anchorPolicy = AnchorPolicy(
      policy: policy,
      doaLocalizer: _doaLocalizer,
      kalmanAnchor: _kalmanAnchor,
    );
  }
}

