import 'package:flutter/material.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 64),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).scaffoldBackgroundColor,
            Theme.of(context).primaryColor.withAlpha((255 * 0.05).round()),
          ],
        ),
      ),
      child: Column(
        children: [
          // Section Header
          Text(
            'About Live Captions XR',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 16),

          Text(
            'Transforming accessibility through multimodal AI',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
          ),

          const SizedBox(height: 64),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Side - Project Info
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'The Vision',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Live Captions XR represents the first practical application of Google Gemma 3n\'s revolutionary multimodal capabilities for accessibility technology. By processing audio, visual, and contextual information simultaneously, we\'re creating experiences that truly understand and adapt to user needs.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                            color: Colors.grey[700],
                          ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Impact Goals',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        _ImpactItem(
                          icon: Icons.people,
                          title: '466 Million People',
                          description:
                              'Worldwide with disabling hearing loss who could benefit',
                        ),
                        _ImpactItem(
                          icon: Icons.security,
                          title: 'Privacy-First Design',
                          description:
                              'Complete on-device processing ensures data never leaves your phone',
                        ),
                        _ImpactItem(
                          icon: Icons.accessibility,
                          title: 'Universal Access',
                          description:
                              'Designed with and for the D/HH community from day one',
                        ),
                        _ImpactItem(
                          icon: Icons.language,
                          title: 'Global Reach',
                          description:
                              'Supporting 140+ languages for worldwide accessibility',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 64),

              // Right Side - Hackathon Info & Links
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hackathon Badge
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context)
                                .primaryColor
                                .withAlpha((255 * 0.8).round()),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.emoji_events,
                            color: Colors.white,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Google Gemma 3n\nHackathon',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Showcasing the potential of multimodal AI for accessibility innovation',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Technical Details
                    _InfoCard(
                      title: 'Technical Implementation',
                      items: [
                        'Flutter cross-platform development',
                        'Gemma 3n multimodal integration',
                        'Google MediaPipe for mobile inference',
                        'ARKit/ARCore spatial computing',
                        'Real-time audio processing (TDOA)',
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Resources
                    _InfoCard(
                      title: 'Resources & Documentation',
                      items: [
                        'GitHub Repository',
                        'Technical Architecture',
                        'API Documentation',
                        'Accessibility Testing Results',
                        'Community Feedback',
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Call to Action
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.grey.withAlpha((255 * 0.3).round())),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Ready to Experience the Future?',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'This demo showcases production-ready accessibility technology that could transform millions of lives.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              // Scroll back to demo section
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 44),
                            ),
                            child: const Text('Try the Demo Again'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 64),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                    color: Colors.grey.withAlpha((255 * 0.3).round())),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '© 2025 Live Captions XR • ',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Built for Google Gemma 3n Hackathon',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  ' • Making technology accessible for all',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _ImpactItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  Theme.of(context).primaryColor.withAlpha((255 * 0.1).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<String> items;

  const _InfoCard({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withAlpha((255 * 0.2).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
