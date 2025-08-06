import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/nav_bar.dart';
import '../../widgets/interactive_demo.dart';
import '../../utils/testflight_utils.dart';
import '../../utils/google_play_utils.dart';
import '../../config/web_performance_config.dart';
import '../../utils/responsive_utils.dart';

class EnhancedFeaturesPage extends StatefulWidget {
  const EnhancedFeaturesPage({super.key});

  @override
  State<EnhancedFeaturesPage> createState() => _EnhancedFeaturesPageState();
}

class _EnhancedFeaturesPageState extends State<EnhancedFeaturesPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _cardAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: WebPerformanceConfig.slowAnimationDuration,
      vsync: this,
    );

    _cardAnimations = List.generate(7, (index) {
      final double start = (index * 0.08).clamp(0.0, 0.4);
      final double end = (start + 0.6).clamp(start + 0.1, 1.0);

      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            start,
            end,
            curve: Curves.easeOutBack,
          ),
        ),
      );
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
            _buildTechnologyShowcase(context, screenSize),
            _buildFeaturesGrid(context, screenSize),
            _buildTechnologyStack(context, screenSize),
            _buildCallToAction(context, screenSize),
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
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
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
              Icons.featured_play_list,
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
                  'Revolutionary Features',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                        fontSize: isMobile ? 28 : isTablet ? 32 : 36,
                      ),
                ),
                SizedBox(height: isMobile ? 6 : 8),
                Text(
                  'Experience advanced accessibility with platform-specific speech recognition, on-device AI, and spatial captioning technologies.',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.grey[600],
                        height: 1.4,
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

  Widget _buildTechnologyShowcase(BuildContext context, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;
    
    final demos = [
      {
        'title': 'Platform Speech Recognition',
        'description': 'Platform-specific speech recognition: Apple Speech Recognition (iOS) and whisper_ggml (Android) for optimal performance.',
        'icon': Icons.mic,
        'color': Colors.blue,
        'features': [
          'Platform-optimized',
          'Real-time transcription',
          'Privacy-first',
          'Offline capability'
        ],
        'onTap': () => context.go('/technology'),
      },
      {
        'title': 'Gemma 3n Context Enhancement',
        'description': 'Google\'s state-of-the-art multimodal AI for contextual enhancement and understanding of speech content.',
        'icon': Icons.psychology,
        'color': Colors.green,
        'features': [
          'Context enhancement',
          'Multimodal fusion',
          'Intelligent processing',
          'On-device AI'
        ],
        'onTap': () => context.go('/technology'),
      },
      {
        'title': 'Hybrid Localization',
        'description': 'Advanced stereo audio with GCC-PHAT direction estimation and Kalman filter fusion for precise speaker positioning.',
        'icon': Icons.hearing,
        'color': Colors.purple,
        'features': [
          'GCC-PHAT direction estimation',
          'Kalman filter fusion',
          'Real-time processing',
          'Multi-speaker support'
        ],
        'onTap': () => context.go('/technology'),
      },
      {
        'title': 'AR Spatial Captions',
        'description': 'Real-time face detection and speaker identification using ARKit/ARCore for 3D spatial caption placement.',
        'icon': Icons.visibility,
        'color': Colors.orange,
        'features': [
          'Face detection',
          'Speaker identification',
          '3D spatial placement',
          'Privacy-focused'
        ],
        'onTap': () => context.go('/technology'),
      },
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getHorizontalPadding(context),
        vertical: isMobile ? 32.0 : isTablet ? 40.0 : 48.0,
      ),
      child: Column(
        children: [
          Text(
            'Core Technologies',
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
              'Advanced technologies working together to create the most comprehensive accessibility solution.',
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
            itemCount: demos.length,
            itemBuilder: (context, index) {
              final demo = demos[index];
              return _buildTechnologyCard(context, demo, screenSize);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTechnologyCard(BuildContext context, Map<String, dynamic> demo, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: demo['onTap'] as VoidCallback,
        borderRadius: BorderRadius.circular(16),
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
                      color: (demo['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      demo['icon'] as IconData,
                      color: demo['color'] as Color,
                      size: isMobile ? 24 : 28,
                    ),
                  ),
                  SizedBox(width: isMobile ? 12 : 16),
                  Expanded(
                    child: Text(
                      demo['title'] as String,
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
                  demo['description'] as String,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontSize: isMobile ? 13 : 14,
                      ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: isMobile ? 2 : 3,
                ),
              ),
              SizedBox(height: isMobile ? 8 : 12),
              Wrap(
                spacing: isMobile ? 4 : 6,
                runSpacing: isMobile ? 4 : 6,
                children: (demo['features'] as List<String>)
                    .take(isMobile ? 2 : 3)
                    .map((feature) => Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 6 : 8,
                            vertical: isMobile ? 2 : 3,
                          ),
                          decoration: BoxDecoration(
                            color: (demo['color'] as Color).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            feature,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: demo['color'] as Color,
                                  fontSize: isMobile ? 9 : 10,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesGrid(BuildContext context, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;
    
    final features = [
      {
        'icon': Icons.hearing,
        'title': 'Platform Speech Recognition',
        'desc': 'Platform-specific speech recognition optimized for each operating system: Apple Speech Recognition (iOS) and whisper_ggml (Android).',
        'details': [
          'Apple Speech Recognition (iOS)',
          'whisper_ggml with Whisper base model (Android)',
          'Real-time transcription',
          'Offline processing capability'
        ],
        'color': Colors.blue,
      },
      {
        'icon': Icons.visibility,
        'title': 'Computer Vision',
        'desc': 'ARKit/ARCore-powered face detection and speaker identification for precise visual tracking and spatial awareness.',
        'details': [
          'Real-time face detection',
          'Speaker identification',
          'Multi-person tracking',
          'Privacy-first on-device processing'
        ],
        'color': Colors.green,
      },
      {
        'icon': Icons.navigation,
        'title': 'Spatial Audio Processing',
        'desc': 'Advanced stereo audio with GCC-PHAT direction estimation and hybrid localization for precise speaker positioning.',
        'details': [
          'GCC-PHAT direction estimation',
          'Stereo audio processing',
          'Hybrid audio-visual fusion',
          'Real-time spatial mapping'
        ],
        'color': Colors.purple,
      },
      {
        'icon': Icons.psychology,
        'title': 'Gemma 3n Multimodal AI',
        'desc': 'Google\'s state-of-the-art multimodal AI for contextual enhancement, visual understanding, and intelligent caption generation.',
        'details': [
          'Multimodal data fusion',
          'Contextual enhancement',
          'Visual scene understanding',
          'Intelligent caption generation'
        ],
        'color': Colors.orange,
      },
      {
        'icon': Icons.vibration,
        'title': 'Haptic Feedback',
        'desc': 'Rich tactile responses synchronized with visual and audio cues for enhanced accessibility experience.',
        'details': [
          'Directional vibration patterns',
          'Intensity-based feedback',
          'Custom haptic profiles',
          'Multi-modal synchronization'
        ],
        'color': Colors.red,
      },
      {
        'icon': Icons.language,
        'title': 'Privacy-First Design',
        'desc': 'All processing happens on-device with no data sent to external servers, ensuring complete privacy and offline functionality.',
        'details': [
          '100% on-device processing',
          'No cloud data transmission',
          'Offline functionality',
          'Complete privacy protection'
        ],
        'color': Colors.teal,
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
            'Comprehensive Feature Set',
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
              'Every feature is designed to work together seamlessly, creating the most comprehensive accessibility solution available.',
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
              return AnimatedBuilder(
                animation: _cardAnimations[index],
                builder: (context, child) {
                  return Transform.scale(
                    scale: _cardAnimations[index].value,
                    child: _buildFeatureCard(context, feature, screenSize),
                  );
                },
              );
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 10 : 12),
                  decoration: BoxDecoration(
                    color: (feature['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    color: feature['color'] as Color,
                    size: isMobile ? 24 : 28,
                  ),
                ),
                SizedBox(width: isMobile ? 12 : 16),
                Expanded(
                  child: Text(
                    feature['title'] as String,
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
                feature['desc'] as String,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      height: 1.4,
                      fontSize: isMobile ? 13 : 14,
                    ),
                overflow: TextOverflow.ellipsis,
                maxLines: isMobile ? 2 : 3,
              ),
            ),
            SizedBox(height: isMobile ? 8 : 12),
            ...(feature['details'] as List<String>).take(isMobile ? 2 : 3).map((detail) {
              return Padding(
                padding: EdgeInsets.only(bottom: isMobile ? 4 : 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: isMobile ? 14 : 16,
                      color: (feature['color'] as Color),
                    ),
                    SizedBox(width: isMobile ? 6 : 8),
                    Expanded(
                      child: Text(
                        detail,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                              fontSize: isMobile ? 11 : 12,
                            ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnologyStack(BuildContext context, ScreenSize screenSize) {
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
            Colors.grey[50]!,
            Colors.white,
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            'Technology Stack',
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
              'Built with the latest technologies for maximum performance and reliability.',
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
              crossAxisCount: isMobile ? 2 : isTablet ? 3 : 4,
              childAspectRatio: isMobile ? 1.8 : isTablet ? 2.0 : 2.2,
              mainAxisSpacing: isMobile ? 12 : 16,
              crossAxisSpacing: isMobile ? 12 : 16,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              final techStacks = [
                {'name': 'Flutter', 'description': 'Cross-platform UI framework', 'icon': Icons.flutter_dash, 'color': Colors.blue},
                {'name': 'Platform Speech Recognition', 'description': 'iOS: Apple Speech, Android: whisper_ggml', 'icon': Icons.mic, 'color': Colors.green},
                {'name': 'Gemma 3n', 'description': 'Multimodal AI model', 'icon': Icons.psychology, 'color': Colors.purple},
                {'name': 'ARKit/ARCore', 'description': 'Augmented Reality frameworks', 'icon': Icons.view_in_ar, 'color': Colors.orange},
                {'name': 'Dart', 'description': 'Programming language', 'icon': Icons.code, 'color': Colors.cyan},
                {'name': 'Native Plugins', 'description': 'Platform-specific optimizations', 'icon': Icons.extension, 'color': Colors.red},
              ];
              final tech = techStacks[index];
              return _buildTechStackItem(context, tech['name'] as String, tech['description'] as String, tech['icon'] as IconData, tech['color'] as Color, screenSize);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTechStackItem(BuildContext context, String name, String description, IconData icon, Color color, ScreenSize screenSize) {
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
              padding: EdgeInsets.all(isMobile ? 8 : 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: isMobile ? 24 : 28,
                color: color,
              ),
            ),
            SizedBox(height: isMobile ? 8 : 12),
            Text(
              name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                    fontSize: isMobile ? 12 : 14,
                  ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            SizedBox(height: isMobile ? 2 : 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: isMobile ? 10 : 11,
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

  Widget _buildCallToAction(BuildContext context, ScreenSize screenSize) {
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
} 