import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:live_captions_xr/features/home/view/home_screen.dart';
import 'package:live_captions_xr/features/sound_detection/view/sound_detection_screen.dart';
import 'package:live_captions_xr/features/localization/view/localization_screen.dart';
import 'package:live_captions_xr/features/visual_identification/view/visual_identification_screen.dart';
import 'package:live_captions_xr/features/settings/view/settings_screen.dart';
import 'package:live_captions_xr/webDev/demo/web_demo_screen.dart';

final GoRouter router = GoRouter(
  routes: <GoRoute>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const WebDemoScreen();
      },
    ),
    GoRoute(
      path: '/home',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
    ),
    GoRoute(
      path: '/sound',
      builder: (BuildContext context, GoRouterState state) {
        return const SoundDetectionScreen();
      },
    ),
    GoRoute(
      path: '/localization',
      builder: (BuildContext context, GoRouterState state) {
        return const LocalizationScreen();
      },
    ),
    GoRoute(
      path: '/visual',
      builder: (BuildContext context, GoRouterState state) {
        return const VisualIdentificationScreen();
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (BuildContext context, GoRouterState state) {
        return const SettingsScreen();
      },
    ),
  ],
);
