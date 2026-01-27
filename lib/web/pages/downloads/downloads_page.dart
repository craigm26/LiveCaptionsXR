import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/nav_bar.dart';
import '../../utils/responsive_utils.dart';

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
            _buildDownloadCards(context, isMobile, isTablet),
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
            'Get our Nexa SDK-powered apps for Android XR and mobile devices.',
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
              iconColor: Theme.of(context).primaryColor,
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
            ),
          ),
          SizedBox(
            width: cardWidth,
            child: _DownloadCard(
              icon: Icons.smart_toy,
              iconColor: Colors.deepPurple,
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
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: Colors.amber[800], size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sideloading Instructions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[900],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'These APKs are installed directly (sideloaded). '
                    'On your Android device, go to Settings → Security → '
                    'enable "Install from unknown sources" for your browser or '
                    'file manager. Then open the downloaded APK to install.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                          height: 1.5,
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
}

class _DownloadCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final List<String> features;
  final VoidCallback onDownload;

  const _DownloadCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.features,
    required this.onDownload,
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
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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
                label: const Text('Download APK'),
                style: ElevatedButton.styleFrom(
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
