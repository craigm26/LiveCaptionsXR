import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/nav_bar.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/testflight_utils.dart';
import '../../utils/google_play_utils.dart';

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  static const String _liveCaptionsApkUrl =
      'https://github.com/craigm26/LiveCaptionsXR/releases/latest/download/app-release.apk';

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = ResponsiveUtils.getScreenSize(context);
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;

    return Scaffold(
      appBar: const NavBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context, isMobile, isTablet),
            _buildMainDownload(context, isMobile, isTablet),
            _buildInstallationGuide(context, isMobile, isTablet),
            _buildAfterInstall(context, isMobile, isTablet),
            _buildAppStoreSection(context, isMobile, isTablet),
            _buildSupportedDevices(context, isMobile, isTablet),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile, bool isTablet) {
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
      child: Column(
        children: [
          Text(
            'Download Live Captions XR',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  fontSize: isMobile ? 26 : isTablet ? 34 : 40,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Text(
              'Get the Nexa SDK-powered APK for Samsung Galaxy XR, Android XR headsets, and Snapdragon phones.',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                    height: 1.4,
                    fontSize: isMobile ? 16 : isTablet ? 18 : 20,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainDownload(BuildContext context, bool isMobile, bool isTablet) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getHorizontalPadding(context),
        vertical: isMobile ? 16.0 : 24.0,
      ),
      padding: EdgeInsets.all(isMobile ? 24.0 : 32.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepOrange.withValues(alpha: 0.1),
            Colors.orange.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.closed_caption, size: 40, color: Colors.deepOrange[700]),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LiveCaptionsXR.apk',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Nexa SDK • NPU Optimized',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Real-time spatial closed captioning powered by on-device AI. Runs Whisper speech recognition directly on the Qualcomm Hexagon NPU.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[700],
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: isMobile ? double.infinity : 320,
            child: ElevatedButton.icon(
              onPressed: () => _launchUrl(_liveCaptionsApkUrl),
              icon: const Icon(Icons.download, size: 24),
              label: const Text(
                'Download APK',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.vrpano, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'For: Samsung Galaxy XR • Android XR • Snapdragon Phones',
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallationGuide(BuildContext context, bool isMobile, bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getHorizontalPadding(context),
        vertical: isMobile ? 16.0 : 24.0,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        padding: EdgeInsets.all(isMobile ? 20.0 : 28.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.install_mobile, color: Colors.green[700], size: 28),
                ),
                const SizedBox(width: 16),
                Text(
                  'How to Install',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Step 1
            _buildDetailedStep(
              context,
              number: '1',
              title: 'Download the APK',
              description: 'Tap the "Download APK" button above. The file will download to your device (usually in the Downloads folder).',
              icon: Icons.file_download,
              color: Colors.blue,
            ),
            
            // Step 2
            _buildDetailedStep(
              context,
              number: '2',
              title: 'Enable Installation from Unknown Sources',
              description: 'Before you can install, you need to allow your browser to install apps:',
              icon: Icons.security,
              color: Colors.orange,
              subSteps: [
                'Open your device Settings',
                'Go to "Apps" or "Applications"',
                'Find your browser (Chrome, Firefox, etc.)',
                'Tap "Install unknown apps"',
                'Toggle ON "Allow from this source"',
              ],
            ),
            
            // Samsung specific note
            Container(
              margin: const EdgeInsets.only(left: 40, bottom: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.phone_android, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Samsung Devices',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Settings → Biometrics and Security → Install unknown apps → Select your browser → Allow',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Step 3
            _buildDetailedStep(
              context,
              number: '3',
              title: 'Install the App',
              description: 'Open your Downloads folder (or tap the download notification). Tap the APK file and press "Install".',
              icon: Icons.touch_app,
              color: Colors.green,
            ),
            
            // Step 4
            _buildDetailedStep(
              context,
              number: '4',
              title: 'Open & Grant Permissions',
              description: 'Launch Live Captions XR from your app drawer. When prompted, allow access to:',
              icon: Icons.check_circle,
              color: Colors.purple,
              subSteps: [
                'Microphone (required for speech recognition)',
                'Camera (required for AR face tracking)',
              ],
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStep(
    BuildContext context, {
    required String number,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    List<String>? subSteps,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: subSteps != null ? 120 : 40,
                  color: Colors.grey[300],
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: color),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                if (subSteps != null) ...[
                  const SizedBox(height: 10),
                  ...subSteps.map((step) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.arrow_right, size: 18, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                step,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAfterInstall(BuildContext context, bool isMobile, bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getHorizontalPadding(context),
        vertical: isMobile ? 8.0 : 16.0,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        padding: EdgeInsets.all(isMobile ? 20.0 : 24.0),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.celebration, color: Colors.green[700], size: 24),
                const SizedBox(width: 12),
                Text(
                  'After Installation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCheckItem(context, 'Look for the "Live Captions XR" app icon in your app drawer'),
            _buildCheckItem(context, 'Point your camera at someone speaking'),
            _buildCheckItem(context, 'Captions will appear floating near the speaker\'s face'),
            _buildCheckItem(context, 'All processing happens on-device — no internet required!'),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 20, color: Colors.green[600]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppStoreSection(BuildContext context, bool isMobile, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getHorizontalPadding(context),
        vertical: isMobile ? 24.0 : 32.0,
      ),
      child: Column(
        children: [
          Text(
            'Also Available On',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Standard versions without Nexa SDK (uses platform speech recognition)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _StoreDownloadButton(
                icon: Icons.apple,
                storeName: 'iOS TestFlight',
                subtitle: 'iPhone & iPad',
                color: Colors.black87,
                onPressed: () async {
                  try {
                    await TestFlightUtils.openTestFlight();
                  } catch (e) {
                    debugPrint('Could not open TestFlight: $e');
                  }
                },
              ),
              _StoreDownloadButton(
                icon: Icons.android,
                storeName: 'Google Play',
                subtitle: 'Android Devices',
                color: Colors.green[700]!,
                onPressed: () async {
                  try {
                    await GooglePlayUtils.openGooglePlayBeta();
                  } catch (e) {
                    debugPrint('Could not open Google Play: $e');
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupportedDevices(BuildContext context, bool isMobile, bool isTablet) {
    final xrDevices = [
      {'name': 'Samsung Galaxy XR (Project Moohan)', 'chip': 'Snapdragon XR2+ Gen 2'},
      {'name': 'Android XR Reference Devices', 'chip': 'Snapdragon XR2'},
      {'name': 'Future Snapdragon AR Glasses', 'chip': 'Coming Soon'},
    ];
    final phoneDevices = [
      {'name': 'Samsung Galaxy S24/S23 Series', 'chip': 'Snapdragon 8 Gen 3/2'},
      {'name': 'OnePlus 12 / 11', 'chip': 'Snapdragon 8 Gen 3/2'},
      {'name': 'Xiaomi 14 / 13 Series', 'chip': 'Snapdragon 8 Gen 3/2'},
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getHorizontalPadding(context),
        vertical: isMobile ? 16.0 : 24.0,
      ),
      child: Column(
        children: [
          Text(
            'Supported Devices',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            '🥽 XR Headsets & Glasses',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: xrDevices.map((device) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withValues(alpha: 0.1),
                        Colors.purple.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        device['name']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        device['chip']!,
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '📱 Snapdragon Phones (for testing)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: phoneDevices.map((device) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      Text(
                        device['name']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        device['chip']!,
                        style: TextStyle(
                          color: Colors.deepOrange[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreDownloadButton extends StatelessWidget {
  final IconData icon;
  final String storeName;
  final String subtitle;
  final Color color;
  final VoidCallback onPressed;

  const _StoreDownloadButton({
    required this.icon,
    required this.storeName,
    required this.subtitle,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: Colors.white),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    storeName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
