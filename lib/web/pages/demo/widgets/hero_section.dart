import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:live_captions_xr/web/pages/demo/cubit/web_navigation_cubit.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

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
            Theme.of(context).primaryColor.withAlpha((255 * 0.1).round()),
            Theme.of(context).scaffoldBackgroundColor,
            Theme.of(context).primaryColor.withAlpha((255 * 0.05).round()),
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
                      color: Theme.of(context)
                          .primaryColor
                          .withAlpha((255 * 0.1).round()),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context)
                            .primaryColor
                            .withAlpha((255 * 0.3).round()),
                      ),
                    ),
                    child: Text(
                      'Real-Time Closed Captioning Powered by Gemma 3n',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Main Headline
                  Text(
                    'Live Captions XR',
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
                      "Live Captions XR delivers instant, accurate closed captions for spoken content in any environment. Powered by Gemma 3n and Google's MediaPipe for high-performance, on-device AI.",
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
                        OutlinedButton.icon(
                          onPressed: () {
                            context
                                .read<WebNavigationCubit>()
                                .navigateToSection(WebSection.technology);
                          },
                          icon: const Icon(Icons.code, size: 20),
                          label: const Text('View Technology'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                            side: BorderSide(
                                color: Theme.of(context).primaryColor),
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
                  const SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _StatCard(
                          title: '466M+',
                          subtitle: 'People with hearing loss globally',
                          icon: Icons.people,
                        ),
                        SizedBox(width: 32),
                        _StatCard(
                          title: '<100ms',
                          subtitle: 'Real-time processing latency',
                          icon: Icons.speed,
                        ),
                        SizedBox(width: 32),
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
