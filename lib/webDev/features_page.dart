import 'package:flutter/material.dart';
import 'nav_bar.dart';

class FeaturesPage extends StatelessWidget {
  const FeaturesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final features = [
      {
        'icon': Icons.hearing,
        'title': 'Sound Detection',
        'desc': 'Real-time audio analysis identifying sounds and speech with directional awareness.'
      },
      {
        'icon': Icons.visibility,
        'title': 'Visual Recognition',
        'desc': 'On-device computer vision for face detection and speaker identification.'
      },
      {
        'icon': Icons.navigation,
        'title': 'Spatial Localization',
        'desc': 'Precise 3D positioning of sounds using advanced sensor fusion.'
      },
      {
        'icon': Icons.psychology,
        'title': 'Contextual AI',
        'desc': 'Intelligent context understanding and multimodal data fusion.'
      },
      {
        'icon': Icons.vibration,
        'title': 'Haptic Feedback',
        'desc': 'Rich tactile responses synchronized with visual and audio cues.'
      },
      {
        'icon': Icons.language,
        'title': 'Multilingual ASR',
        'desc': 'Streaming Automatic Speech Recognition for 100+ languages.'
      },
    ];
    final String location = ModalRoute.of(context)?.settings.name ?? '/features';
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Scaffold(
      appBar: const NavBar(),
      endDrawer: isMobile ? NavDrawer(location: location) : null,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Core Features',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 40,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Real-time multimodal AI processing for comprehensive accessibility.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 20,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth > 900
                      ? 3
                      : constraints.maxWidth > 600
                          ? 2
                          : 1;
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 32,
                    mainAxisSpacing: 32,
                    childAspectRatio: 1.2,
                    children: features.map((feature) {
                      return _FeatureCard(
                        icon: feature['icon'] as IconData,
                        title: feature['title'] as String,
                        description: feature['desc'] as String,
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  const _FeatureCard({required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).primaryColor),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 