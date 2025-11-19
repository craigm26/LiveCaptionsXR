import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

import '../models/native_engine_event.dart';
import 'app_logger.dart';

class NativeCaptionEngineBridge {
  NativeCaptionEngineBridge(
      {MethodChannel? controlChannel, EventChannel? eventChannel})
      : _controlChannel =
            controlChannel ?? const MethodChannel(_controlChannelName),
        _eventChannel = eventChannel ?? const EventChannel(_eventChannelName);

  static const _controlChannelName = 'live_captions_xr/engine_control';
  static const _eventChannelName = 'live_captions_xr/engine_events';

  final MethodChannel _controlChannel;
  final EventChannel _eventChannel;
  final AppLogger _logger = AppLogger.instance;

  Stream<NativeEngineEvent>? _cachedStream;
  bool _running = false;

  bool get isSupported => !kIsWeb && Platform.isAndroid;

  Future<void> ensureStarted() async {
    if (!isSupported) {
      _logger.w('Native engine bridge ignored: unsupported platform',
          category: LogCategory.system);
      return;
    }
    if (_running) return;

    try {
      await _controlChannel.invokeMethod('startEngine');
      _running = true;
      _logger.i('Native caption engine requested to start',
          category: LogCategory.system);
    } on PlatformException catch (e) {
      _logger.e('Failed to start native engine',
          category: LogCategory.system, error: e);
      rethrow;
    }
  }

  Future<void> stop() async {
    if (!isSupported || !_running) return;
    try {
      await _controlChannel.invokeMethod('stopEngine');
      _logger.i('Native caption engine stop requested',
          category: LogCategory.system);
    } on PlatformException catch (e) {
      _logger.e('Failed to stop native engine',
          category: LogCategory.system, error: e);
    } finally {
      _running = false;
    }
  }

  Stream<NativeEngineEvent> get events {
    if (!isSupported) {
      return const Stream<NativeEngineEvent>.empty();
    }
    return _cachedStream ??= _eventChannel
        .receiveBroadcastStream()
        .where((event) => event is Map)
        .map((event) =>
            NativeEngineEvent.fromMap(event as Map<dynamic, dynamic>))
        .handleError((error, stackTrace) {
      _logger.e('Error receiving native engine events',
          category: LogCategory.system, error: error, stackTrace: stackTrace);
    }).asBroadcastStream();
  }
}
