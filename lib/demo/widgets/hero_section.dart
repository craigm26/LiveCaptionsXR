import '../../../demo/web_navigation_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../navigation/web_navigation_cubit.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Container(
      height: size.height - 80, // Account for navigation bar
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).scaffoldBackgroundColor,
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 64.0),
        child: Row(
          children: [
            // Left Side - Text Content
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hackathon Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '🏆 Real-Time Closed Captioning Powered by Gemma 3n',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Main Headline
                  Text(
                    'live_captions_xr',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Subtitle
                  Text(
                    'Real-Time AI Closed Captioning for the Deaf and Hard of Hearing',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      color: Colors.grey[700],
                      height: 1.3,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Description
                  SizedBox(
                    width: size.width * 0.4,
                    child: Text(
                      'live_captions_xr delivers instant, accurate closed captions for spoken content in any environment. Powered by Gemma 3n, our AI ensures accessibility and inclusion for everyone, everywhere.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 18,
                        height: 1.6,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Action Buttons
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<WebNavigationCubit>().startDemo();
                          },
                          icon: const Icon(Icons.play_arrow, size: 20),
                          label: const Text('Try Live Demo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            context.read<WebNavigationCubit>().navigateToSection(WebSection.technology);
                          },
                          icon: const Icon(Icons.code, size: 20),
                          label: const Text('View Technology'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                            side: BorderSide(color: Theme.of(context).primaryColor),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Key Stats
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _StatCard(
                          title: '466M+',
                          subtitle: 'People with hearing loss globally',
                          icon: Icons.people,
                        ),
                        const SizedBox(width: 32),
                        _StatCard(
                          title: '<100ms',
                          subtitle: 'Real-time processing latency',
                          icon: Icons.speed,
                        ),
                        const SizedBox(width: 32),
                        _StatCard(
                          title: '140+',
                          subtitle: 'Languages supported',
                          icon: Icons.language,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Right Side - Visual Demo Preview
            Expanded(
              flex: 2,
              child: Center(
                child: Container(
                  width: 400,
                  height: 600,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      color: Colors.black,
                      child: Column(
                        children: [
                          // Phone Status Bar Simulation
                          Container(
                            height: 40,
                            color: Colors.black,
                            child: const Center(
                              child: Text(
                                'live_captions_xr Mobile',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ),
                          ),
                          // AR View Simulation
                          Expanded(
                            child: Container(
                              color: Colors.grey[900],
                              child: Stack(
                                children: [
                                  // Background "camera view"
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: RadialGradient(
                                        colors: [
                                          Colors.blue.withOpacity(0.3),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                  // AR Overlays
                                  const Positioned(
                                    top: 100,
                                    left: 50,
                                    child: _ARAnnotation(
                                      text: '🔔 Doorbell\n(85% confidence)',
                                      direction: 'Left',
                                    ),
                                  ),
                                  const Positioned(
                                    bottom: 200,
                                    right: 60,
                                    child: _ARAnnotation(
                                      text: '🍽️ Microwave\n(92% confidence)',
                                      direction: 'Center',
                                    ),
                                  ),
                                  const Positioned(
                                    top: 250,
                                    right: 40,
                                    child: _ARAnnotation(
                                      text: '👥 Person speaking\n(88% confidence)',
                                      direction: 'Right',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _ARAnnotation extends StatelessWidget {
  final String text;
  final String direction;

  const _ARAnnotation({
    required this.text,
    required this.direction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              direction,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}