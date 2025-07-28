import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/nav_bar.dart';
import '../../utils/testflight_utils.dart';
import '../../utils/responsive_utils.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return Scaffold(
      appBar: const NavBar(),

      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeroSection(context, isMobile),

              // Coming Soon Section
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 24.0, horizontal: 16.0),
                child: Card(
                  color: Colors.blue[50],
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.android,
                                color: Colors.green[700], size: 32),
                            SizedBox(width: 12),
                            Icon(Icons.vrpano,
                                color: Colors.deepPurple, size: 32),
                            SizedBox(width: 12),
                            Icon(Icons.phone_iphone,
                                color: Colors.grey[800], size: 32),
                          ],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Coming Soon: Android & Android XR Support!',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[900],
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Live Captions XR is designed for the next generation of accessibility—optimized for Android XR headsets, but also fully compatible with Android and iOS devices. Stay tuned for our upcoming Android and XR releases! ',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.blueGrey[800],
                                    fontSize: 16,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _buildMissionSection(context, isMobile),
              _buildFounderSection(context, isMobile),
              _buildProjectSection(context, isMobile),
              _buildContributeSection(context, isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 48.0,
        vertical: isMobile ? 48.0 : 80.0,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
            Colors.purple.withValues(alpha: 0.05),
            Colors.white,
          ],
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            size: isMobile ? 64 : 80,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            'About Live Captions XR',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            constraints:
                BoxConstraints(maxWidth: isMobile ? double.infinity : 700),
            child: Text(
              'Democratizing accessibility through open-source innovation and community-driven development.',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionSection(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 48.0,
        vertical: isMobile ? 48.0 : 64.0,
      ),
      child: Column(
        children: [
          Text(
            'Our Mission',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Text(
              'Live Captions XR was born from a simple belief: everyone deserves equal access to communication and information. Our mission is to break down barriers for the deaf and hard-of-hearing community by providing real-time, accurate, and contextually-aware closed captions through cutting-edge AI technology.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[700],
                    height: 1.6,
                    fontSize: 18,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 32,
            runSpacing: 32,
            alignment: WrapAlignment.center,
            children: [
              _buildMissionItem(
                context,
                Icons.accessibility_new,
                'Accessibility First',
                'Designed by and for the deaf community',
              ),
              _buildMissionItem(
                context,
                Icons.code,
                'Open Source',
                'Transparent, collaborative development',
              ),
              _buildMissionItem(
                context,
                Icons.privacy_tip,
                'Privacy Focused',
                'On-device processing protects your data',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMissionItem(
      BuildContext context, IconData icon, String title, String description) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 250),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 32,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFounderSection(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 48.0,
        vertical: isMobile ? 48.0 : 64.0,
      ),
      color: Colors.grey[50],
      child: Column(
        children: [
          Text(
            'Meet the Founder',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor:
                      Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Craig Merry',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Founder & Lead Developer',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  'Craig is a mostly deaf individual who understands firsthand the challenges faced by the deaf and hard-of-hearing community. With a background in software development and AI, Craig founded Live Captions XR to bridge the accessibility gap using innovative technology. His personal experience drives the project\'s commitment to creating truly inclusive solutions.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[700],
                        height: 1.6,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        await TestFlightUtils.openWebsite();
                      },
                      icon: const Icon(Icons.code),
                      label: const Text('GitHub Profile'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/support'),
                      icon: const Icon(Icons.email),
                      label: const Text('Contact'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectSection(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 48.0,
        vertical: isMobile ? 48.0 : 64.0,
      ),
      child: Column(
        children: [
          Text(
            'Open Source Project',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Text(
              'Live Captions XR is built in the open with transparency and community collaboration at its core. Every line of code, every decision, and every improvement is shared with the community.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[700],
                    height: 1.6,
                    fontSize: 18,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isMobile ? 1 : 2,
            childAspectRatio: isMobile ? 3 : 2.5,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            children: [
              _buildProjectCard(
                context,
                Icons.code,
                'MIT Licensed',
                'Free and open source software that anyone can use, modify, and distribute.',
              ),
              _buildProjectCard(
                context,
                Icons.group,
                'Community Driven',
                'Built by developers, accessibility advocates, and community members worldwide.',
              ),
              _buildProjectCard(
                context,
                Icons.bug_report,
                'Transparent Development',
                'All bugs, features, and discussions are tracked publicly on GitHub.',
              ),
              _buildProjectCard(
                context,
                Icons.volunteer_activism,
                'Contributing Welcome',
                'We welcome contributions from developers, designers, testers, and accessibility experts.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(
      BuildContext context, IconData icon, String title, String description) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContributeSection(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 48.0,
        vertical: isMobile ? 48.0 : 64.0,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.05),
            Colors.blue.withValues(alpha: 0.03),
          ],
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.favorite,
            size: 48,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            'Join Our Community',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text(
              'Help us build a more accessible world. Whether you\'re a developer, designer, tester, or accessibility advocate, there\'s a place for you in our community.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () async {
                  await TestFlightUtils.openWebsite();
                },
                icon: const Icon(Icons.code),
                label: const Text('Contribute on GitHub'),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/support'),
                icon: const Icon(Icons.support),
                label: const Text('Get Support'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
