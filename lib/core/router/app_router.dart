import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:live_captions_xr/app_shell.dart';
import 'package:live_captions_xr/features/home/view/home_screen.dart';
import 'package:live_captions_xr/features/sound_detection/view/sound_detection_screen.dart';
import 'package:live_captions_xr/features/localization/view/localization_screen.dart';
import 'package:live_captions_xr/features/visual_identification/view/visual_identification_screen.dart';
import 'package:live_captions_xr/features/settings/view/settings_screen.dart';
import 'package:live_captions_xr/app.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    // Bootstrap route - checks onboarding status
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const AppBootstrap();
      },
    ),

    // Shell routes with navigation
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return AppShell(child: child);
      },
      routes: <RouteBase>[
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
        GoRoute(
          path: '/about',
          builder: (BuildContext context, GoRouterState state) {
            return const AboutScreen();
          },
        ),
      ],
    ),
  ],
);

// Simple About screen placeholder
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.spatial_audio_off,
                size: 64,
                color: Colors.blue,
              ),
              SizedBox(height: 16),
              Text(
                'LiveCaptionsXR',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'AR Live Captions for Enhanced Accessibility',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
