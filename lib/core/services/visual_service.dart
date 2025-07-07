import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'debug_capturing_logger.dart';

/// Represents the location and state of an identified speaker.
class SpeakerInfo {
  /// The bounding box of the speaker's face in screen coordinates.
  final Rect boundingBox;

  /// A confidence score indicating how likely this person is the speaker.
  final double confidence;

  SpeakerInfo({required this.boundingBox, required this.confidence});
}

/// A service for visual speaker identification using the device's camera.
///
/// Implements the API defined in `prd/06_face_detection_speaker_identification.md`.
/// This service interfaces with native code (Swift/Vision) to perform
/// real-time face detection and mouth movement analysis to identify the
/// active speaker in the camera feed.
class VisualService {
  static const _channel = MethodChannel('com.craig.livecaptions/visual');

  static final DebugCapturingLogger _logger = DebugCapturingLogger();

  final _speakerController = StreamController<SpeakerInfo?>.broadcast();
  bool _isDetecting = false;

  /// A stream of [SpeakerInfo] objects.
  ///
  /// Emits a [SpeakerInfo] object when an active speaker is identified.
  /// Emits `null` when no speaker is detected.
  Stream<SpeakerInfo?> get speakerStream => _speakerController.stream;

  VisualService() {
    _logger.i('🏗️ Initializing VisualService...');
    _logger.d('Setting up method channel handler...');
    _channel.setMethodCallHandler(_handleMethodCall);
    _logger.d('✅ VisualService initialized successfully');
  }

  /// Starts the visual speaker detection process.
  ///
  /// This will activate the camera and begin the native vision processing.
  Future<void> startDetection() async {
    if (_isDetecting) {
      _logger.w('⚠️ Visual detection already running, skipping start request');
      return;
    }

    try {
      _logger.i('👁️ Starting visual speaker detection...');
      await _channel.invokeMethod('startDetection');
      _isDetecting = true;
      _logger.i('✅ Visual speaker detection started successfully');
    } on PlatformException catch (e, stackTrace) {
      _logger.e('❌ Failed to start visual detection',
          error: e, stackTrace: stackTrace);
      rethrow;
    } catch (e, stackTrace) {
      _logger.e('❌ Unexpected error starting visual detection',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Stops the visual speaker detection process.
  ///
  /// This will release the camera and stop the native vision processing.
  Future<void> stopDetection() async {
    if (!_isDetecting) {
      _logger.w('⚠️ Visual detection not running, skipping stop request');
      return;
    }

    try {
      _logger.i('👁️ Stopping visual speaker detection...');
      await _channel.invokeMethod('stopDetection');
      _isDetecting = false;
      _logger.i('✅ Visual speaker detection stopped successfully');
    } on PlatformException catch (e, stackTrace) {
      _logger.e('❌ Failed to stop visual detection',
          error: e, stackTrace: stackTrace);
      rethrow;
    } catch (e, stackTrace) {
      _logger.e('❌ Unexpected error stopping visual detection',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    try {
      switch (call.method) {
        case 'onSpeakerUpdated':
          final data = call.arguments as Map<dynamic, dynamic>?;
          if (data != null) {
            _logger.d('👁️ Speaker detected with data: $data');
            final box = Rect.fromLTWH(
              data['x'],
              data['y'],
              data['width'],
              data['height'],
            );
            final confidence = data['confidence'] as double;
            final speakerInfo =
                SpeakerInfo(boundingBox: box, confidence: confidence);
            _speakerController.add(speakerInfo);
            _logger.d(
                '✅ Speaker info updated - confidence: ${confidence.toStringAsFixed(2)}, box: $box');
          } else {
            _logger.d('👁️ No speaker detected - clearing speaker info');
            _speakerController.add(null);
          }
          break;
        default:
          _logger.w('⚠️ Unknown method call from native: ${call.method}');
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Error handling method call: ${call.method}',
          error: e, stackTrace: stackTrace);
    }
  }

  void dispose() {
    _logger.i('🗑️ Disposing VisualService resources...');
    _speakerController.close();
    _logger.d('✅ VisualService disposed successfully');
  }
}
