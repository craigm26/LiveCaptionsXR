import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'app.dart';
import 'webDev/app_web.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    runApp(const LiveCaptionsXrWebApp());
  } else {
    runApp(const live_captions_xrApp());
  }
}