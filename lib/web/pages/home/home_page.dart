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
    final screenSize = ResponsiveUtils.getScreenSize(context);
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return Scaffold(
      appBar: const NavBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(context, screenSize),
            _buildYoutubeEmbedSection(context, screenSize),
            _buildTechnologyHighlights(context, screenSize),
            _buildFeaturesPreview(context, screenSize),
            _buildTestFlightSection(context, screenSize),
            // let's build a open source section
            _buildOpenSourceSection(context, screenSize),
            //_buildCtaSection(context, screenSize),
          ],
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
            Theme.of(context).primaryColor.withValues(alpha: 0.05),
            Colors.white,
          ],
        ),
      ),
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Row(
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
                          height: isMobile ? 80 : isTablet ? 100 : 120,
                          width: isMobile ? 80 : isTablet ? 100 : 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(width: isMobile ? 20 : 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Live Captions XR',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                            fontSize: isMobile ? 28 : isTablet ? 32 : 36,
                          ),
                    ),
                    SizedBox(height: isMobile ? 8 : 12),
                    Text(
                      'Advanced accessibility application providing real-time, spatially-aware closed captioning with platform-specific speech recognition and on-device AI.',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.grey[600],
                            height: 1.4,
                            fontSize: isMobile ? 16 : isTablet ? 18 : 20,
                          ),
                    ),
                    SizedBox(height: isMobile ? 20 : 24),
                    Wrap(
                      spacing: isMobile ? 12 : 16,
                      runSpacing: isMobile ? 8 : 12,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => context.go('/features'),
                          icon: const Icon(Icons.explore),
                          label: Text(
                            isMobile ? 'Features' : 'Explore Features',
                            style: TextStyle(fontSize: isMobile ? 14 : 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 20 : 24,
                              vertical: isMobile ? 12 : 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.go('/technology'),
                          icon: const Icon(Icons.psychology),
                          label: Text(
                            isMobile ? 'Technology' : 'Learn Technology',
                            style: TextStyle(fontSize: isMobile ? 14 : 16),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                            side: BorderSide(color: Theme.of(context).primaryColor),
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 20 : 24,
                              vertical: isMobile ? 12 : 16,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTechnologyHighlights(BuildContext context, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getHorizontalPadding(context),
        vertical: isMobile ? 32.0 : isTablet ? 40.0 : 48.0,
      ),
      child: Column(
        children: [
          Text(
            'Powered by Advanced AI',
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
              'Live Captions XR combines cutting-edge on-device AI technologies to deliver the most advanced accessibility experience.',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                    height: 1.4,
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
              final technologies = [
                {
                  'title': 'Platform Speech Recognition',
                  'description': 'Android: whisper_ggml with Whisper base model. iOS: Native Apple Speech Recognition framework for optimal performance.',
                  'icon': Icons.mic,
                  'color': Colors.blue,
                },
                {
                  'title': 'Gemma 3n Multimodal AI',
                  'description': 'Google\'s state-of-the-art multimodal AI for contextual enhancement, visual understanding, and intelligent caption generation.',
                  'icon': Icons.psychology,
                  'color': Colors.green,
                },
                {
                  'title': 'Hybrid Localization',
                  'description': 'Advanced stereo audio with GCC-PHAT direction estimation and Kalman filter fusion for precise speaker positioning.',
                  'icon': Icons.hearing,
                  'color': Colors.purple,
                },
                {
                  'title': 'AR Spatial Captions',
                  'description': 'Real-time face detection and speaker identification using ARKit/ARCore for 3D spatial caption placement.',
                  'icon': Icons.visibility,
                  'color': Colors.orange,
                },
              ];
              final tech = technologies[index];
              return _buildTechCard(context, tech['title'] as String, tech['description'] as String, tech['icon'] as IconData, tech['color'] as Color, screenSize);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTechCard(BuildContext context, String title, String description,
      IconData icon, Color color, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: isMobile ? 24 : 28,
                  ),
                ),
                SizedBox(width: isMobile ? 12 : 16),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
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
                      height: 1.4,
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

  Widget _buildFeaturesPreview(BuildContext context, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;
    
    final features = [
      {
        'icon': Icons.hearing,
        'title': 'Real-Time Audio',
        'desc': 'Platform-native speech recognition with advanced spatial audio processing and direction estimation',
        'color': Colors.blue,
      },
      {
        'icon': Icons.visibility,
        'title': 'Visual Recognition',
        'desc': 'ARKit/ARCore-powered face detection and speaker identification for precise visual tracking',
        'color': Colors.green,
      },
      {
        'icon': Icons.psychology,
        'title': 'Multimodal AI',
        'desc': 'Gemma 3n multimodal AI for contextual enhancement and intelligent caption generation',
        'color': Colors.purple,
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getHorizontalPadding(context),
        vertical: isMobile ? 32.0 : isTablet ? 40.0 : 48.0,
      ),
      child: Column(
        children: [
          Text(
            'Key Features',
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
              'Core features that make Live Captions XR the most advanced accessibility solution available.',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                    height: 1.4,
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
              childAspectRatio: isMobile ? 2.2 : isTablet ? 2.5 : 2.8,
              mainAxisSpacing: isMobile ? 12 : 16,
              crossAxisSpacing: isMobile ? 12 : 16,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) {
              final feature = features[index];
              return _buildFeatureCard(context, feature, screenSize);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, Map<String, dynamic> feature, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: (feature['color'] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                feature['icon'] as IconData,
                size: isMobile ? 28 : 32,
                color: feature['color'] as Color,
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              feature['title'] as String,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 16 : 18,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 6 : 8),
            Expanded(
              child: Text(
                feature['desc'] as String,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      fontSize: isMobile ? 13 : 14,
                    ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: isMobile ? 2 : 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCtaSection(BuildContext context, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getHorizontalPadding(context),
        vertical: isMobile ? 32.0 : isTablet ? 40.0 : 48.0,
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
              Icons.rocket_launch,
              size: isMobile ? 32 : 36,
              color: Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            'Ready to Experience the Future?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  fontSize: isMobile ? 20 : isTablet ? 22 : 24,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 6 : 8),
          Text(
            'Join the accessibility revolution with Live Captions XR',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                  fontSize: isMobile ? 16 : isTablet ? 18 : 20,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 24 : 32),
          Wrap(
            spacing: isMobile ? 8 : 12,
            runSpacing: isMobile ? 8 : 12,
            alignment: WrapAlignment.center,
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
                label: Text(isMobile ? 'iOS' : 'iOS TestFlight'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 24,
                    vertical: isMobile ? 12 : 16,
                  ),
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
                label: Text(isMobile ? 'Android' : 'Android Beta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 24,
                    vertical: isMobile ? 12 : 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/technology'),
                icon: const Icon(Icons.code),
                label: Text(isMobile ? 'Technology' : 'View Technology'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  side: BorderSide(color: Theme.of(context).primaryColor),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 24,
                    vertical: isMobile ? 12 : 16,
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
    );
  }

  Widget _buildTestFlightSection(BuildContext context, ScreenSize screenSize) {
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
              'Join our beta programs to get early access to Live Captions XR and help us improve the experience for everyone.',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                    height: 1.4,
                    fontSize: isMobile ? 16 : isTablet ? 18 : 20,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: isMobile ? 24 : 32),
          // Platform Icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // iOS App Icon
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
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
                  size: isMobile ? 48 : isTablet ? 56 : 64,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              SizedBox(width: isMobile ? 20 : 32),
              // Android App Icon
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
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
                  size: isMobile ? 48 : isTablet ? 56 : 64,
                  color: Colors.green[600],
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 24 : 32),
          // Beta Features
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
              final features = [
                {'icon': Icons.science, 'title': 'Early Access', 'description': 'Get the latest features before public release'},
                {'icon': Icons.feedback, 'title': 'Direct Feedback', 'description': 'Help shape the future of the app'},
                {'icon': Icons.security, 'title': 'Secure Testing', 'description': 'Safe and secure beta testing environment'},
              ];
              final feature = features[index];
              return _buildTestFlightFeature(context, feature['icon'] as IconData, feature['title'] as String, feature['description'] as String, screenSize);
            },
          ),
          SizedBox(height: isMobile ? 24 : 32),
          // Download Buttons
          Wrap(
            spacing: isMobile ? 12 : 16,
            runSpacing: isMobile ? 8 : 12,
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
                  icon: const Icon(Icons.apple, color: Colors.white, size: 20),
                  label: Text(
                    isMobile ? 'iOS' : 'iOS TestFlight',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 20 : 24,
                      vertical: isMobile ? 12 : 16,
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
                  icon: const Icon(Icons.android, color: Colors.white, size: 20),
                  label: Text(
                    isMobile ? 'Android' : 'Android Beta',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 20 : 24,
                      vertical: isMobile ? 12 : 16,
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

  Widget _buildYoutubeEmbedSection(BuildContext context, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;
    
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getHorizontalPadding(context),
        vertical: isMobile ? 16 : 24,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: isMobile ? 24 : 32,
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
              fontSize: isMobile ? 20 : isTablet ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Text(
            'Watch our demo video to see how Live Captions XR transforms accessibility in augmented reality',
            style: TextStyle(
              fontSize: isMobile ? 14 : isTablet ? 16 : 18,
              color: Colors.grey[600],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 16 : 24),
          Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isMobile ? double.infinity : isTablet ? 700 : 800,
                maxHeight: isMobile ? 250 : isTablet ? 350 : 450,
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
    ScreenSize screenSize,
  ) {
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

  Widget _buildOpenSourceSection(BuildContext context, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getHorizontalPadding(context),
        vertical: isMobile ? 32.0 : isTablet ? 40.0 : 48.0,
      ),
      child: Column(
        children: [
          Text(
            'Open Source',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  fontSize: isMobile ? 24 : isTablet ? 28 : 32,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 16 : 20),
          Text( 
            'Live Captions XR is 100% open source and free to use. We believe in the power of open source to create a more accessible and inclusive world.',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                  height: 1.4,
                  fontSize: isMobile ? 16 : isTablet ? 18 : 20,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
