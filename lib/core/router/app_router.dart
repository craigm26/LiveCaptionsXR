import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:live_captions_xr/app_shell.dart';
import 'package:live_captions_xr/features/home/view/home_screen.dart';
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.spatial_audio_off,
                      size: 64,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'LiveCaptionsXR',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Integrated AR Live Captions for Enhanced Accessibility',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Features Section
              const Text(
                'Integrated Features',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildFeatureCard(
                icon: Icons.hearing,
                title: 'Real-time Sound Detection',
                description: 'Advanced audio analysis identifies sounds and speech with directional awareness.',
                color: Colors.blue,
              ),
              
              _buildFeatureCard(
                icon: Icons.location_on,
                title: 'Spatial Localization',
                description: 'Precise 3D positioning of sounds using advanced sensor fusion technology.',
                color: Colors.orange,
              ),
              
              _buildFeatureCard(
                icon: Icons.visibility,
                title: 'Visual Identification',
                description: 'On-device computer vision for face detection and speaker identification.',
                color: Colors.green,
              ),
              
              _buildFeatureCard(
                icon: Icons.closed_caption,
                title: 'Live Captions',
                description: 'Real-time speech transcription with spatial positioning in AR.',
                color: Colors.purple,
              ),
              
              const SizedBox(height: 24),
              
              // How it Works Section
              const Text(
                'How It Works',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All features work together seamlessly on the main screen:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '1. Audio processing detects and localizes sounds in real-time\n'
                      '2. Visual identification recognizes speakers and objects\n'
                      '3. Speech recognition transcribes spoken content\n'
                      '4. AR overlay positions captions spatially near speakers\n'
                      '5. All information is fused for enhanced accessibility',
                      style: TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Privacy Section
              const Text(
                'Privacy & Performance',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.security, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Privacy First',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'All processing happens on-device using MediaPipe and Gemma 3n. '
                      'Your audio and visual data never leaves your device, ensuring '
                      'complete privacy while maintaining low latency performance.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: color.withAlpha((255 * 0.3).round())),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
