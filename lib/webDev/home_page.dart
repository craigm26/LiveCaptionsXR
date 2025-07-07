import 'package:flutter/material.dart';
import 'nav_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final String location = ModalRoute.of(context)?.settings.name ?? '/';
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
              // App logo or icon
              Image.asset(
                'assets/logos/logo.png',
                height: 120,
                width: 120,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 24),
              Text(
                'Live Captions XR',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  fontSize: 56,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                'Real-Time AI Closed Captioning for the Deaf and Hard of Hearing',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w400,
                  fontSize: 28,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Text(
                'LiveCaptionsXR delivers instant, accurate closed captions for spoken content in any environment. Powered by on-device AI for privacy and performance.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[700],
                  fontSize: 20,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              OutlinedButton.icon(
                onPressed: () {
                  // Navigate to the features page
                  Navigator.pushNamed(context, '/features');
                },
                icon: const Icon(Icons.featured_play_list),
                label: const Text('Explore Features'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  // Navigate to the technology page
                  Navigator.pushNamed(context, '/technology');
                },
                icon: const Icon(Icons.code),
                label: const Text('View Technology'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
} 