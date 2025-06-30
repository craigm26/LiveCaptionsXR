import 'dart:typed_data';

import 'package:flutter/services.dart';

class ARAnchorManager {
  static const _channel = MethodChannel('com.craig.livecaptions/visual');

  Future<void> createAnchorFromAngle(double angle, double distance, String text) async {
    try {
      await _channel.invokeMethod('createAnchorFromAngle', {
        'angle': angle,
        'distance': distance,
        'text': text,
      });
    } on PlatformException catch (e) {
      // Handle the exception
    }
  }

  Future<void> createAnchorFromTransform(Float32List transform, String text) async {
    try {
      await _channel.invokeMethod('createAnchorFromTransform', {
        'transform': transform,
        'text': text,
      });
    } on PlatformException catch (e) {
      // Handle the exception
    }
  }
}
