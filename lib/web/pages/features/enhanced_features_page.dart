import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/nav_bar.dart';
import '../../widgets/interactive_demo.dart';
import '../../utils/testflight_utils.dart';
import '../../config/web_performance_config.dart';

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

    _cardAnimations = List.generate(6, (index) {
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
    final String location = GoRouterState.of(context).uri.toString();
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      appBar: const NavBar(),

      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(context, isMobile),
            _buildTechnologyShowcase(context, isMobile),
            _buildFeaturesGrid(context, isMobile),
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
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
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
            'Revolutionary Features',
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
              'Experience the future of accessibility with cutting-edge AI, spatial audio, and augmented reality technologies.',
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

  Widget _buildTechnologyShowcase(BuildContext context, bool isMobile) {
    final demos = [
      {
        'title': 'Whisper GGML Speech Recognition',
        'description': 'On-device speech recognition using the Whisper base model for fast, private, offline transcription with ~3-5 second processing delay.',
        'icon': Icons.mic,
        'color': Colors.blue,
        'features': [
          'On-device processing',
          'Fast transcription',
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
        'title': 'Spatial Audio Processing',
        'description': 'Advanced stereo audio processing with directional awareness and real-time speaker localization.',
        'icon': Icons.hearing,
        'color': Colors.purple,
        'features': [
          '360° audio detection',
          'Directional awareness',
          'Real-time processing',
          'Multi-speaker support'
        ],
        'onTap': () => context.go('/technology'),
      },
      {
        'title': 'Computer Vision & Face Detection',
        'description': 'Real-time face detection and speaker identification using on-device AI for enhanced accuracy.',
        'icon': Icons.visibility,
        'color': Colors.orange,
        'features': [
          'Face detection',
          'Speaker identification',
          'Real-time processing',
          'Privacy-focused'
        ],
        'onTap': () => context.go('/technology'),
      },
    ];

    return DemoShowcase(
      demos: demos,
      isMobile: isMobile,
    );
  }

  Widget _buildFeaturesGrid(BuildContext context, bool isMobile) {
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

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 48.0,
        vertical: isMobile ? 48.0 : 80.0,
      ),
      child: Column(
        children: [
          Text(
            'Comprehensive Feature Set',
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
              'Every feature is designed to work together seamlessly, creating the most comprehensive accessibility solution available.',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: isMobile ? 32 : 48),
          Wrap(
            spacing: isMobile ? 16 : 24,
            runSpacing: isMobile ? 16 : 24,
            alignment: WrapAlignment.center,
            children: features.asMap().entries.map((entry) {
              final index = entry.key;
              final feature = entry.value;
              return AnimatedBuilder(
                animation: _cardAnimations[index],
                builder: (context, child) {
                  return Transform.scale(
                    scale: _cardAnimations[index].value,
                    child: _buildFeatureCard(context, feature, isMobile),
                  );
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, Map<String, dynamic> feature, bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 350,
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
          color: (feature['color'] as Color).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (feature['color'] as Color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              feature['icon'] as IconData,
              color: feature['color'] as Color,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            feature['title'] as String,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            feature['desc'] as String,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 16),
          ...(feature['details'] as List<String>).map((detail) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: (feature['color'] as Color),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      detail,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTechnologyStack(BuildContext context, bool isMobile) {
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
            Colors.grey[50]!,
            Colors.white,
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            'Technology Stack',
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
              'Built with the latest technologies for maximum performance and reliability.',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: isMobile ? 32 : 48),
          Wrap(
            spacing: isMobile ? 16 : 24,
            runSpacing: isMobile ? 16 : 24,
            alignment: WrapAlignment.center,
            children: [
              _buildTechStackItem(context, 'Flutter', 'Cross-platform UI framework', Icons.flutter_dash, Colors.blue),
              _buildTechStackItem(context, 'Whisper GGML', 'On-device speech recognition', Icons.mic, Colors.green),
              _buildTechStackItem(context, 'Gemma 3n', 'Multimodal AI model', Icons.psychology, Colors.purple),
              _buildTechStackItem(context, 'ARKit/ARCore', 'Augmented Reality frameworks', Icons.view_in_ar, Colors.orange),
              _buildTechStackItem(context, 'Dart', 'Programming language', Icons.code, Colors.cyan),
              _buildTechStackItem(context, 'Native Plugins', 'Platform-specific optimizations', Icons.extension, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTechStackItem(BuildContext context, String name, String description, IconData icon, Color color) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Icon(
            icon,
            size: 40,
            color: color,
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCallToAction(BuildContext context, bool isMobile) {
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
                label: const Text('Download TestFlight'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
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
} 