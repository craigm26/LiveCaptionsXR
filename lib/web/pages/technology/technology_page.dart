import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/nav_bar.dart';
import '../../utils/testflight_utils.dart';
import '../../utils/google_play_utils.dart';
import '../../utils/responsive_utils.dart';

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
    final String location = GoRouterState.of(context).uri.toString();
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
                          'Live Captions XR is designed for the next generation of accessibility—optimized for Android XR headsets, but also fully compatible with Android and iOS devices. Stay tuned for our upcoming Android and XR releases!',
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
        vertical: isMobile ? 32.0 : 48.0, // Reduced vertical padding
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
            Icons.memory,
            size: isMobile ? 48 : 64, // Reduced icon size
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16), // Reduced spacing
          Text(
            'Advanced Technology Stack',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12), // Reduced spacing
          Container(
            constraints:
                BoxConstraints(maxWidth: isMobile ? double.infinity : 700),
            child: Text(
              'Powered by on-device AI, multimodal sensor fusion, and native Augmented Reality frameworks.',
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
              Tab(text: 'Audio & Localization'),
              Tab(text: 'Computer Vision'),
              Tab(text: 'Augmented Reality'),
            ],
          ),
          const SizedBox(height: 24), // Reduced spacing
          SizedBox(
            height: 320, // Reduced height from 400
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
        'name': 'Apple Speech Recognition',
        'description':
            'Native iOS speech recognition framework for real-time, on-device transcription with offline support.',
        'icon': Icons.mic,
        'features': [
          'Native iOS integration',
          'Real-time processing',
          'Offline capability',
          'High accuracy'
        ],
      },
      {
        'name': 'Google Gemma 3n',
        'description':
            'On-device large language model for contextual enhancement and multimodal understanding.',
        'icon': Icons.psychology,
        'features': [
          'On-device inference',
          'Context enhancement',
          'Privacy-first',
          'Multimodal fusion'
        ],
      },
      {
        'name': 'MediaPipe LLM Inference API',
        'description':
            'Optimized engine for running large models like Gemma on mobile devices.',
        'icon': Icons.apps,
        'features': [
          'GPU acceleration',
          'Efficient runtime',
          'Cross-platform',
          'Streaming support'
        ],
      },
      {
        'name': 'Kalman Filter',
        'description':
            'Algorithm for fusing noisy sensor data from multiple sources for robust tracking.',
        'icon': Icons.filter_center_focus,
        'features': [
          'Sensor fusion',
          'Real-time estimation',
          'Noise reduction',
          'Predictive tracking'
        ],
      },
    ];

    return _buildTechnologyGrid(aiTechnologies);
  }

  Widget _buildAudioSection() {
    final audioTechnologies = [
      {
        'name': 'Hybrid Localization Engine',
        'description':
            'Custom engine to determine speaker location by fusing audio, vision, and IMU data.',
        'icon': Icons.hearing,
        'features': [
          'Audio-visual fusion',
          'IMU integration',
          'High accuracy',
          'Real-time'
        ],
      },
      {
        'name': 'AVAudioEngine',
        'description':
            'Native iOS framework for real-time stereo audio capture and processing.',
        'icon': Icons.audiotrack,
        'features': [
          'Low-latency capture',
          'Hardware acceleration',
          'Stereo processing',
          'iOS optimized'
        ],
      },
      {
        'name': 'Direction Estimation (RMS & GCC-PHAT)',
        'description':
            'Algorithms applied to stereo audio to estimate the direction of a sound source.',
        'icon': Icons.graphic_eq,
        'features': [
          'Sound source localization',
          'Noise resilient',
          'Real-time analysis',
          'Core of localization'
        ],
      },
    ];

    return _buildTechnologyGrid(audioTechnologies);
  }

  Widget _buildVisionSection() {
    final visionTechnologies = [
      {
        'name': 'Visual Speaker Identifier',
        'description':
            'Custom module to detect faces and identify the current speaker visually.',
        'icon': Icons.face_retouching_natural,
        'features': [
          'Active speaker detection',
          'Face tracking',
          'Multimodal context',
          'Privacy-focused'
        ],
      },
      {
        'name': 'Apple Vision Framework',
        'description':
            'Native iOS framework for high-performance face detection and analysis.',
        'icon': Icons.visibility,
        'features': [
          'Hardware accelerated',
          'Face detection',
          'Facial landmark analysis',
          'iOS optimized'
        ],
      },
    ];

    return _buildTechnologyGrid(visionTechnologies);
  }

  Widget _buildARSection() {
    final arTechnologies = [
      {
        'name': 'ARKit',
        'description':
            'Apple\'s native augmented reality framework for world tracking and scene understanding on iOS.',
        'icon': Icons.view_in_ar,
        'features': [
          'World tracking',
          'Plane detection',
          'Light estimation',
          '3D object rendering'
        ],
      },
      {
        'name': 'ARCore',
        'description':
            'Google\'s native augmented reality framework for world tracking and scene understanding on Android.',
        'icon': Icons.view_in_ar_outlined,
        'features': [
          'World tracking',
          'Plane detection',
          'Light estimation',
          'Cross-platform (Android)'
        ],
      },
      {
        'name': 'Custom Flutter Plugins',
        'description':
            'A robust bridge connecting the Flutter UI with native AR, AI, and sensor processing code.',
        'icon': Icons.flutter_dash,
        'features': [
          'Method & Event Channels',
          'Native performance',
          'Seamless integration',
          'Extensible'
        ],
      },
    ];

    return _buildTechnologyGrid(arTechnologies);
  }

  Widget _buildTechnologyGrid(List<Map<String, dynamic>> technologies) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        childAspectRatio: 4.0, // Increased aspect ratio for more compact cards
        mainAxisSpacing: 12, // Reduced spacing
      ),
      itemCount: technologies.length,
      itemBuilder: (context, index) {
        final tech = technologies[index];
        return Card(
          elevation: 2, // Reduced elevation
          child: Padding(
            padding: const EdgeInsets.all(12.0), // Reduced padding
            child: Row(
              children: [
                Icon(
                  tech['icon'] as IconData,
                  size: 32, // Reduced icon size
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12), // Reduced spacing
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tech['name'] as String,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Flexible(
                        child: Text(
                          tech['description'] as String,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(height: 4), // Reduced spacing
                      Flexible(
                        child: Wrap(
                          spacing: 3, // Reduced spacing
                          runSpacing: 3, // Reduced spacing
                          children: (tech['features'] as List<String>)
                              .take(3) // Limit to 3 features to prevent overflow
                              .map((feature) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1), // Reduced padding
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6), // Reduced radius
                                    ),
                                    child: Text(
                                      feature,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context).primaryColor,
                                            fontSize: 9, // Reduced font size
                                          ),
                                    ),
                                  ))
                              .toList(),
                        ),
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
      padding: const EdgeInsets.symmetric(vertical: 32.0), // Reduced padding
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
          const SizedBox(height: 24), // Reduced spacing
          Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(24), // Reduced padding
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                _buildArchitectureLayer('Input Layer',
                    'Camera • Stereo Microphone • IMU', Icons.input),
                const SizedBox(height: 12), // Reduced spacing
                Icon(Icons.arrow_downward, color: Colors.grey[600], size: 20), // Reduced icon size
                const SizedBox(height: 12), // Reduced spacing
                _buildArchitectureLayer(
                    'Processing Layer',
                    'Gemma 3n • Hybrid Localization • Native Vision/Audio',
                    Icons.memory),
                const SizedBox(height: 12), // Reduced spacing
                Icon(Icons.arrow_downward, color: Colors.grey[600], size: 20), // Reduced icon size
                const SizedBox(height: 12), // Reduced spacing
                _buildArchitectureLayer('Output Layer',
                    'ARKit/ARCore Overlay • Real-time Captions', Icons.output),
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
      padding: const EdgeInsets.all(12), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 24), // Reduced icon size
          const SizedBox(width: 12), // Reduced spacing
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
                const SizedBox(height: 2), // Reduced spacing
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
      {'metric': 'Latency', 'value': '<100ms', 'icon': Icons.speed},
      {'metric': 'Accuracy', 'value': '>95%', 'icon': Icons.check_circle},
      {'metric': 'CPU Usage', 'value': 'Optimized', 'icon': Icons.memory},
      {
        'metric': 'Power',
        'value': 'Efficient',
        'icon': Icons.battery_charging_full
      },
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16.0 : 48.0,
        vertical: 32.0, // Reduced padding
      ),
      color: Colors.grey[50],
      child: Column(
        children: [
          Text(
            'Performance Goals',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24), // Reduced spacing
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 2 : 4,
              childAspectRatio: 1.8, // Increased aspect ratio for more compact cards
              mainAxisSpacing: 12, // Reduced spacing
              crossAxisSpacing: 12, // Reduced spacing
            ),
            itemCount: metrics.length,
            itemBuilder: (context, index) {
              final metric = metrics[index];
              return Card(
                elevation: 1, // Reduced elevation
                child: Padding(
                  padding: const EdgeInsets.all(12.0), // Reduced padding
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        metric['icon'] as IconData,
                        size: 24, // Reduced icon size
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 4), // Reduced spacing
                      Flexible(
                        child: Text(
                          metric['value'] as String,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(height: 2), // Reduced spacing
                      Flexible(
                        child: Text(
                          metric['metric'] as String,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
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
        vertical: 32.0, // Reduced padding
      ),
      child: Column(
        children: [
          Icon(
            Icons.rocket_launch,
            size: 36, // Reduced icon size
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 12), // Reduced spacing
          Text(
            'Ready to Experience the Future?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6), // Reduced spacing
          Text(
            'Download Live Captions XR and experience real-time AR captions.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24), // Reduced spacing
          Wrap(
            spacing: 12, // Reduced spacing
            runSpacing: 12, // Reduced spacing
            alignment: WrapAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () async {
                  try {
                    await TestFlightUtils.openTestFlight();
                  } catch (e) {
                    debugPrint('Could not open TestFlight: $e');
                  }
                },
                icon: const Icon(Icons.apple),
                label: const Text('iOS TestFlight'),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Reduced padding
                ),
              ),
              FilledButton.icon(
                onPressed: () async {
                  try {
                    await GooglePlayUtils.openGooglePlayBeta();
                  } catch (e) {
                    debugPrint('Could not open Google Play Beta: $e');
                  }
                },
                icon: const Icon(Icons.android),
                label: const Text('Android Beta'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Reduced padding
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/features'),
                icon: const Icon(Icons.list),
                label: const Text('View Features'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  side: BorderSide(color: Theme.of(context).primaryColor),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Reduced padding
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
