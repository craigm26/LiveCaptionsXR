import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'nav_bar.dart';

class TechnologyPage extends StatefulWidget {
  const TechnologyPage({super.key});

  @override
  State<TechnologyPage> createState() => _TechnologyPageState();
}

class _TechnologyPageState extends State<TechnologyPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).location;
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      appBar: const NavBar(),
      endDrawer: isMobile ? NavDrawer(location: location) : null,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeroSection(context, isMobile),
              _buildTechTabs(context, isMobile),
              _buildArchitectureOverview(context, isMobile),
              _buildPerformanceMetrics(context, isMobile),
              _buildCallToAction(context, isMobile),
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
            Theme.of(context).primaryColor.withOpacity(0.1),
            Colors.purple.withOpacity(0.05),
            Colors.white,
          ],
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.memory,
            size: isMobile ? 64 : 80,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            'Advanced Technology Stack',
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
              'Powered by Google Gemma 3n and cutting-edge mobile AI.',
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

  Widget _buildTechTabs(BuildContext context, bool isMobile) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 16.0 : 48.0),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Theme.of(context).primaryColor,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'AI & ML'),
              Tab(text: 'Audio Processing'),
              Tab(text: 'Computer Vision'),
              Tab(text: 'AR Framework'),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAISection(),
                _buildAudioSection(),
                _buildVisionSection(),
                _buildARSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAISection() {
    final aiTechnologies = [
      {
        'name': 'Google Gemma 3n',
        'description':
            'On-device large language model for real-time speech recognition',
        'icon': Icons.psychology,
        'features': [
          'On-device inference',
          'Multi-language support',
          'Low latency',
          'Privacy-first'
        ],
      },
      {
        'name': 'TensorFlow Lite',
        'description': 'Mobile-optimized ML framework for edge computing',
        'icon': Icons.apps,
        'features': [
          'GPU acceleration',
          'Model quantization',
          'Cross-platform',
          'Efficient runtime'
        ],
      },
      {
        'name': 'Core ML',
        'description': 'Apple\'s native ML framework for iOS optimization',
        'icon': Icons.apple,
        'features': [
          'Hardware acceleration',
          'iOS integration',
          'Model optimization',
          'Neural Engine'
        ],
      },
    ];

    return _buildTechnologyGrid(aiTechnologies);
  }

  Widget _buildAudioSection() {
    final audioTechnologies = [
      {
        'name': 'AVAudioEngine',
        'description': 'Real-time audio processing and spatial analysis',
        'icon': Icons.audiotrack,
        'features': [
          'Real-time processing',
          'Spatial audio',
          'Low latency',
          'Hardware acceleration'
        ],
      },
      {
        'name': 'MediaPipe Audio',
        'description': 'Google\'s audio processing pipeline for ML',
        'icon': Icons.graphic_eq,
        'features': [
          'Audio classification',
          'Voice activity detection',
          'Noise reduction',
          'Feature extraction'
        ],
      },
      {
        'name': 'FMOD',
        'description': 'Professional audio engine for spatial sound',
        'icon': Icons.surround_sound,
        'features': [
          '3D audio',
          'Real-time effects',
          'Cross-platform',
          'Low-level control'
        ],
      },
    ];

    return _buildTechnologyGrid(audioTechnologies);
  }

  Widget _buildVisionSection() {
    final visionTechnologies = [
      {
        'name': 'MediaPipe Face',
        'description': 'Real-time face detection and landmark tracking',
        'icon': Icons.face,
        'features': [
          '468 facial landmarks',
          'Real-time tracking',
          'Multi-face support',
          'Cross-platform'
        ],
      },
      {
        'name': 'Vision Framework',
        'description': 'Apple\'s computer vision framework',
        'icon': Icons.visibility,
        'features': [
          'Face detection',
          'Object tracking',
          'Text recognition',
          'Barcode scanning'
        ],
      },
      {
        'name': 'OpenCV',
        'description': 'Open-source computer vision library',
        'icon': Icons.camera_alt,
        'features': [
          'Image processing',
          'Feature detection',
          'Video analysis',
          'Machine learning'
        ],
      },
    ];

    return _buildTechnologyGrid(visionTechnologies);
  }

  Widget _buildARSection() {
    final arTechnologies = [
      {
        'name': 'ARKit',
        'description': 'Apple\'s augmented reality development platform',
        'icon': Icons.view_in_ar,
        'features': [
          'World tracking',
          'Plane detection',
          'Light estimation',
          'Face tracking'
        ],
      },
      {
        'name': 'RealityKit',
        'description': 'High-performance 3D rendering for AR',
        'icon': Icons.threed_rotation,
        'features': [
          'Physically based rendering',
          'Animation system',
          'Audio spatialization',
          'Occlusion'
        ],
      },
      {
        'name': 'Flutter AR',
        'description': 'Cross-platform AR integration for Flutter',
        'icon': Icons.flutter_dash,
        'features': [
          'Cross-platform',
          'Widget integration',
          'Native performance',
          'Hot reload'
        ],
      },
    ];

    return _buildTechnologyGrid(arTechnologies);
  }

  Widget _buildTechnologyGrid(List<Map<String, dynamic>> technologies) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        childAspectRatio: 3.5,
        mainAxisSpacing: 16,
      ),
      itemCount: technologies.length,
      itemBuilder: (context, index) {
        final tech = technologies[index];
        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  tech['icon'] as IconData,
                  size: 40,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tech['name'] as String,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tech['description'] as String,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: (tech['features'] as List<String>)
                            .map(
                              (feature) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  feature,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context).primaryColor,
                                      ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildArchitectureOverview(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 16.0 : 48.0),
      padding: const EdgeInsets.symmetric(vertical: 48.0),
      child: Column(
        children: [
          Text(
            'System Architecture',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                _buildArchitectureLayer('Input Layer',
                    'Camera • Microphone • Sensors', Icons.input),
                const SizedBox(height: 16),
                Icon(Icons.arrow_downward, color: Colors.grey[600]),
                const SizedBox(height: 16),
                _buildArchitectureLayer('Processing Layer',
                    'Gemma 3n • MediaPipe • Kalman Filter', Icons.memory),
                const SizedBox(height: 16),
                Icon(Icons.arrow_downward, color: Colors.grey[600]),
                const SizedBox(height: 16),
                _buildArchitectureLayer('Output Layer',
                    'AR Overlay • Haptic Feedback • Audio', Icons.output),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchitectureLayer(
      String title, String components, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  components,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics(BuildContext context, bool isMobile) {
    final metrics = [
      {'metric': 'Latency', 'value': '<50ms', 'icon': Icons.speed},
      {'metric': 'Accuracy', 'value': '99.5%', 'icon': Icons.check_circle},
      {
        'metric': 'Battery Life',
        'value': '8+ hours',
        'icon': Icons.battery_full
      },
      {'metric': 'Memory Usage', 'value': '<512MB', 'icon': Icons.memory},
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16.0 : 48.0,
        vertical: 48.0,
      ),
      color: Colors.grey[50],
      child: Column(
        children: [
          Text(
            'Performance Metrics',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 2 : 4,
              childAspectRatio: 1.2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemCount: metrics.length,
            itemBuilder: (context, index) {
              final metric = metrics[index];
              return Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        metric['icon'] as IconData,
                        size: 32,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        metric['value'] as String,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        metric['metric'] as String,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
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
        vertical: 48.0,
      ),
      child: Column(
        children: [
          Icon(
            Icons.rocket_launch,
            size: 48,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Ready to Experience the Future?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'See our technology in action with the interactive demo.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () => context.go('/demo'),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Try Interactive Demo'),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/features'),
                icon: const Icon(Icons.list),
                label: const Text('View Features'),
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
