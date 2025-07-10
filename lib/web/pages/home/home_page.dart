import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/nav_bar.dart';
import '../../utils/testflight_utils.dart';
import '../../config/web_performance_config.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Use optimized animation durations from performance config
    _fadeController = AnimationController(
      duration: WebPerformanceConfig.normalAnimationDuration,
      vsync: this,
    );
    _slideController = AnimationController(
      duration: WebPerformanceConfig.slowAnimationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    // Start animations simultaneously for better performance
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).location;
    final isMobile = MediaQuery.of(context).size.width < 700;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: const NavBar(),
      endDrawer: isMobile ? NavDrawer(location: location) : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            _buildHeroSection(context, isMobile, screenWidth),

            // Coming Soon Section
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Live Captions XR is designed for the next generation of accessibility—optimized for Android XR headsets, but also fully compatible with Android and iOS devices. Stay tuned for our upcoming Android and XR releases!',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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

            // Features Preview Section
            _buildFeaturesPreview(context, isMobile),

            // Stats Section
            _buildStatsSection(context, isMobile),

            // TestFlight Section
            _buildTestFlightSection(context, isMobile),

            // CTA Section
            _buildCtaSection(context, isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(
      BuildContext context, bool isMobile, double screenWidth) {
    return Container(
      height: isMobile ? MediaQuery.of(context).size.height * 0.9 : 700,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
            Colors.white,
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24.0 : 48.0,
          vertical: isMobile ? 32.0 : 64.0,
        ),
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo with pulse animation
                TweenAnimationBuilder<double>(
                  duration: const Duration(seconds: 2),
                  tween: Tween(begin: 0.8, end: 1.0),
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.asset(
                            'assets/logos/logo.png',
                            height: isMobile ? 100 : 150,
                            width: isMobile ? 100 : 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: isMobile ? 32 : 48),

                // Main title with gradient
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'Live Captions XR',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 48 : 72,
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: isMobile ? 16 : 24),

                // Subtitle
                Text(
                  'Real-Time AI Closed Captioning for the Deaf and Hard of Hearing',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w400,
                        fontSize: isMobile ? 20 : 32,
                        height: 1.3,
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isMobile ? 24 : 32),

                // Description
                Container(
                  constraints: BoxConstraints(
                      maxWidth: isMobile ? screenWidth * 0.9 : 800),
                  child: Text(
                    'Live Captions XR delivers instant, accurate closed captions for spoken content in any environment. Powered by on-device AI for privacy and performance.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[700],
                          fontSize: isMobile ? 16 : 22,
                          height: 1.6,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: isMobile ? 32 : 48),

                // CTA Buttons
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildAnimatedButton(
                      context,
                      onPressed: () async {
                        try {
                          await TestFlightUtils.openTestFlight();
                        } catch (e) {
                          // Handle error gracefully without blocking UI
                          debugPrint('Could not open TestFlight: $e');
                        }
                      },
                      icon: Icons.apple,
                      label: 'Download on TestFlight',
                      isPrimary: true,
                    ),
                    _buildAnimatedButton(
                      context,
                      onPressed: () => context.go('/features'),
                      icon: Icons.featured_play_list,
                      label: 'Explore Features',
                      isPrimary: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedButton(
    BuildContext context, {
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween(begin: 1.0, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: isPrimary
              ? ElevatedButton.icon(
                  onPressed: onPressed,
                  icon: Icon(icon),
                  label: Text(label),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                )
              : OutlinedButton.icon(
                  onPressed: onPressed,
                  icon: Icon(icon),
                  label: Text(label),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildFeaturesPreview(BuildContext context, bool isMobile) {
    final features = [
      {
        'icon': Icons.hearing,
        'title': 'Real-Time Audio',
        'desc': 'Instant speech recognition with directional awareness',
        'color': Colors.blue,
      },
      {
        'icon': Icons.visibility,
        'title': 'Visual Recognition',
        'desc': 'Face detection and speaker identification',
        'color': Colors.green,
      },
      {
        'icon': Icons.psychology,
        'title': 'AI Powered',
        'desc': 'Gemma 3n multimodal AI for context understanding',
        'color': Colors.purple,
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 48.0,
        vertical: isMobile ? 48.0 : 80.0,
      ),
      child: Column(
        children: [
          Text(
            'Key Features',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: features
                .map((feature) => _buildFeatureCard(context, feature, isMobile))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
      BuildContext context, Map<String, dynamic> feature, bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (feature['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              feature['icon'] as IconData,
              size: 32,
              color: feature['color'] as Color,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            feature['title'] as String,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            feature['desc'] as String,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, bool isMobile) {
    final stats = [
      {'value': '99.5%', 'label': 'Accuracy'},
      {'value': '<50ms', 'label': 'Latency'},
      {'value': '100+', 'label': 'Languages'},
      {'value': '24/7', 'label': 'Available'},
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 48.0,
        vertical: isMobile ? 48.0 : 64.0,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.05),
            Theme.of(context).primaryColor.withOpacity(0.1),
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            'Performance Metrics',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 32,
            runSpacing: 32,
            children:
                stats.map((stat) => _buildStatItem(context, stat)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, Map<String, String> stat) {
    return Column(
      children: [
        Text(
          stat['value']!,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          stat['label']!,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildCtaSection(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 48.0,
        vertical: isMobile ? 48.0 : 80.0,
      ),
      child: Column(
        children: [
          Text(
            'Ready to Experience the Future?',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            'Join the accessibility revolution with Live Captions XR',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildAnimatedButton(
                context,
                onPressed: () async {
                  try {
                    await TestFlightUtils.openTestFlight();
                  } catch (e) {
                    debugPrint('Could not open TestFlight: $e');
                  }
                },
                icon: Icons.apple,
                label: 'Download TestFlight',
                isPrimary: true,
              ),
              _buildAnimatedButton(
                context,
                onPressed: () => context.go('/technology'),
                icon: Icons.code,
                label: 'View Technology',
                isPrimary: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestFlightSection(BuildContext context, bool isMobile) {
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
            Theme.of(context).primaryColor.withOpacity(0.03),
            Colors.blue.withOpacity(0.02),
            Colors.white,
          ],
        ),
      ),
      child: Column(
        children: [
          // iOS App Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.apple,
              size: 64,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Available on iOS',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          Container(
            constraints:
                BoxConstraints(maxWidth: isMobile ? double.infinity : 600),
            child: Text(
              'Join our TestFlight beta program to get early access to Live Captions XR and help us improve the experience for everyone.',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),

          // TestFlight Features
          Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Wrap(
              spacing: 32,
              runSpacing: 24,
              alignment: WrapAlignment.center,
              children: [
                _buildTestFlightFeature(
                  context,
                  Icons.science,
                  'Early Access',
                  'Get the latest features before public release',
                ),
                _buildTestFlightFeature(
                  context,
                  Icons.feedback,
                  'Direct Feedback',
                  'Help shape the future of the app',
                ),
                _buildTestFlightFeature(
                  context,
                  Icons.security,
                  'Secure Testing',
                  'Safe and secure beta testing environment',
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),

          // Download Button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  await TestFlightUtils.openTestFlight();
                } catch (e) {
                  debugPrint('Could not open TestFlight: $e');
                }
              },
              icon: const Icon(Icons.download, color: Colors.white, size: 24),
              label: Text(
                'Join TestFlight Beta',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 32 : 48,
                  vertical: isMobile ? 16 : 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestFlightFeature(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
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
}
