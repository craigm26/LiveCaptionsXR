import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'nav_bar.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
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
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final String location = GoRouterState.of(context).location;

    return Scaffold(
      appBar: const NavBar(),
      endDrawer: isMobile ? NavDrawer(location: location) : null,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isMobile ? 32 : 64),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.1),
                      Theme.of(context).primaryColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.privacy_tip_rounded,
                      size: isMobile ? 48 : 64,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Privacy Policy',
                      style: TextStyle(
                        fontSize: isMobile ? 32 : 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your privacy is our priority. Learn how we protect your data.',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 20,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Last updated: ${DateTime.now().year}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Privacy Highlights
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isMobile ? 24 : 32),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.green.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.verified_user_rounded,
                          color: Colors.green.shade700,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Privacy-First Design',
                          style: TextStyle(
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildPrivacyHighlight(
                      '🔒 Local Processing',
                      'Audio processing happens entirely on your device for maximum privacy.',
                      Colors.green.shade700,
                    ),
                    _buildPrivacyHighlight(
                      '🚫 No Data Collection',
                      'We don\'t collect, store, or transmit your personal conversations.',
                      Colors.green.shade700,
                    ),
                    _buildPrivacyHighlight(
                      '📱 Device-Only Storage',
                      'All user preferences and settings are stored locally on your device.',
                      Colors.green.shade700,
                    ),
                    _buildPrivacyHighlight(
                      '🔓 Open Source',
                      'Our code is publicly available for transparency and security auditing.',
                      Colors.green.shade700,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Main Content
              Container(
                padding: EdgeInsets.all(isMobile ? 24 : 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      'Introduction',
                      'LiveCaptionsXR is committed to protecting your privacy. This Privacy Policy explains how our open-source accessibility application handles your information.',
                      isMobile,
                    ),
                    _buildSection(
                      'Information We Don\'t Collect',
                      'LiveCaptionsXR is designed with privacy as a core principle:\n\n'
                          '• We do not collect or store audio recordings\n'
                          '• We do not track your conversations\n'
                          '• We do not collect personal identification information\n'
                          '• We do not use analytics or tracking services\n'
                          '• We do not share data with third parties',
                      isMobile,
                    ),
                    _buildSection(
                      'Local Data Processing',
                      'All audio processing and speech recognition occurs entirely on your device using Apple\'s on-device Speech Recognition framework. This means:\n\n'
                          '• Your voice data never leaves your device\n'
                          '• No internet connection is required for core functionality\n'
                          '• Speech recognition models are downloaded and run locally\n'
                          '• Captions are generated in real-time on your device',
                      isMobile,
                    ),
                    _buildSection(
                      'Device Permissions',
                      'LiveCaptionsXR requires certain permissions to function:\n\n'
                          '• **Microphone Access**: Required to capture audio for real-time transcription\n'
                          '• **Camera Access**: Required for AR functionality and spatial audio mapping\n'
                          '• **Speech Recognition**: Uses Apple\'s on-device Speech Recognition framework\n\n'
                          'These permissions are used solely for the app\'s core functionality and are processed locally on your device.',
                      isMobile,
                    ),
                    _buildSection(
                      'Data Storage',
                      'The app may store the following data locally on your device:\n\n'
                          '• User preferences and settings\n'
                          '• Language and accessibility configurations\n'
                          '• App usage statistics (stored locally only)\n\n'
                          'This data is never transmitted off your device and can be deleted by uninstalling the app.',
                      isMobile,
                    ),
                    _buildSection(
                      'Open Source Transparency',
                      'LiveCaptionsXR is an open-source project. Our complete source code is available on GitHub, allowing anyone to:\n\n'
                          '• Review our privacy practices\n'
                          '• Verify that we don\'t collect data\n'
                          '• Contribute to the project\n'
                          '• Report security issues\n\n'
                          'This transparency ensures accountability and builds trust with our users.',
                      isMobile,
                    ),
                    _buildSection(
                      'TestFlight Beta Program',
                      'If you participate in our TestFlight beta program:\n\n'
                          '• Apple may collect crash reports and usage analytics\n'
                          '• This data is handled according to Apple\'s privacy policy\n'
                          '• We may receive anonymized crash reports to improve the app\n'
                          '• No personal data or audio content is included in these reports',
                      isMobile,
                    ),
                    _buildSection(
                      'Third-Party Services',
                      'LiveCaptionsXR uses minimal third-party services:\n\n'
                          '• **Apple Speech Recognition**: Processes audio locally on device\n'
                          '• **ARKit**: Provides augmented reality features locally\n'
                          '• **Core ML**: Runs machine learning models locally\n\n'
                          'All processing occurs on-device without data transmission.',
                      isMobile,
                    ),
                    _buildSection(
                      'Children\'s Privacy',
                      'LiveCaptionsXR does not knowingly collect any information from children under 13. Since we don\'t collect personal data from any users, this extends to users of all ages.',
                      isMobile,
                    ),
                    _buildSection(
                      'Changes to This Policy',
                      'We may update this Privacy Policy from time to time. Any changes will be posted on this page and in our GitHub repository. We encourage you to review this policy periodically.',
                      isMobile,
                    ),
                    _buildSection(
                      'Contact Us',
                      'If you have questions about this Privacy Policy or our privacy practices:\n\n'
                          '• Create an issue on our GitHub repository\n'
                          '• Review our open-source code for transparency\n'
                          '• Contact the development team through GitHub\n\n'
                          'As an open-source project, we believe in transparency and welcome community oversight of our privacy practices.',
                      isMobile,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Footer CTA
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isMobile ? 24 : 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.1),
                      Theme.of(context).primaryColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.security_rounded,
                      size: 48,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Questions About Privacy?',
                      style: TextStyle(
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Review our open-source code or contact us through GitHub',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => context.go('/support'),
                          icon: const Icon(Icons.support_agent_rounded,
                              color: Colors.white),
                          label: const Text(
                            'Get Support',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
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

  Widget _buildPrivacyHighlight(String title, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content, bool isMobile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
