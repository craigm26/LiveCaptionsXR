import 'package:flutter/material.dart';
import '../shared/theme/app_theme.dart';
import 'web_router.dart';

/// Root widget for the Flutter web build.
class LiveCaptionsXrWebApp extends StatelessWidget {
  const LiveCaptionsXrWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LiveCaptionsXR Web',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: webRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
