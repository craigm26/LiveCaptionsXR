import 'package:flutter/material.dart';
import 'nav_bar.dart';

class TechnologyPage extends StatelessWidget {
  const TechnologyPage({super.key});
  @override
  Widget build(BuildContext context) {
    final techStack = [
      {
        'icon': Icons.flutter_dash,
        'name': 'Flutter',
        'desc': 'Cross-platform UI framework for fast, expressive apps.'
      },
      {
        'icon': Icons.code,
        'name': 'Dart',
        'desc': 'High-performance language for modern app development.'
      },
      {
        'icon': Icons.psychology,
        'name': 'Gemma 3n',
        'desc': 'Multimodal AI model for real-time captioning and context.'
      },
      {
        'icon': Icons.memory,
        'name': 'Google MediaPipe',
        'desc': 'On-device inference engine for audio and vision.'
      },
      {
        'icon': Icons.sensors,
        'name': 'TDOA & Kalman Filter',
        'desc': 'Advanced localization and sensor fusion.'
      },
      {
        'icon': Icons.devices,
        'name': 'ARKit / ARCore',
        'desc': 'Augmented reality frameworks for iOS and Android.'
      },
    ];
    final String location = ModalRoute.of(context)?.settings.name ?? '/technology';
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Scaffold(
      appBar: const NavBar(),
      endDrawer: isMobile ? NavDrawer(location: location) : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Technology Stack',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 40,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Powered by Google Gemma 3n and cutting-edge mobile AI.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 20,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Wrap(
              spacing: 32,
              runSpacing: 32,
              alignment: WrapAlignment.center,
              children: techStack.map((tech) {
                return _TechCard(
                  icon: tech['icon'] as IconData,
                  name: tech['name'] as String,
                  description: tech['desc'] as String,
                );
              }).toList(),
            ),
            const SizedBox(height: 56),
            Text(
              'System Architecture',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              width: 600,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: const [
                  Text(
                    'Input Layer  →  Processing Layer  →  Output Layer',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Camera, Microphone, Sensors  →  Gemma 3n, MediaPipe, Kalman Filter  →  AR Overlay, Haptic Feedback',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '(Architecture diagram coming soon)',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
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

class _TechCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final String description;
  const _TechCard({required this.icon, required this.name, required this.description});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).primaryColor),
            const SizedBox(height: 14),
            Text(
              name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 