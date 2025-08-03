import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../widgets/nav_bar.dart';
import '../../utils/testflight_utils.dart';
import '../../utils/google_play_utils.dart';
import '../../config/web_performance_config.dart';
import '../../utils/responsive_utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  
  // YouTube player controller
  late YoutubePlayerController _youtubeController;

  @override
  void initState() {
    super.initState();

    // Initialize YouTube player controller
    _youtubeController = YoutubePlayerController.fromVideoId(
      videoId: 'Oz8nzt2cc3Q', // Extracted from https://youtu.be/Oz8nzt2cc3Q
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        enableCaption: true,
        mute: false,
      ),
    );

    // Use optimized animation durations from performance config
    _fadeController = AnimationController(
      duration: WebPerformanceConfig.normalAnimationDuration,
      vsync: this,
    );
    _slideController = AnimationController(
      duration: WebPerformanceConfig.slowAnimationDuration,
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _youtubeController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: const NavBar(),

      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            _buildHeroSection(context, isMobile, screenWidth),

            // Youtube Embed Section
            _buildYoutubeEmbedSection(context, isMobile),

            // Technology Highlights Section
            _buildTechnologyHighlights(context, isMobile),

            // Features Preview Section
            _buildFeaturesPreview(context, isMobile),

            // Stats Section

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
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
            Theme.of(context).primaryColor.withValues(alpha: 0.05),
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
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.3),
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

                // Main headline
                Text(
                  'Live Captions XR',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                        fontSize: isMobile ? 32 : 48,
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isMobile ? 16 : 24),

                // Subtitle
                Container(
                  constraints: BoxConstraints(
                    maxWidth: isMobile ? double.infinity : 600,
                  ),
                  child: Text(
                    'Revolutionary AR-powered live captioning with on-device AI, spatial audio, and contextual understanding.',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                          height: 1.5,
                          fontSize: isMobile ? 18 : 22,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: isMobile ? 32 : 48),

                // CTA Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.go('/features'),
                      icon: const Icon(Icons.explore),
                      label: Text(
                        'Explore Features',
                        style: TextStyle(fontSize: isMobile ? 16 : 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 24 : 32,
                          vertical: isMobile ? 16 : 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(width: isMobile ? 16 : 24),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/technology'),
                      icon: const Icon(Icons.psychology),
                      label: Text(
                        'Learn Technology',
                        style: TextStyle(fontSize: isMobile ? 16 : 18),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                        side: BorderSide(color: Theme.of(context).primaryColor),
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 24 : 32,
                          vertical: isMobile ? 16 : 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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

  Widget _buildTechnologyHighlights(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 48.0,
        vertical: isMobile ? 48.0 : 80.0,
      ),
      child: Column(
        children: [
          Text(
            'Powered by Advanced AI',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 24 : 32),
          Container(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : 800,
            ),
            child: Text(
              'Live Captions XR combines cutting-edge on-device AI technologies to deliver the most advanced accessibility experience.',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: isMobile ? 32 : 48),
          
          // Technology cards
          Wrap(
            spacing: isMobile ? 16 : 24,
            runSpacing: isMobile ? 16 : 24,
            alignment: WrapAlignment.center,
            children: [
              _buildTechCard(
                context,
                'Whisper GGML',
                'On-device speech recognition using the Whisper base model for fast, private, offline transcription.',
                Icons.mic,
                Colors.blue,
                isMobile,
              ),
              _buildTechCard(
                context,
                'Gemma 3n',
                'Google\'s state-of-the-art multimodal AI for contextual enhancement and understanding.',
                Icons.psychology,
                Colors.green,
                isMobile,
              ),
              _buildTechCard(
                context,
                'Spatial Audio',
                'Advanced stereo audio processing with directional awareness and speaker localization.',
                Icons.hearing,
                Colors.purple,
                isMobile,
              ),
              _buildTechCard(
                context,
                'Computer Vision',
                'Real-time face detection and speaker identification using on-device AI.',
                Icons.visibility,
                Colors.orange,
                isMobile,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTechCard(BuildContext context, String title, String description,
      IconData icon, Color color, bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                  height: 1.5,
                ),
          ),
        ],
      ),
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
            color: Colors.grey.withValues(alpha: 0.1),
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
              color: (feature['color'] as Color).withValues(alpha: 0.1),
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
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await TestFlightUtils.openTestFlight();
                  } catch (e) {
                    debugPrint('Could not open TestFlight: $e');
                  }
                },
                icon: const Icon(Icons.apple),
                label: const Text('iOS TestFlight'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await GooglePlayUtils.openGooglePlayBeta();
                  } catch (e) {
                    debugPrint('Could not open Google Play Beta: $e');
                  }
                },
                icon: const Icon(Icons.android),
                label: const Text('Android Beta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/technology'),
                icon: const Icon(Icons.code),
                label: const Text('View Technology'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  side: BorderSide(color: Theme.of(context).primaryColor),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
            Theme.of(context).primaryColor.withValues(alpha: 0.03),
            Colors.blue.withValues(alpha: 0.02),
            Colors.white,
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            'Available on Mobile',
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
              'Join our beta programs to get early access to Live Captions XR and help us improve the experience for everyone.',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),

          // Platform Icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // iOS App Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
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
              SizedBox(width: isMobile ? 24 : 48),
              // Android App Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.android,
                  size: 64,
                  color: Colors.green[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Beta Features
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

          // Download Buttons
          Wrap(
            spacing: isMobile ? 16 : 24,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              // iOS TestFlight Button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withValues(alpha: 0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
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
                  icon: const Icon(Icons.apple, color: Colors.white, size: 24),
                  label: Text(
                    'iOS TestFlight',
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
                      horizontal: isMobile ? 24 : 32,
                      vertical: isMobile ? 16 : 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              // Android Google Play Beta Button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Colors.green[600]!,
                      Colors.green[600]!.withValues(alpha: 0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green[600]!.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await GooglePlayUtils.openGooglePlayBeta();
                    } catch (e) {
                      debugPrint('Could not open Google Play Beta: $e');
                    }
                  },
                  icon: const Icon(Icons.android, color: Colors.white, size: 24),
                  label: Text(
                    'Android Beta',
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
                      horizontal: isMobile ? 24 : 32,
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
        ],
      ),
    );
  }

  Widget _buildYoutubeEmbedSection(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: 8,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: isMobile ? 24 : 40,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'See Live Captions XR in Action',
            style: TextStyle(
              fontSize: isMobile ? 24 : 32,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Watch our demo video to see how Live Captions XR transforms accessibility in augmented reality',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isMobile ? double.infinity : 800,
                maxHeight: isMobile ? 300 : 450,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: YoutubePlayer(
                  controller: _youtubeController,
                  aspectRatio: 16 / 9,
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
}
