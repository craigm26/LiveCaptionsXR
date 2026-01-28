import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/nav_bar.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/testflight_utils.dart';
import '../../utils/google_play_utils.dart';

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  static const String _liveCaptionsApkUrl =
      'https://github.com/craigm26/LiveCaptionsXR/releases/latest/download/LiveCaptionsXR.apk';
  static const String _continuonApkUrl =
      'https://github.com/continuonai/ContinuonXR/releases/latest/download/ContinuonXR.apk';

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
            _buildAppStoreSection(context, isMobile, isTablet),
            _buildSnapdragonSection(context, isMobile, isTablet),
            _buildDownloadCards(context, isMobile, isTablet),
            _buildSupportedDevices(context, isMobile, isTablet),
            _buildSideloadingNote(context, isMobile, isTablet),
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
            'Downloads',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  fontSize: isMobile ? 28 : isTablet ? 36 : 42,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Get Live Captions XR on your device. Choose the best option for your platform.',
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
            'App Store Downloads',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Standard app store versions with platform-native speech recognition',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              // iOS TestFlight
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
              // Google Play
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

  Widget _buildSnapdragonSection(BuildContext context, bool isMobile, bool isTablet) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getHorizontalPadding(context),
        vertical: isMobile ? 16.0 : 24.0,
      ),
      padding: EdgeInsets.all(isMobile ? 20.0 : 28.0),
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
        border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.memory, size: 32, color: Colors.deepOrange[700]),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Snapdragon NPU-Optimized Builds',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange[800],
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'For the best experience on Qualcomm Snapdragon devices, download our Nexa SDK-powered APKs. '
            'These run AI models directly on the Hexagon NPU for 2x faster inference and 9x better power efficiency.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[700],
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt, color: Colors.deepOrange[600]),
                const SizedBox(width: 8),
                Text(
                  'Requires: Snapdragon 8 Gen 1 or newer with Hexagon NPU',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadCards(BuildContext context, bool isMobile, bool isTablet) {
    final cardWidth = isMobile ? double.infinity : 420.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getHorizontalPadding(context),
        vertical: isMobile ? 24.0 : 40.0,
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        alignment: WrapAlignment.center,
        children: [
          SizedBox(
            width: cardWidth,
            child: _DownloadCard(
              icon: Icons.closed_caption,
              iconColor: Colors.deepOrange,
              badge: 'Nexa SDK',
              title: 'LiveCaptionsXR',
              description:
                  'Real-time spatial closed captioning powered by on-device AI. '
                  'Uses Nexa SDK for NPU-accelerated speech recognition and '
                  'ARCore for 3D caption placement at the speaker\'s location.',
              features: const [
                'Nexa ASR on Qualcomm Hexagon NPU',
                'Spatial AR captions via ARCore',
                '100% on-device, privacy-first',
                'Android XR & mobile support',
              ],
              onDownload: () => _launchUrl(_liveCaptionsApkUrl),
              buttonLabel: 'Download Snapdragon APK',
              buttonColor: Colors.deepOrange,
            ),
          ),
          SizedBox(
            width: cardWidth,
            child: _DownloadCard(
              icon: Icons.smart_toy,
              iconColor: Colors.deepPurple,
              badge: 'Nexa SDK',
              title: 'ContinuonXR',
              description:
                  'Robot trainer app with voice commands, camera vision, and '
                  'RLDS episode recording. Uses Nexa SDK for on-device vision '
                  'and voice pipelines to train robots without the cloud.',
              features: const [
                'Nexa Vision & Voice pipelines',
                'RLDS training data recording',
                'Drive controls & 6-axis arm',
                'WebRTC camera streaming',
              ],
              onDownload: () => _launchUrl(_continuonApkUrl),
              buttonLabel: 'Download Snapdragon APK',
              buttonColor: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportedDevices(BuildContext context, bool isMobile, bool isTablet) {
    final devices = [
      {'name': 'Samsung Galaxy S24 Ultra/S24+/S24', 'chip': 'Snapdragon 8 Gen 3'},
      {'name': 'Samsung Galaxy S23 Ultra/S23+/S23', 'chip': 'Snapdragon 8 Gen 2'},
      {'name': 'OnePlus 12 / OnePlus 11', 'chip': 'Snapdragon 8 Gen 3/2'},
      {'name': 'Xiaomi 14 Pro / Xiaomi 13', 'chip': 'Snapdragon 8 Gen 3/2'},
      {'name': 'Google Pixel 8 Pro (limited)', 'chip': 'Tensor G3'},
      {'name': 'Android XR Reference Devices', 'chip': 'Snapdragon XR2'},
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
          const SizedBox(height: 8),
          Text(
            'Nexa SDK APKs work best on these devices with NPU support',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: devices.map((device) {
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

  Widget _buildSideloadingNote(BuildContext context, bool isMobile, bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getHorizontalPadding(context),
        vertical: 16,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber[800], size: 24),
                const SizedBox(width: 12),
                Text(
                  'How to Install APK Files',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[900],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInstallStep(context, '1', 'Download the APK file to your device'),
            _buildInstallStep(context, '2', 'Go to Settings → Security (or Privacy)'),
            _buildInstallStep(context, '3', 'Enable "Install from unknown sources" for your browser'),
            _buildInstallStep(context, '4', 'Open the downloaded APK and tap Install'),
            _buildInstallStep(context, '5', 'Grant microphone and camera permissions when the app opens'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.android, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'On Samsung devices: Settings → Biometrics & Security → Install unknown apps',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallStep(BuildContext context, String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.amber[700],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
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
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: Colors.white),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    storeName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
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

class _DownloadCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String? badge;
  final String title;
  final String description;
  final List<String> features;
  final VoidCallback onDownload;
  final String buttonLabel;
  final Color buttonColor;

  const _DownloadCard({
    required this.icon,
    required this.iconColor,
    this.badge,
    required this.title,
    required this.description,
    required this.features,
    required this.onDownload,
    this.buttonLabel = 'Download APK',
    this.buttonColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 32, color: iconColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange[700],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 16),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 18, color: Colors.green[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(f,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[700],
                                )),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onDownload,
                icon: const Icon(Icons.download),
                label: Text(buttonLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
