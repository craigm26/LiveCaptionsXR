import 'dart:async';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

import '../models/detected_speaker.dart';
import 'app_logger.dart';
import 'camera_service.dart';

/// Coordinates camera frames, native detectors, and speaker tracking signals.
class VisualSpeakerService {
  VisualSpeakerService({
    required CameraService cameraService,
    MethodChannel? methodChannel,
  })  : _cameraService = cameraService,
        _channel = methodChannel ??
            const MethodChannel('live_captions_xr/visual_speaker_methods');

  final CameraService _cameraService;
  final MethodChannel _channel;
  static final AppLogger _logger = AppLogger.instance;

  bool _isRunning = false;

  final StreamController<List<DetectedSpeaker>> _detectedSpeakerController =
      StreamController<List<DetectedSpeaker>>.broadcast();

  Stream<List<DetectedSpeaker>> get detectedSpeakers =>
      _detectedSpeakerController.stream;

  bool get isRunning => _isRunning;

  Future<void> start() async {
    if (_isRunning) {
      _logger.w(
        'VisualSpeakerService already running, start skipped',
        category: LogCategory.camera,
      );
      return;
    }

    await _cameraService.initialize();

    // Add listener
    _cameraService.addOnFrameListener(_processFrame);

    _cameraService.startCamera();

    _channel.setMethodCallHandler(_handleMethodCall);

    _isRunning = true;
    _logger.i(
      'VisualSpeakerService started',
      category: LogCategory.camera,
    );
  }

  Future<void> stop() async {
    if (!_isRunning) {
      return;
    }

    // Remove listener and stop the camera
    _cameraService.removeOnFrameListener(_processFrame);
    _cameraService.stopCamera();

    _channel.setMethodCallHandler(null);
    _isRunning = false;
    _logger.i('VisualSpeakerService stopped', category: LogCategory.camera);
  }

  void dispose() {
    stop();
    _detectedSpeakerController.close();
  }

  Future<void> _processFrame(CameraImage image) async {
    try {
      final plane = image.planes.first;
      final bytes = plane.bytes;

      await _channel.invokeMethod('processCameraFrame', {
        'bytes': bytes,
        'timestampMicros': DateTime.now().microsecondsSinceEpoch,
        'format': 'yuv420',
        'width': image.width,
        'height': image.height,
      });
    } on PlatformException catch (e, stackTrace) {
      _logger.e(
        'Failed sending frame to native visual speaker detector',
        category: LogCategory.camera,
        error: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      _logger.e(
        'Unexpected error processing camera frame',
        category: LogCategory.camera,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method != 'onSpeakersDetected') {
      _logger.w(
        'Unknown method ${call.method} on visual speaker channel',
        category: LogCategory.camera,
      );
      return;
    }
    final payload = call.arguments;
    if (payload is! List) {
      _logger.w(
        'Ignoring malformed speaker payload: $payload',
        category: LogCategory.camera,
      );
      return;
    }
    final detections = payload
        .whereType<Map>()
        .map((entry) => _mapDetectedSpeaker(Map<String, dynamic>.from(entry)))
        .whereType<DetectedSpeaker>()
        .toList();
    if (detections.isNotEmpty && !_detectedSpeakerController.isClosed) {
      _detectedSpeakerController.add(detections);
    }
  }

  DetectedSpeaker? _mapDetectedSpeaker(Map<String, dynamic> data) {
    try {
      final bbox = data['boundingBox'] as List<dynamic>? ?? const [0, 0, 1, 1];
      final rect = Rect.fromLTWH(
        (bbox[0] as num).toDouble(),
        (bbox[1] as num).toDouble(),
        (bbox[2] as num).toDouble(),
        (bbox[3] as num).toDouble(),
      );
      final timestampMicros = (data['timestampMicros'] as num?)?.toInt() ??
          DateTime.now().microsecondsSinceEpoch;
      final landmarksRaw = data['landmarks'] as List<dynamic>?;
      final landmarks = landmarksRaw
          ?.map((point) => Offset(
                (point['x'] as num).toDouble(),
                (point['y'] as num).toDouble(),
              ))
          .toList();
      final transformRaw = data['worldTransform'] as List<dynamic>?;
      return DetectedSpeaker(
        faceId: data['faceId'] as int,
        boundingBox: rect,
        timestamp:
            DateTime.fromMicrosecondsSinceEpoch(timestampMicros, isUtc: true)
                .toLocal(),
        confidence: (data['confidence'] as num?)?.toDouble() ?? 0,
        state: _stateFromString(data['state'] as String?),
        landmarks: landmarks,
        worldTransform:
            transformRaw?.map((e) => (e as num).toDouble()).toList(),
      );
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to parse detected speaker: $data',
        category: LogCategory.camera,
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  SpeakerState _stateFromString(String? value) {
    switch (value) {
      case 'speaking':
        return SpeakerState.speaking;
      case 'silent':
        return SpeakerState.silent;
      default:
        return SpeakerState.unknown;
    }
  }
}
