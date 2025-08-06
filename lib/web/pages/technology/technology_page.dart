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
              _buildCrossPlatformSection(context, screenSize),
              _buildTechTabs(context, screenSize),
              _buildArchitectureOverview(context, screenSize),
              _buildPerformanceMetrics(context, screenSize),
              _buildCallToAction(context, screenSize),
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
              Icons.memory,
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
                  'Advanced Technology Stack',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                        fontSize: isMobile ? 28 : isTablet ? 32 : 36,
                      ),
                ),
                SizedBox(height: isMobile ? 6 : 8),
                Text(
                  'Powered by on-device AI, multimodal sensor fusion, and native Augmented Reality frameworks.',
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

  Widget _buildCrossPlatformSection(BuildContext context, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getHorizontalPadding(context),
        vertical: isMobile ? 24.0 : 32.0,
      ),
      child: Card(
        color: Colors.blue[50],
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 20.0 : 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.android, color: Colors.green[700], size: isMobile ? 28 : 32),
                  SizedBox(width: isMobile ? 8 : 12),
                  Icon(Icons.vrpano, color: Colors.deepPurple, size: isMobile ? 28 : 32),
                  SizedBox(width: isMobile ? 8 : 12),
                  Icon(Icons.phone_iphone, color: Colors.grey[800], size: isMobile ? 28 : 32),
                ],
              ),
              SizedBox(height: isMobile ? 12 : 16),
              Text(
                'Cross-Platform Support',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                      fontSize: isMobile ? 20 : 22,
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isMobile ? 8 : 12),
              Text(
                'Live Captions XR supports both iOS and Android platforms with platform-specific speech recognition: Apple Speech Recognition on iOS and whisper_ggml on Android.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.blueGrey[800],
                      fontSize: isMobile ? 14 : 16,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTechTabs(BuildContext context, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getHorizontalPadding(context)),
      child: Column(
        children: [
          // Responsive TabBar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Theme.of(context).primaryColor,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: TextStyle(
                fontSize: isMobile ? 12 : isTablet ? 13 : 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: isMobile ? 12 : isTablet ? 13 : 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(text: isMobile ? 'AI & ML' : 'AI & Machine Learning'),
                Tab(text: isMobile ? 'Audio' : 'Audio & Localization'),
                Tab(text: isMobile ? 'Vision' : 'Computer Vision'),
                Tab(text: isMobile ? 'AR' : 'Augmented Reality'),
              ],
            ),
          ),
          SizedBox(height: isMobile ? 20 : 24),
          SizedBox(
            height: isMobile ? 280 : isTablet ? 320 : 360,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAISection(screenSize),
                _buildAudioSection(screenSize),
                _buildVisionSection(screenSize),
                _buildARSection(screenSize),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAISection(ScreenSize screenSize) {
    final aiTechnologies = [
      {
        'name': 'Apple Speech Recognition',
        'description': 'Native iOS speech recognition framework for real-time, on-device transcription with offline support.',
        'icon': Icons.mic,
        'features': ['Native iOS integration', 'Real-time processing', 'Offline capability', 'High accuracy']
      },
      {
        'name': 'Google Gemma 3n',
        'description': 'On-device large language model for contextual enhancement and multimodal understanding.',
        'icon': Icons.psychology,
        'features': ['On-device inference', 'Context enhancement', 'Privacy-first', 'Multimodal fusion']
      },
      {
        'name': 'MediaPipe LLM Inference API',
        'description': 'Optimized engine for running large models like Gemma on mobile devices.',
        'icon': Icons.apps,
        'features': ['GPU acceleration', 'Efficient runtime', 'Cross-platform', 'Streaming support']
      },
      {
        'name': 'Kalman Filter',
        'description': 'Algorithm for fusing noisy sensor data from multiple sources for robust tracking.',
        'icon': Icons.filter_center_focus,
        'features': ['Sensor fusion', 'Real-time estimation', 'Noise reduction', 'Predictive tracking']
      },
    ];

    return _buildTechnologyGrid(aiTechnologies, screenSize);
  }

  Widget _buildAudioSection(ScreenSize screenSize) {
    final audioTechnologies = [
      {
        'name': 'Hybrid Localization Engine',
        'description': 'Custom engine to determine speaker location by fusing audio, vision, and IMU data.',
        'icon': Icons.hearing,
        'features': ['Audio-visual fusion', 'IMU integration', 'High accuracy', 'Real-time']
      },
      {
        'name': 'AVAudioEngine',
        'description': 'Native iOS framework for real-time stereo audio capture and processing.',
        'icon': Icons.audiotrack,
        'features': ['Low-latency capture', 'Hardware acceleration', 'Stereo processing', 'iOS optimized']
      },
      {
        'name': 'Direction Estimation (RMS & GCC-PHAT)',
        'description': 'Algorithms applied to stereo audio to estimate the direction of a sound source.',
        'icon': Icons.graphic_eq,
        'features': ['Sound source localization', 'Noise resilient', 'Real-time analysis', 'Core of localization']
      },
    ];

    return _buildTechnologyGrid(audioTechnologies, screenSize);
  }

  Widget _buildVisionSection(ScreenSize screenSize) {
    final visionTechnologies = [
      {
        'name': 'Visual Speaker Identifier',
        'description': 'Custom module to detect faces and identify the current speaker visually.',
        'icon': Icons.face_retouching_natural,
        'features': ['Active speaker detection', 'Face tracking', 'Multimodal context', 'Privacy-focused']
      },
      {
        'name': 'Apple Vision Framework',
        'description': 'Native iOS framework for high-performance face detection and analysis.',
        'icon': Icons.visibility,
        'features': ['Hardware accelerated', 'Face detection', 'Facial landmark analysis', 'iOS optimized']
      },
    ];

    return _buildTechnologyGrid(visionTechnologies, screenSize);
  }

  Widget _buildARSection(ScreenSize screenSize) {
    final arTechnologies = [
      {
        'name': 'ARKit',
        'description': 'Apple\'s native augmented reality framework for world tracking and scene understanding on iOS.',
        'icon': Icons.view_in_ar,
        'features': ['World tracking', 'Plane detection', 'Light estimation', '3D object rendering']
      },
      {
        'name': 'ARCore',
        'description': 'Google\'s native augmented reality framework for world tracking and scene understanding on Android.',
        'icon': Icons.view_in_ar_outlined,
        'features': ['World tracking', 'Plane detection', 'Light estimation', 'Cross-platform (Android)']
      },
      {
        'name': 'Custom Flutter Plugins',
        'description': 'A robust bridge connecting the Flutter UI with native AR, AI, and sensor processing code.',
        'icon': Icons.flutter_dash,
        'features': ['Method & Event Channels', 'Native performance', 'Seamless integration', 'Extensible']
      },
    ];

    return _buildTechnologyGrid(arTechnologies, screenSize);
  }

  Widget _buildTechnologyGrid(List<Map<String, dynamic>> technologies, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;
    
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        childAspectRatio: isMobile ? 3.8 : isTablet ? 4.2 : 4.5,
        mainAxisSpacing: isMobile ? 8 : 12,
      ),
      itemCount: technologies.length,
      itemBuilder: (context, index) {
        final tech = technologies[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 8 : 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    tech['icon'] as IconData,
                    size: isMobile ? 24 : 28,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                SizedBox(width: isMobile ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tech['name'] as String,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 14 : 16,
                            ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      SizedBox(height: isMobile ? 2 : 4),
                      Flexible(
                        child: Text(
                          tech['description'] as String,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                                fontSize: isMobile ? 12 : 13,
                              ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                      SizedBox(height: isMobile ? 4 : 6),
                      Flexible(
                        child: Wrap(
                          spacing: isMobile ? 4 : 6,
                          runSpacing: isMobile ? 4 : 6,
                          children: (tech['features'] as List<String>)
                              .take(isMobile ? 2 : 3)
                              .map((feature) => Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isMobile ? 6 : 8,
                                      vertical: isMobile ? 2 : 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      feature,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).primaryColor,
                                            fontSize: isMobile ? 9 : 10,
                                            fontWeight: FontWeight.w500,
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

  Widget _buildArchitectureOverview(BuildContext context, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;
    
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getHorizontalPadding(context)),
      padding: EdgeInsets.symmetric(vertical: isMobile ? 24.0 : 32.0),
      child: Column(
        children: [
          Text(
            'System Architecture',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  fontSize: isMobile ? 24 : isTablet ? 28 : 32,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 20 : 24),
          Container(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : isTablet ? 700 : 800,
            ),
            padding: EdgeInsets.all(isMobile ? 20 : 24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                _buildArchitectureLayer('Input Layer', 'Camera • Stereo Microphone • IMU', Icons.input, screenSize),
                SizedBox(height: isMobile ? 12 : 16),
                Icon(Icons.arrow_downward, color: Colors.grey[600], size: isMobile ? 18 : 20),
                SizedBox(height: isMobile ? 12 : 16),
                _buildArchitectureLayer('Processing Layer', 'Gemma 3n • Hybrid Localization • Native Vision/Audio', Icons.memory, screenSize),
                SizedBox(height: isMobile ? 12 : 16),
                Icon(Icons.arrow_downward, color: Colors.grey[600], size: isMobile ? 18 : 20),
                SizedBox(height: isMobile ? 12 : 16),
                _buildArchitectureLayer('Output Layer', 'ARKit/ARCore Overlay • Real-time Captions', Icons.output, screenSize),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchitectureLayer(String title, String components, IconData icon, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 6 : 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: isMobile ? 20 : 24,
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 14 : 16,
                      ),
                ),
                SizedBox(height: isMobile ? 2 : 4),
                Text(
                  components,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontSize: isMobile ? 12 : 14,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics(BuildContext context, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;
    
    final metrics = [
      {'metric': 'Latency', 'value': '<100ms', 'icon': Icons.speed},
      {'metric': 'Accuracy', 'value': '>95%', 'icon': Icons.check_circle},
      {'metric': 'CPU Usage', 'value': 'Optimized', 'icon': Icons.memory},
      {'metric': 'Power', 'value': 'Efficient', 'icon': Icons.battery_charging_full},
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getHorizontalPadding(context),
        vertical: isMobile ? 24.0 : 32.0,
      ),
      color: Colors.grey[50],
      child: Column(
        children: [
          Text(
            'Performance Goals',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  fontSize: isMobile ? 24 : isTablet ? 28 : 32,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 20 : 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 2 : isTablet ? 2 : 4,
              childAspectRatio: isMobile ? 1.6 : isTablet ? 1.8 : 2.0,
              mainAxisSpacing: isMobile ? 8 : 12,
              crossAxisSpacing: isMobile ? 8 : 12,
            ),
            itemCount: metrics.length,
            itemBuilder: (context, index) {
              final metric = metrics[index];
              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(isMobile ? 8 : 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          metric['icon'] as IconData,
                          size: isMobile ? 20 : 24,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      SizedBox(height: isMobile ? 6 : 8),
                      Text(
                        metric['value'] as String,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                              fontSize: isMobile ? 14 : 16,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isMobile ? 2 : 4),
                      Text(
                        metric['metric'] as String,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontSize: isMobile ? 11 : 12,
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

  Widget _buildCallToAction(BuildContext context, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getHorizontalPadding(context),
        vertical: isMobile ? 24.0 : 32.0,
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
                  color: Theme.of(context).primaryColor,
                  fontSize: isMobile ? 20 : isTablet ? 22 : 24,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 6 : 8),
          Text(
            'Download Live Captions XR and experience real-time AR captions.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                  fontSize: isMobile ? 14 : 16,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 20 : 24),
          Wrap(
            spacing: isMobile ? 8 : 12,
            runSpacing: isMobile ? 8 : 12,
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
                label: Text(isMobile ? 'iOS' : 'iOS TestFlight'),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 20,
                    vertical: isMobile ? 10 : 12,
                  ),
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
                label: Text(isMobile ? 'Android' : 'Android Beta'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 20,
                    vertical: isMobile ? 10 : 12,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/features'),
                icon: const Icon(Icons.list),
                label: Text(isMobile ? 'Features' : 'View Features'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  side: BorderSide(color: Theme.of(context).primaryColor),
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
