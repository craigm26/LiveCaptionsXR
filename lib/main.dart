import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app.dart';
//import 'web/demo/lib/web_app.dart';
// C:\Users\CraigM\source\repos\live_captions_xr\web\demo\lib\web_app.dart
//import '../web/demo/lib/web_app.dart';
import 'core/di/service_locator.dart';
import 'demo/web_app.dart';

Widget createApp() {
  if (kIsWeb) {
    return const live_captions_xrWebApp();
  } else {
    return const live_captions_xrApp();
  }
}

void main() {
  runApp(createApp());
}