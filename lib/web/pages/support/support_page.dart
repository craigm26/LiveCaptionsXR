import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/nav_bar.dart';
import '../../utils/testflight_utils.dart';
import '../../utils/google_play_utils.dart';
import '../../utils/github_docs_utils.dart';
import '../../config/web_performance_config.dart';
import '../../utils/responsive_utils.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Use optimized durations from performance config
    _fadeController = AnimationController(
      duration: WebPerformanceConfig.normalAnimationDuration,
      vsync: this,
    );
    _slideController = AnimationController(
      duration: WebPerformanceConfig.slowAnimationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    // Start animations with optimized delay
    _fadeController.forward();
    Future.delayed(WebPerformanceConfig.fastAnimationDuration, () {
      if (mounted) {
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final String location = GoRouterState.of(context).uri.toString();

    return Scaffold(
      appBar: const NavBar(),

      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Section
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isMobile ? 24 : 48), // Reduced padding
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        Theme.of(context).primaryColor.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.support_agent_rounded,
                        size: isMobile ? 36 : 48, // Reduced icon size
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 16), // Reduced spacing
                      Text(
                        'Support & Help',
                        style: TextStyle(
                          fontSize: isMobile ? 28 : 40, // Reduced font size
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12), // Reduced spacing
                      Text(
                        'Get help with Live Captions XR and connect with our community',
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 20,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32), // Reduced spacing

                // Support Options Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isMobile ? 1 : 2,
                  crossAxisSpacing: 16, // Reduced spacing
                  mainAxisSpacing: 16, // Reduced spacing
                  childAspectRatio: isMobile ? 1.4 : 1.8, // Increased aspect ratio for more compact cards
                  children: [
                    _buildSupportCard(
                      context,
                      icon: Icons.bug_report_rounded,
                      title: 'Report a Bug',
                      description:
                          'Found an issue? Help us improve by reporting bugs on GitHub.',
                      actionText: 'Open GitHub Issues',
                      onTap: () => WebInteractionHandler.safeButtonPress(
                        () async {
                          await TestFlightUtils.openGitHub();
                        },
                        context,
                      ),
                      gradient: [Colors.red.shade400, Colors.red.shade300],
                    ),
                    _buildSupportCard(
                      context,
                      icon: Icons.lightbulb_rounded,
                      title: 'Feature Requests',
                      description:
                          'Have an idea? Share your feature suggestions with our team.',
                      actionText: 'Submit Ideas',
                      onTap: () async {
                        try {
                          await TestFlightUtils.openGitHub();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Could not open GitHub: $e')),
                            );
                          }
                        }
                      },
                      gradient: [Colors.amber.shade400, Colors.amber.shade300],
                    ),
                    _buildSupportCard(
                      context,
                      icon: Icons.code_rounded,
                      title: 'Contribute',
                      description:
                          'Help build the future of accessible AR technology.',
                      actionText: 'View Source Code',
                      onTap: () async {
                        try {
                          await TestFlightUtils.openGitHub();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Could not open GitHub: $e')),
                            );
                          }
                        }
                      },
                      gradient: [Colors.green.shade400, Colors.green.shade300],
                    ),
                    _buildSupportCard(
                      context,
                      icon: Icons.apple_rounded,
                      title: 'iOS Beta Testing',
                      description:
                          'Join our TestFlight program to test new features early.',
                      actionText: 'Join TestFlight',
                      onTap: () async {
                        try {
                          await TestFlightUtils.openTestFlight();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Could not open TestFlight: $e')),
                            );
                          }
                        }
                      },
                      gradient: [Colors.blue.shade400, Colors.blue.shade300],
                    ),
                    _buildSupportCard(
                      context,
                      icon: Icons.android_rounded,
                      title: 'Android Beta Testing',
                      description:
                          'Join our Google Play Beta program to test new features early.',
                      actionText: 'Join Beta',
                      onTap: () async {
                        try {
                          await GooglePlayUtils.openGooglePlayBeta();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Could not open Google Play Beta: $e')),
                            );
                          }
                        }
                      },
                      gradient: [Colors.green.shade400, Colors.green.shade300],
                    ),
                    _buildSupportCard(
                      context,
                      icon: Icons.description_rounded,
                      title: 'Technical Documentation',
                      description:
                          'Comprehensive guides for developers, setup instructions, and architecture documentation.',
                      actionText: 'View Docs',
                      onTap: () => context.go('/docs'),
                      gradient: [Colors.indigo.shade400, Colors.indigo.shade300],
                    ),
                    _buildSupportCard(
                      context,
                      icon: Icons.build_rounded,
                      title: 'Setup Guide',
                      description:
                          'Step-by-step instructions for setting up the development environment and contributing.',
                      actionText: 'Get Started',
                      onTap: () => context.go('/docs'),
                      gradient: [Colors.teal.shade400, Colors.teal.shade300],
                    ),
                  ],
                ),

                const SizedBox(height: 32), // Reduced spacing

                // FAQ Section
                _buildFAQSection(context, isMobile),

                const SizedBox(height: 32), // Reduced spacing

                // Developer Documentation Section
                _buildDeveloperDocsSection(context, isMobile),

                const SizedBox(height: 32), // Reduced spacing

                // Community Section
                _buildCommunitySection(context, isMobile),

                const SizedBox(height: 32), // Reduced spacing

                // Contact Section
                _buildContactSection(context, isMobile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSupportCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String actionText,
    required VoidCallback onTap,
    required List<Color> gradient,
  }) {
    return Container(
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
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16), // Reduced padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10), // Reduced padding
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20, // Reduced icon size
                  ),
                ),
                const SizedBox(height: 12), // Reduced spacing
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16, // Reduced font size
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6), // Reduced spacing
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13, // Reduced font size
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Text(
                      actionText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: gradient.first,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: gradient.first,
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

  Widget _buildFAQSection(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: isMobile ? 22 : 26, // Reduced font size
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 20), // Reduced spacing
          _buildFAQItem(
            'What is Live Captions XR?',
            'Live Captions XR is an AR app that provides real-time captions in 3D space, helping deaf and hard-of-hearing individuals identify who is speaking and what they\'re saying.',
          ),
          _buildFAQItem(
            'How do I join the beta program?',
            'You can join our beta programs by clicking the iOS TestFlight or Android Beta buttons. This gives you early access to new features and helps us improve the app.',
          ),
          _buildFAQItem(
            'Is the app free?',
            'Yes! Live Captions XR is completely free and open-source. Our mission is to make accessibility technology available to everyone.',
          ),
          _buildFAQItem(
            'What devices are supported?',
            'We support iOS devices with ARKit capability and Android devices. We\'re working on expanding to more platforms including Android XR headsets in the future.',
          ),
          _buildFAQItem(
            'How can I contribute to the project?',
            'As an open-source project, we welcome contributions! You can contribute code, report bugs, suggest features, or help with documentation on our GitHub repository.',
          ),
          _buildFAQItem(
            'What technologies does Live Captions XR use?',
            'We use Flutter for cross-platform development, ARKit/ARCore for AR features, platform-specific speech recognition (Apple Speech Recognition on iOS, whisper_ggml on Android), Gemma 3n for AI processing, and various native plugins for audio processing.',
          ),
          _buildFAQItem(
            'How do I set up the development environment?',
            'You\'ll need Flutter SDK, Xcode (for iOS development), Android Studio, and the necessary dependencies. Check our detailed setup guide in the Developer Resources section.',
          ),
          _buildFAQItem(
            'Can I integrate Live Captions XR into my own app?',
            'Yes! Live Captions XR is open-source and can be integrated into other applications. Check our technical documentation and integration guides for details.',
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Reduced margin
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 15, // Reduced font size
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6), // Reduced spacing
          Text(
            answer,
            style: TextStyle(
              fontSize: 13, // Reduced font size
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperDocsSection(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
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
              Icon(
                Icons.code_rounded,
                size: 28, // Reduced icon size
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 12), // Reduced spacing
              Text(
                'Developer Resources',
                style: TextStyle(
                  fontSize: isMobile ? 22 : 26, // Reduced font size
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20), // Reduced spacing
          Text(
            'Comprehensive documentation and guides for developers who want to contribute to Live Captions XR or integrate with our technology.',
            style: TextStyle(
              fontSize: 15, // Reduced font size
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24), // Reduced spacing
          
          // Documentation Categories
          Wrap(
            spacing: 12, // Reduced spacing
            runSpacing: 12, // Reduced spacing
            children: [
              _buildDocCategory(
                context,
                'Architecture',
                'System design, data flow, and technical architecture',
                Icons.architecture_rounded,
                Colors.blue,
                () async {
                  try {
                    await TestFlightUtils.openGitHub();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not open GitHub: $e')),
                      );
                    }
                  }
                },
              ),
              _buildDocCategory(
                context,
                'API Reference',
                'Complete API documentation and integration guides',
                Icons.api_rounded,
                Colors.green,
                () async {
                  try {
                    await TestFlightUtils.openGitHub();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not open GitHub: $e')),
                      );
                    }
                  }
                },
              ),
              _buildDocCategory(
                context,
                'Setup Guide',
                'Development environment setup and contribution workflow',
                Icons.settings_rounded,
                Colors.orange,
                () async {
                  try {
                    await TestFlightUtils.openGitHub();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not open GitHub: $e')),
                      );
                    }
                  }
                },
              ),
              _buildDocCategory(
                context,
                'Testing',
                'Testing strategies, test cases, and quality assurance',
                Icons.science_rounded,
                Colors.purple,
                () async {
                  try {
                    await TestFlightUtils.openGitHub();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not open GitHub: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24), // Reduced spacing
          
          // Quick Start Guide
          Container(
            padding: const EdgeInsets.all(20), // Reduced padding
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.rocket_launch_rounded,
                      color: Theme.of(context).primaryColor,
                      size: 20, // Reduced icon size
                    ),
                    const SizedBox(width: 8), // Reduced spacing
                    Text(
                      'Quick Start for Contributors',
                      style: TextStyle(
                        fontSize: 16, // Reduced font size
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12), // Reduced spacing
                _buildQuickStartStep(
                  '1. Fork the Repository',
                  'Start by forking the LiveCaptionsXR repository on GitHub',
                ),
                _buildQuickStartStep(
                  '2. Clone Your Fork',
                  'Clone your forked repository to your local machine',
                ),
                _buildQuickStartStep(
                  '3. Set Up Development Environment',
                  'Install Flutter, Xcode (for iOS), and Android Studio',
                ),
                _buildQuickStartStep(
                  '4. Install Dependencies',
                  'Run `flutter pub get` to install all required packages',
                ),
                _buildQuickStartStep(
                  '5. Run the App',
                  'Use `flutter run` to start the development server',
                ),
                _buildQuickStartStep(
                  '6. Make Changes',
                  'Create a feature branch and implement your changes',
                ),
                _buildQuickStartStep(
                  '7. Submit a Pull Request',
                  'Create a pull request with a detailed description of your changes',
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context.go('/docs'),
                  icon: const Icon(Icons.code, color: Colors.white),
                  label: const Text(
                    'View Full Setup Guide',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocCategory(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final isMobile = ResponsiveUtils.isMobile(context);
    return Container(
      width: isMobile ? double.infinity : 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16), // Reduced padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10), // Reduced padding
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20, // Reduced icon size
                  ),
                ),
                const SizedBox(height: 8), // Reduced spacing
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14, // Reduced font size
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4), // Reduced spacing
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12, // Reduced font size
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStartStep(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                title.split(' ').first,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunitySection(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
            Theme.of(context).primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.people_rounded,
            size: 48,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Join Our Community',
            style: TextStyle(
              fontSize: isMobile ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Connect with other users, share feedback, and stay updated on the latest developments. Our community is built on accessibility, inclusion, and collaboration.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await TestFlightUtils.openGitHub();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not open GitHub: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.code, color: Colors.white),
            label: const Text(
              'View on GitHub',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Need More Help?',
            style: TextStyle(
              fontSize: isMobile ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Can\'t find what you\'re looking for? We\'re here to help!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.email_rounded,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'GitHub Issues',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create an issue on GitHub for technical support',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.description_rounded,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Documentation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check our comprehensive docs and guides',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.code_rounded,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Developer Chat',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Join our developer community discussions',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
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

class WebInteractionHandler {
  static void safeButtonPress(Future<void> Function() action, dynamic context) async {
    try {
      await action();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open GitHub: $e')),
        );
      }
    }
  }
}
