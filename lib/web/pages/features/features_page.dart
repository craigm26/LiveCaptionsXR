import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/nav_bar.dart';
import '../../utils/testflight_utils.dart';
import '../../config/web_performance_config.dart';

class FeaturesPage extends StatefulWidget {
  const FeaturesPage({super.key});

  @override
  State<FeaturesPage> createState() => _FeaturesPageState();
}

class _FeaturesPageState extends State<FeaturesPage>
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

    _cardAnimations = List.generate(6, (index) {
      // Calculate safe intervals that don't exceed 1.0
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
    final features = [
      {
        'icon': Icons.hearing,
        'title': 'Advanced Sound Detection',
        'desc':
            'Real-time audio analysis with directional awareness using spatial audio processing and machine learning algorithms.',
        'details': [
          '360° spatial audio detection',
          'Multi-speaker identification',
          'Background noise filtering',
          'Real-time frequency analysis'
        ],
        'color': Colors.blue,
      },
      {
        'icon': Icons.visibility,
        'title': 'Computer Vision',
        'desc':
            'On-device face detection and speaker identification using advanced computer vision and facial recognition.',
        'details': [
          'Real-time face detection',
          'Speaker lip-sync correlation',
          'Multi-person tracking',
          'Privacy-first on-device processing'
        ],
        'color': Colors.green,
      },
      {
        'icon': Icons.navigation,
        'title': 'Spatial Localization',
        'desc':
            'Precise 3D positioning of sounds using advanced sensor fusion combining audio, visual, and IMU data.',
        'details': [
          'IMU sensor integration',
          'Audio-visual correlation',
          '3D spatial mapping',
          'Dynamic position tracking'
        ],
        'color': Colors.purple,
      },
      {
        'icon': Icons.psychology,
        'title': 'Contextual AI',
        'desc':
            'Intelligent context understanding using Gemma 3n multimodal AI for enhanced accuracy and relevance.',
        'details': [
          'Multimodal data fusion',
          'Context-aware processing',
          'Intelligent noise reduction',
          'Adaptive learning algorithms'
        ],
        'color': Colors.orange,
      },
      {
        'icon': Icons.vibration,
        'title': 'Haptic Feedback',
        'desc':
            'Rich tactile responses synchronized with visual and audio cues for enhanced accessibility experience.',
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
        'title': 'Multilingual ASR',
        'desc':
            'Advanced Automatic Speech Recognition supporting 100+ languages with streaming real-time processing.',
        'details': [
          'Real-time streaming ASR',
          '100+ language support',
          'Dialect recognition',
          'Code-switching detection'
        ],
        'color': Colors.teal,
      },
    ];

    final String location = GoRouterState.of(context).location;
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      appBar: const NavBar(),
      endDrawer: isMobile ? NavDrawer(location: location) : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(context, isMobile),
            _buildFeaturesGrid(context, features, isMobile),
            _buildTechnologyStack(context, isMobile),
            _buildCallToAction(context, isMobile),
          ],
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
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Colors.white,
          ],
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.featured_play_list,
            size: isMobile ? 64 : 80,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            'Comprehensive Features',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
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
              'Discover the advanced technologies and features that make Live Captions XR the most comprehensive accessibility solution available.',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid(BuildContext context,
      List<Map<String, dynamic>> features, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 48.0,
        vertical: isMobile ? 32.0 : 48.0,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount =
              isMobile ? 1 : (constraints.maxWidth > 1200 ? 3 : 2);
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: isMobile ? 1.2 : 0.8,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _cardAnimations[index],
                builder: (context, child) {
                  return Transform.scale(
                    scale: _cardAnimations[index].value,
                    child: Opacity(
                      opacity: _cardAnimations[index].value,
                      child:
                          _buildFeatureCard(context, features[index], isMobile),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFeatureCard(
      BuildContext context, Map<String, dynamic> feature, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (feature['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                feature['icon'] as IconData,
                size: 32,
                color: feature['color'] as Color,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              feature['title'] as String,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              feature['desc'] as String,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Key Capabilities:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: feature['color'] as Color,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...((feature['details'] as List<String>)
                      .map((detail) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin:
                                      const EdgeInsets.only(top: 6, right: 8),
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: feature['color'] as Color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    detail,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.grey[700],
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnologyStack(BuildContext context, bool isMobile) {
    final technologies = [
      {'name': 'Flutter', 'icon': Icons.flutter_dash, 'color': Colors.blue},
      {'name': 'Gemma 3n', 'icon': Icons.psychology, 'color': Colors.purple},
      {
        'name': 'MediaPipe',
        'icon': Icons.video_camera_back,
        'color': Colors.green
      },
      {'name': 'ARKit', 'icon': Icons.view_in_ar, 'color': Colors.orange},
      {'name': 'Core ML', 'icon': Icons.memory, 'color': Colors.red},
      {'name': 'AVFoundation', 'icon': Icons.audiotrack, 'color': Colors.teal},
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 48.0,
        vertical: isMobile ? 48.0 : 64.0,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey[50]!,
            Colors.white,
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            'Built with Advanced Technologies',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: technologies
                .map((tech) => _buildTechItem(context, tech))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTechItem(BuildContext context, Map<String, dynamic> tech) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: (tech['color'] as Color).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tech['icon'] as IconData,
            size: 20,
            color: tech['color'] as Color,
          ),
          const SizedBox(width: 8),
          Text(
            tech['name'] as String,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallToAction(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 48.0,
        vertical: isMobile ? 48.0 : 64.0,
      ),
      child: Column(
        children: [
          Text(
            'Experience These Features Live',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Download Live Captions XR from TestFlight to experience these features',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  await TestFlightUtils.openTestFlight();
                },
                icon: const Icon(Icons.apple),
                label: const Text('Download on TestFlight'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/technology'),
                icon: const Icon(Icons.code),
                label: const Text('View Technology'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
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
