import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  @override
  void initState() {
    super.initState();

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

    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = ResponsiveUtils.getScreenSize(context);

    return Scaffold(
      appBar: const NavBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(context, screenSize),
            _buildDownloadSection(context, screenSize),
            _buildTechnologyHighlights(context, screenSize),
            _buildFeaturesPreview(context, screenSize),
            _buildSnapdragonSection(context, screenSize),
            _buildOpenSourceSection(context, screenSize),
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
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
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
                      'Real-time, spatially-aware closed captioning powered by on-device AI. Optimized for Qualcomm Snapdragon devices with NPU acceleration.',
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
                          onPressed: () => context.go('/downloads'),
                          icon: const Icon(Icons.download),
                          label: Text(
                            'Download Now',
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
                          onPressed: () => context.go('/features'),
                          icon: const Icon(Icons.explore),
                          label: Text(
                            'Explore Features',
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

  Widget _buildDownloadSection(BuildContext context, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getHorizontalPadding(context),
        vertical: isMobile ? 32.0 : isTablet ? 40.0 : 48.0,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.03),
      ),
      child: Column(
        children: [
          Text(
            'Get the App',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  fontSize: isMobile ? 24 : isTablet ? 28 : 32,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            'Available on iOS, Android, and optimized APKs for Snapdragon devices with Nexa SDK',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                  fontSize: isMobile ? 14 : 16,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 24 : 32),
          Wrap(
            spacing: isMobile ? 12 : 16,
            runSpacing: isMobile ? 12 : 16,
            alignment: WrapAlignment.center,
            children: [
              // iOS TestFlight
              _buildDownloadButton(
                context,
                icon: Icons.apple,
                label: 'iOS TestFlight',
                subtitle: 'iPhone & iPad',
                color: Colors.black87,
                onPressed: () async {
                  try {
                    await TestFlightUtils.openTestFlight();
                  } catch (e) {
                    debugPrint('Could not open TestFlight: $e');
                  }
                },
                isMobile: isMobile,
              ),
              // Google Play
              _buildDownloadButton(
                context,
                icon: Icons.android,
                label: 'Google Play',
                subtitle: 'Android Devices',
                color: Colors.green[700]!,
                onPressed: () async {
                  try {
                    await GooglePlayUtils.openGooglePlayBeta();
                  } catch (e) {
                    debugPrint('Could not open Google Play: $e');
                  }
                },
                isMobile: isMobile,
              ),
              // Snapdragon APK
              _buildDownloadButton(
                context,
                icon: Icons.memory,
                label: 'Snapdragon APK',
                subtitle: 'Nexa NPU Optimized',
                color: Colors.deepOrange,
                onPressed: () => context.go('/downloads'),
                isMobile: isMobile,
                highlighted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onPressed,
    required bool isMobile,
    bool highlighted = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        color: highlighted ? color : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : 28,
              vertical: isMobile ? 16 : 20,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: highlighted ? null : Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: isMobile ? 28 : 32,
                  color: highlighted ? Colors.white : color,
                ),
                SizedBox(width: isMobile ? 12 : 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: highlighted ? Colors.white : Colors.grey[800],
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 14,
                        color: highlighted ? Colors.white70 : Colors.grey[600],
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

  Widget _buildSnapdragonSection(BuildContext context, ScreenSize screenSize) {
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
            Colors.deepOrange.withValues(alpha: 0.05),
            Colors.orange.withValues(alpha: 0.03),
            Colors.white,
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.vrpano, size: isMobile ? 32 : 40, color: Colors.blue[700]),
              SizedBox(width: isMobile ? 12 : 16),
              Flexible(
                child: Text(
                  'Built for XR Headsets & AR Glasses',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                        fontSize: isMobile ? 20 : isTablet ? 24 : 28,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),
          Container(
            constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 800),
            child: Text(
              'Designed for Samsung Galaxy XR (Project Moohan) and future Snapdragon-powered AR glasses. '
              'Uses Nexa SDK on the Hexagon NPU for 2x faster AI inference and 9x better power efficiency.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                    height: 1.5,
                    fontSize: isMobile ? 15 : 17,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: isMobile ? 24 : 32),
          // Target Hardware
          Text(
            'Target Hardware',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  fontSize: isMobile ? 18 : 20,
                ),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Wrap(
            spacing: isMobile ? 8 : 12,
            runSpacing: isMobile ? 8 : 12,
            alignment: WrapAlignment.center,
            children: [
              _buildDeviceChip(context, '🥽 Samsung Galaxy XR', isMobile, primary: true),
              _buildDeviceChip(context, '🥽 Android XR Devices', isMobile, primary: true),
              _buildDeviceChip(context, '👓 Future AR Glasses', isMobile, primary: true),
              _buildDeviceChip(context, 'Galaxy S24/S23 (testing)', isMobile),
              _buildDeviceChip(context, 'OnePlus 12/11 (testing)', isMobile),
              _buildDeviceChip(context, 'Xiaomi 14/13 (testing)', isMobile),
            ],
          ),
          SizedBox(height: isMobile ? 24 : 32),
          // Installation Steps
          Container(
            constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 600),
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How to Install',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                ),
                SizedBox(height: isMobile ? 12 : 16),
                _buildInstallStep(context, '1', 'Download the APK from the Downloads page', isMobile),
                _buildInstallStep(context, '2', 'On your device: Settings → Security → Enable "Install unknown apps"', isMobile),
                _buildInstallStep(context, '3', 'Open the downloaded APK and tap Install', isMobile),
                _buildInstallStep(context, '4', 'Grant microphone and camera permissions when prompted', isMobile),
              ],
            ),
          ),
          SizedBox(height: isMobile ? 20 : 28),
          ElevatedButton.icon(
            onPressed: () => context.go('/downloads'),
            icon: const Icon(Icons.download),
            label: const Text('Download Snapdragon APK'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24 : 32,
                vertical: isMobile ? 14 : 18,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceChip(BuildContext context, String label, bool isMobile, {bool primary = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 18,
        vertical: isMobile ? 10 : 12,
      ),
      decoration: BoxDecoration(
        gradient: primary ? LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.15),
            Colors.purple.withValues(alpha: 0.1),
          ],
        ) : null,
        color: primary ? null : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primary ? Colors.blue.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.3),
          width: primary ? 2 : 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: isMobile ? 13 : 14,
          fontWeight: primary ? FontWeight.bold : FontWeight.w500,
          color: primary ? Colors.blue[800] : Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildInstallStep(BuildContext context, String number, String text, bool isMobile) {
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 10 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isMobile ? 24 : 28,
            height: isMobile ? 24 : 28,
            decoration: BoxDecoration(
              color: Colors.deepOrange,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
            ),
          ),
          SizedBox(width: isMobile ? 10 : 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isMobile ? 14 : 15,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
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
              'Combining cutting-edge on-device AI technologies for the most advanced accessibility experience.',
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
                  'title': 'Nexa ASR on NPU',
                  'description': 'Whisper-based speech recognition accelerated on Qualcomm Hexagon NPU for real-time transcription with minimal battery drain.',
                  'icon': Icons.mic,
                  'color': Colors.blue,
                },
                {
                  'title': 'Gemma 3n Multimodal AI',
                  'description': 'Google\'s multimodal AI for contextual enhancement, visual understanding, and intelligent caption generation.',
                  'icon': Icons.psychology,
                  'color': Colors.green,
                },
                {
                  'title': 'Hybrid Localization',
                  'description': 'Stereo audio with GCC-PHAT direction estimation and Kalman filter fusion for precise speaker positioning.',
                  'icon': Icons.hearing,
                  'color': Colors.purple,
                },
                {
                  'title': 'AR Spatial Captions',
                  'description': 'ARKit/ARCore-powered face detection for 3D spatial caption placement at the speaker\'s location.',
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
                  child: Icon(icon, color: color, size: isMobile ? 24 : 28),
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
        'desc': 'Platform-native speech recognition with spatial audio processing',
        'color': Colors.blue,
      },
      {
        'icon': Icons.visibility,
        'title': 'Visual Recognition',
        'desc': 'AR-powered face detection and speaker identification',
        'color': Colors.green,
      },
      {
        'icon': Icons.psychology,
        'title': 'Multimodal AI',
        'desc': 'Contextual enhancement and intelligent caption generation',
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
          SizedBox(height: isMobile ? 20 : 24),
          OutlinedButton.icon(
            onPressed: () => context.go('/technology'),
            icon: const Icon(Icons.code),
            label: const Text('View on GitHub'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 28,
                vertical: isMobile ? 12 : 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
