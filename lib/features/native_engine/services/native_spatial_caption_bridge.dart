import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:spatial_captions/cubit/spatial_captions_cubit.dart';

import '../../../core/models/native_engine_event.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/services/native_caption_engine_bridge.dart';
import '../../../spatial_intel/streams/predictive_stream_hub.dart';
import '../../../spatial_intel/streams/spatial_sensor_stream.dart';

class NativeSpatialCaptionBridge {
  NativeSpatialCaptionBridge({
    required NativeCaptionEngineBridge bridge,
    required SpatialCaptionsCubit spatialCaptionsCubit,
    PredictiveStreamHub? predictiveStreamHub,
  })  : _bridge = bridge,
        _spatialCaptionsCubit = spatialCaptionsCubit,
        _predictiveStreamHub = predictiveStreamHub;

  final NativeCaptionEngineBridge _bridge;
  final SpatialCaptionsCubit _spatialCaptionsCubit;
  final PredictiveStreamHub? _predictiveStreamHub;
  final AppLogger _logger = AppLogger.instance;

  final Map<String, NativeSpeakerDirection?> _lastDirections = {};
  final Map<String, Vector3> _lastPositions = {};
  final Map<String, String> _lastPartialText = {};
  StreamSubscription<NativeEngineEvent>? _subscription;
  bool _spatialEnabled = true;

  bool get isActive => _subscription != null;

  Future<void> start() async {
    if (_subscription != null ||
        !_bridge.isSupported ||
        kIsWeb ||
        !Platform.isAndroid) {
      return;
    }
    _logger.d('?? Starting NativeSpatialCaptionBridge',
        category: LogCategory.captions);
    _subscription = _bridge.events.listen(
      _handleEvent,
      onError: (error, stackTrace) {
        _logger.e('?? NativeSpatialCaptionBridge stream error',
            category: LogCategory.captions,
            error: error,
            stackTrace: stackTrace);
      },
    );
  }

  Future<void> stop() async {
    _logger.d('?? Stopping NativeSpatialCaptionBridge',
        category: LogCategory.captions);
    await _subscription?.cancel();
    _subscription = null;
    _lastDirections.clear();
    _lastPositions.clear();
    _lastPartialText.clear();
  }

  void _handleEvent(NativeEngineEvent event) {
    if (event is NativeSpeakerUpdateEvent) {
      _lastDirections[event.speakerId] = event.direction;
      if (event.text.trim().isEmpty) return;
      _publishPartial(
        speakerId: event.speakerId,
        text: event.text,
        direction: event.direction,
      );
    } else if (event is NativeCaptionUpdateEvent) {
      final speakerId = event.speakerId ?? 'unknown';
      if (event.text.trim().isEmpty) return;
      if (event.isFinal) {
        _publishFinal(
          speakerId: speakerId,
          text: event.text,
        );
      } else {
        _publishPartial(
          speakerId: speakerId,
          text: event.text,
          direction: null,
        );
      }
    }
  }

  void _publishPartial({
    required String speakerId,
    required String text,
    NativeSpeakerDirection? direction,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _lastPartialText[speakerId] == trimmed) {
      return;
    }
    _lastPartialText[speakerId] = trimmed;
    final position = _resolvePosition(speakerId, direction);
    if (_spatialEnabled) {
      unawaited(_runSpatialCommand(() =>
          _spatialCaptionsCubit.addPartialCaption(
              text: trimmed,
              speakerId: speakerId,
              position: position,
              confidence: direction?.confidence ?? 1.0)));
    }
    if (direction != null) {
      _publishDoa(direction);
    }
  }

  void _publishFinal({
    required String speakerId,
    required String text,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final position = _resolvePosition(speakerId, null);
    if (_spatialEnabled) {
      unawaited(_runSpatialCommand(() => _spatialCaptionsCubit.finalizeCaption(
          text: trimmed, speakerId: speakerId, position: position)));
    }
    _lastPartialText.remove(speakerId);
  }

  Vector3 _resolvePosition(
      String speakerId, NativeSpeakerDirection? direction) {
    final dir = direction ?? _lastDirections[speakerId];
    final fromDir = dir != null ? _vectorFromDirection(dir) : null;
    if (fromDir != null) {
      _lastPositions[speakerId] = fromDir;
      return fromDir;
    }
    return _lastPositions[speakerId] ?? Vector3(0, 0, -_defaultRadius);
  }

  Vector3? _vectorFromDirection(NativeSpeakerDirection direction) {
    final azimuthRad = radians(direction.azimuthDeg);
    final elevationRad = radians(direction.elevationDeg);
    final x = _defaultRadius * cos(elevationRad) * sin(azimuthRad);
    final y = _defaultRadius * sin(elevationRad);
    final z = -_defaultRadius * cos(elevationRad) * cos(azimuthRad);
    if (x.isNaN || y.isNaN || z.isNaN) return null;
    return Vector3(x, y, z);
  }

  double radians(double degrees) => degrees * pi / 180.0;

  static const double _defaultRadius = 2.0;

  Future<void> _runSpatialCommand(Future<void> Function() command) async {
    if (!_spatialEnabled) return;
    try {
      await command();
    } on MissingPluginException catch (e, stackTrace) {
      _spatialEnabled = false;
      _logger.w(
        '?? Spatial captions plugin missing, disabling native spatial bridge',
        category: LogCategory.captions,
        error: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      _logger.e(
        '?? Spatial captions command failed',
        category: LogCategory.captions,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _publishDoa(NativeSpeakerDirection direction) {
    final hub = _predictiveStreamHub;
    if (hub == null) return;
    try {
      hub.sensors.publishDoa(
        DoaEstimate(
          azimuth: radians(direction.azimuthDeg),
          elevation: radians(direction.elevationDeg),
          confidence: direction.confidence.clamp(0, 1),
        ),
      );
    } catch (e, stackTrace) {
      _logger.w(
        '?? Failed to publish DOA estimate from native engine',
        category: LogCategory.captions,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
