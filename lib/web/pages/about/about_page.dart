import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:live_captions_xr/core/utils/interaction_handler.dart';
import 'package:url_launcher/url_launcher.dart';
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
    final screenSize = ResponsiveUtils.getScreenSize(context);
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return Scaffold(
      appBar: const NavBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeroSection(context, screenSize),
              _buildMissionSection(context, screenSize),
              _buildFounderSection(context, screenSize),
              _buildProjectSection(context, screenSize),
              _buildContributeSection(context, screenSize),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getHorizontalPadding(context),
        vertical: isMobile ? 40.0 : isTablet ? 48.0 : 64.0,
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
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.info_outline,
              size: isMobile ? 48 : isTablet ? 56 : 64,
              color: Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(width: isMobile ? 16 : 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About Live Captions XR',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                        fontSize: isMobile ? 28 : isTablet ? 32 : 36,
                      ),
                ),
                SizedBox(height: isMobile ? 6 : 8),
                Text(
                  'Democratizing accessibility through open-source innovation and community-driven development.',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                        fontSize: isMobile ? 16 : isTablet ? 18 : 20,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionSection(BuildContext context, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getHorizontalPadding(context),
        vertical: isMobile ? 32.0 : isTablet ? 40.0 : 48.0,
      ),
      child: Column(
        children: [
          Text(
            'Our Mission',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  fontSize: isMobile ? 24 : isTablet ? 28 : 32,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 16 : 20),
          Container(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : isTablet ? 700 : 800,
            ),
            child: Text(
              'Live Captions XR was born from a simple belief: everyone deserves equal access to communication and information. Our mission is to break down barriers for the deaf and hard-of-hearing community by providing real-time, accurate, and contextually-aware closed captions through cutting-edge AI technology.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[700],
                    height: 1.5,
                    fontSize: isMobile ? 16 : isTablet ? 18 : 20,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: isMobile ? 24 : 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 1 : isTablet ? 2 : 3,
              childAspectRatio: isMobile ? 2.5 : isTablet ? 3.0 : 3.5,
              mainAxisSpacing: isMobile ? 12 : 16,
              crossAxisSpacing: isMobile ? 12 : 16,
            ),
            itemCount: 3,
            itemBuilder: (context, index) {
              final missions = [
                {'icon': Icons.accessibility_new, 'title': 'Accessibility First', 'description': 'Designed by and for the deaf community'},
                {'icon': Icons.code, 'title': 'Open Source', 'description': 'Transparent, collaborative development'},
                {'icon': Icons.privacy_tip, 'title': 'Privacy Focused', 'description': 'On-device processing protects your data'},
              ];
              final mission = missions[index];
              return _buildMissionItem(context, mission['icon'] as IconData, mission['title'] as String, mission['description'] as String, screenSize);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMissionItem(BuildContext context, IconData icon, String title, String description, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: isMobile ? 24 : 28,
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: isMobile ? 8 : 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 14 : 16,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 4 : 6),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: isMobile ? 12 : 13,
                  ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFounderSection(BuildContext context, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getHorizontalPadding(context),
        vertical: isMobile ? 32.0 : isTablet ? 40.0 : 48.0,
      ),
      color: Colors.grey[50],
      child: Column(
        children: [
          Text(
            'Meet the Founders',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  fontSize: isMobile ? 24 : isTablet ? 28 : 32,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 24 : 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 1 : 2,
              childAspectRatio: isMobile ? 2.2 : 2.8,
              mainAxisSpacing: isMobile ? 12 : 16,
              crossAxisSpacing: isMobile ? 12 : 16,
            ),
            itemCount: 2,
            itemBuilder: (context, index) {
              final founders = [
                {
                  'name': 'Craig Merry',
                  'title': 'Founder & Lead Developer',
                  'bio': 'Craig is a mostly deaf individual who understands firsthand the challenges faced by the deaf and hard-of-hearing community. With a background in software development and AI, Craig founded Live Captions XR to bridge the accessibility gap using innovative technology. His personal experience drives the project\'s commitment to creating truly inclusive solutions.',
                  'buttons': [
                    OutlinedButton.icon(
                      onPressed: () async {
                        await InteractionHandler.safeAsyncExecution(
                          action: () async {
                            await launchUrl(Uri.parse('https://www.linkedin.com/in/craigmerry/'));
                          },
                          timeout: const Duration(seconds: 5),
                        );
                      },
                      icon: const Icon(Icons.code),
                      label: Text(isMobile ? 'LinkedIn' : 'LinkedIn Profile'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 20,
                          vertical: isMobile ? 8 : 10,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await InteractionHandler.safeAsyncExecution(
                          action: () async {
                            await launchUrl(Uri.parse('mailto:craig@craigmerry.com'));
                          },
                          timeout: const Duration(seconds: 5),
                        );
                      },
                      icon: const Icon(Icons.email),
                      label: const Text('Contact'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 20,
                          vertical: isMobile ? 8 : 10,
                        ),
                      ),
                    ),
                  ],
                },
                {
                  'name': 'Sasha Denisov',
                  'title': 'Co-Founder & Technical Lead',
                  'bio': 'Chief Software Engineer and Head of Flutter Competency with 12+ years in designing scalable, maintainable systems. Google Developer Expert for AI, Flutter and Firebase. Creator of flutter_gemma, the on-device AI package powering Live Captions XR\'s speech recognition capabilities. Specializes in end-to-end architecture and AI integration.',
                  'buttons': [
                    OutlinedButton.icon(
                      onPressed: () async {
                        await InteractionHandler.safeAsyncExecution(
                          action: () async {
                            await launchUrl(Uri.parse('https://www.linkedin.com/in/aleks-denisov/'));
                          },
                          timeout: const Duration(seconds: 5),
                        );
                      },
                      icon: const Icon(Icons.code),
                      label: Text(isMobile ? 'LinkedIn' : 'LinkedIn Profile'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 20,
                          vertical: isMobile ? 8 : 10,
                        ),
                      ),
                    ),
                  ],
                },
              ];
              final founder = founders[index];
              return _buildFounderCard(
                context,
                founder['name'] as String,
                founder['title'] as String,
                founder['bio'] as String,
                founder['buttons'] as List<Widget>,
                screenSize,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFounderCard(BuildContext context, String name, String title, String bio, List<Widget> buttons, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          children: [
            CircleAvatar(
              radius: isMobile ? 40 : isTablet ? 45 : 50,
              backgroundColor: Colors.grey[200],
              backgroundImage: name == 'Craig Merry' 
                  ? const AssetImage('assets/images/CraigMerry.jpg')
                  : name == 'Sasha Denisov'
                      ? const AssetImage('assets/images/SashaProfilePicture.jpg')
                      : null,
              child: name == 'Craig Merry' || name == 'Sasha Denisov'
                  ? null
                  : Icon(
                      Icons.person,
                      size: isMobile ? 40 : isTablet ? 45 : 50,
                      color: Theme.of(context).primaryColor,
                    ),
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                    fontSize: isMobile ? 18 : 20,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 4 : 6),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: isMobile ? 14 : 16,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Expanded(
              child: Text(
                bio,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                      height: 1.4,
                      fontSize: isMobile ? 13 : 14,
                    ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: isMobile ? 6 : 8,
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Wrap(
              spacing: isMobile ? 8 : 12,
              runSpacing: isMobile ? 8 : 12,
              alignment: WrapAlignment.center,
              children: buttons,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectSection(BuildContext context, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getHorizontalPadding(context),
        vertical: isMobile ? 32.0 : isTablet ? 40.0 : 48.0,
      ),
      child: Column(
        children: [
          Text(
            'Open Source Project',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  fontSize: isMobile ? 24 : isTablet ? 28 : 32,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 16 : 20),
          Container(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : isTablet ? 700 : 800,
            ),
            child: Text(
              'Live Captions XR is built in the open with transparency and community collaboration at its core. Every line of code, every decision, and every improvement is shared with the community.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[700],
                    height: 1.5,
                    fontSize: isMobile ? 16 : isTablet ? 18 : 20,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: isMobile ? 24 : 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 1 : isTablet ? 2 : 2,
              childAspectRatio: isMobile ? 2.8 : isTablet ? 3.2 : 3.5,
              mainAxisSpacing: isMobile ? 12 : 16,
              crossAxisSpacing: isMobile ? 12 : 16,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              final projects = [
                {'icon': Icons.code, 'title': 'MIT Licensed', 'description': 'Free and open source software that anyone can use, modify, and distribute.'},
                {'icon': Icons.group, 'title': 'Community Driven', 'description': 'Built by developers, accessibility advocates, and community members worldwide.'},
                {'icon': Icons.bug_report, 'title': 'Transparent Development', 'description': 'All bugs, features, and discussions are tracked publicly on GitHub.'},
                {'icon': Icons.volunteer_activism, 'title': 'Contributing Welcome', 'description': 'We welcome contributions from developers, designers, testers, and accessibility experts.'},
              ];
              final project = projects[index];
              return _buildProjectCard(context, project['icon'] as IconData, project['title'] as String, project['description'] as String, screenSize);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, IconData icon, String title, String description, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 10 : 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: isMobile ? 24 : 28,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                SizedBox(width: isMobile ? 12 : 16),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 16 : 18,
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 8 : 12),
            Expanded(
              child: Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      fontSize: isMobile ? 13 : 14,
                    ),
                overflow: TextOverflow.ellipsis,
                maxLines: isMobile ? 3 : 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContributeSection(BuildContext context, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getHorizontalPadding(context),
        vertical: isMobile ? 32.0 : isTablet ? 40.0 : 48.0,
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
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.favorite,
              size: isMobile ? 32 : 36,
              color: Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            'Join Our Community',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  fontSize: isMobile ? 24 : isTablet ? 28 : 32,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Container(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : isTablet ? 700 : 800,
            ),
            child: Text(
              'Help us build a more accessible world. Whether you\'re a developer, designer, tester, or accessibility advocate, there\'s a place for you in our community.',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                    height: 1.4,
                    fontSize: isMobile ? 16 : isTablet ? 18 : 20,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: isMobile ? 20 : 24),
          Wrap(
            spacing: isMobile ? 8 : 12,
            runSpacing: isMobile ? 8 : 12,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () async {
                  await InteractionHandler.safeAsyncExecution(
                    action: () async {
                      await launchUrl(Uri.parse('https://github.com/craigm26/livecaptionsxr'));
                    },
                    timeout: const Duration(seconds: 5),
                  );
                },
                icon: const Icon(Icons.code),
                label: Text(isMobile ? 'GitHub' : 'Contribute on GitHub'),
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 20,
                    vertical: isMobile ? 10 : 12,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  await InteractionHandler.safeAsyncExecution(
                    action: () async {
                      await launchUrl(Uri.parse('https://github.com/craigm26/livecaptionsxr'));
                    },
                    timeout: const Duration(seconds: 5),
                  );
                },
                icon: const Icon(Icons.support),
                label: Text(isMobile ? 'Support' : 'Get Support'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 20,
                    vertical: isMobile ? 10 : 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
