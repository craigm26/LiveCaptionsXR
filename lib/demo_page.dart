import 'package:flutter/material.dart';
import 'nav_bar.dart';

class DemoPage extends StatelessWidget {
  const DemoPage({super.key});
  @override
  Widget build(BuildContext context) {
    final String location = ModalRoute.of(context)?.settings.name ?? '/demo';
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Scaffold(
      appBar: const NavBar(),
      endDrawer: isMobile ? NavDrawer(location: location) : null,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.play_circle_fill, size: 64, color: Theme.of(context).primaryColor),
              const SizedBox(height: 24),
              Text(
                'Live Demo',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 40,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Experience LiveCaptionsXR in action! This interactive demo will showcase real-time closed captioning and multimodal AI features.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 20,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Container(
                width: 400,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Center(
                  child: Text(
                    'Demo coming soon...\n(Here you will see live captions and AI features in action!)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.play_arrow),
                label: const Text('Try Demo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 