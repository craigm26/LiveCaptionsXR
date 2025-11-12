import 'dart:math';

import 'package:live_captions_xr/spatial_intel/decoding/decode_policy.dart';
import 'package:live_captions_xr/spatial_intel/fusion/doa_localizer.dart';
import 'package:live_captions_xr/spatial_intel/fusion/kalman_anchor.dart';
import 'package:live_captions_xr/spatial_intel/streams/spatial_sensor_stream.dart';
import 'package:vector_math/vector_math_64.dart';

class AnchorDecision {
  AnchorDecision({
    required this.position,
    required this.useNeutralRail,
    required this.spatialConfidence,
    this.doaEstimate,
  });

  final Vector3 position;
  final bool useNeutralRail;
  final double spatialConfidence;
  final DoaEstimate? doaEstimate;
}

class AnchorPolicy {
  AnchorPolicy({
    required DecodePolicy policy,
    required DoaLocalizer doaLocalizer,
    required KalmanAnchor kalmanAnchor,
    double neutralDistance = 1.8,
  })  : _policy = policy,
        _doaLocalizer = doaLocalizer,
        _kalmanAnchor = kalmanAnchor,
        _neutralDistance = neutralDistance;

  final DecodePolicy _policy;
  final DoaLocalizer _doaLocalizer;
  final KalmanAnchor _kalmanAnchor;
  final double _neutralDistance;

  AnchorDecision decide({
    Vector3? fusedTransformPosition,
    DoaEstimate? doaEstimate,
    double spatialConfidence = 0.0,
    bool occludingFace = false,
  }) {
    final doa = doaEstimate ?? _doaLocalizer.currentEstimate;
    final List<double>? transform = fusedTransformPosition == null
        ? null
        : [fusedTransformPosition.x, fusedTransformPosition.y, fusedTransformPosition.z];

    bool useNeutralRail = occludingFace;
    Vector3 targetPosition;
    double confidence = spatialConfidence;

    if (!useNeutralRail && doa != null) {
      if (doa.confidence < 0.35) {
        useNeutralRail = true;
      } else {
        final azimuthDegrees = doa.azimuth * 180 / pi;
        if (azimuthDegrees.abs() > _policy.azimuthGateDeg) {
          useNeutralRail = true;
        } else {
          targetPosition = Vector3(
            _neutralDistance * sin(doa.azimuth),
            0.0,
            -_neutralDistance * cos(doa.azimuth),
          );
          _kalmanAnchor.update(targetPosition, confidence: doa.confidence);
          return AnchorDecision(
            position: _kalmanAnchor.position ?? targetPosition,
            useNeutralRail: false,
            spatialConfidence: max(confidence, doa.confidence),
            doaEstimate: doa,
          );
        }
      }
    }

    if (!useNeutralRail && transform != null) {
      final position = fusedTransformPosition!;
      _kalmanAnchor.update(position, confidence: max(confidence, 0.7));
      return AnchorDecision(
        position: _kalmanAnchor.position ?? position,
        useNeutralRail: false,
        spatialConfidence: max(confidence, 0.7),
        doaEstimate: doa,
      );
    }

    final neutralPosition = Vector3(0.0, 0.0, -_neutralDistance);
    if (_kalmanAnchor.position == null) {
      _kalmanAnchor.update(neutralPosition, confidence: 0.2);
    }
    return AnchorDecision(
      position: _kalmanAnchor.position ?? neutralPosition,
      useNeutralRail: true,
      spatialConfidence: max(confidence, 0.2),
      doaEstimate: doa,
    );
  }
}

