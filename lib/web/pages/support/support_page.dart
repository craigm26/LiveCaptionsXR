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
    final screenSize = ResponsiveUtils.getScreenSize(context);
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return Scaffold(
      appBar: const NavBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroSection(context, screenSize),
                SizedBox(height: isMobile ? 24 : 32),
                _buildSupportGrid(context, screenSize),
                SizedBox(height: isMobile ? 24 : 32),
                _buildFAQSection(context, screenSize),
                SizedBox(height: isMobile ? 24 : 32),
                _buildDeveloperDocsSection(context, screenSize),
                SizedBox(height: isMobile ? 24 : 32),
                _buildCommunitySection(context, screenSize),
                SizedBox(height: isMobile ? 24 : 32),
                _buildContactSection(context, screenSize),
              ],
            ),
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
      padding: EdgeInsets.all(isMobile ? 20 : isTablet ? 28 : 36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
            Theme.of(context).primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
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
              Icons.support_agent_rounded,
              size: isMobile ? 32 : isTablet ? 36 : 40,
              color: Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(width: isMobile ? 16 : 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Support & Help',
                  style: TextStyle(
                    fontSize: isMobile ? 24 : isTablet ? 28 : 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: isMobile ? 6 : 8),
                Text(
                  'Get help with Live Captions XR and connect with our community',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : isTablet ? 16 : 18,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportGrid(BuildContext context, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 1 : isTablet ? 2 : 3,
      crossAxisSpacing: isMobile ? 12 : 16,
      mainAxisSpacing: isMobile ? 12 : 16,
      childAspectRatio: isMobile ? 2.2 : isTablet ? 2.5 : 2.8,
      children: [
        _buildSupportCard(
          context,
          icon: Icons.bug_report_rounded,
          title: 'Report a Bug',
          description: 'Found an issue? Help us improve by reporting bugs on GitHub.',
          actionText: 'Open GitHub Issues',
          onTap: () => WebInteractionHandler.safeButtonPress(
            () async {
              await TestFlightUtils.openGitHub();
            },
            context,
          ),
          gradient: [Colors.red.shade400, Colors.red.shade300],
          screenSize: screenSize,
        ),
        _buildSupportCard(
          context,
          icon: Icons.lightbulb_rounded,
          title: 'Feature Requests',
          description: 'Have an idea? Share your feature suggestions with our team.',
          actionText: 'Submit Ideas',
          onTap: () async {
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
          gradient: [Colors.amber.shade400, Colors.amber.shade300],
          screenSize: screenSize,
        ),
        _buildSupportCard(
          context,
          icon: Icons.code_rounded,
          title: 'Contribute',
          description: 'Help build the future of accessible AR technology.',
          actionText: 'View Source Code',
          onTap: () async {
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
          gradient: [Colors.green.shade400, Colors.green.shade300],
          screenSize: screenSize,
        ),
        _buildSupportCard(
          context,
          icon: Icons.apple_rounded,
          title: 'iOS Beta Testing',
          description: 'Join our TestFlight program to test new features early.',
          actionText: 'Join TestFlight',
          onTap: () async {
            try {
              await TestFlightUtils.openTestFlight();
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not open TestFlight: $e')),
                );
              }
            }
          },
          gradient: [Colors.blue.shade400, Colors.blue.shade300],
          screenSize: screenSize,
        ),
        _buildSupportCard(
          context,
          icon: Icons.android_rounded,
          title: 'Android Beta Testing',
          description: 'Join our Google Play Beta program to test new features early.',
          actionText: 'Join Beta',
          onTap: () async {
            try {
              await GooglePlayUtils.openGooglePlayBeta();
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not open Google Play Beta: $e')),
                );
              }
            }
          },
          gradient: [Colors.green.shade400, Colors.green.shade300],
          screenSize: screenSize,
        ),
        _buildSupportCard(
          context,
          icon: Icons.description_rounded,
          title: 'Technical Documentation',
          description: 'Comprehensive guides for developers, setup instructions, and architecture documentation.',
          actionText: 'View Docs',
          onTap: () => context.go('/docs'),
          gradient: [Colors.indigo.shade400, Colors.indigo.shade300],
          screenSize: screenSize,
        ),
        _buildSupportCard(
          context,
          icon: Icons.build_rounded,
          title: 'Setup Guide',
          description: 'Step-by-step instructions for setting up the development environment and contributing.',
          actionText: 'Get Started',
          onTap: () => context.go('/docs'),
          gradient: [Colors.teal.shade400, Colors.teal.shade300],
          screenSize: screenSize,
        ),
      ],
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
    required ScreenSize screenSize,
  }) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;
    
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
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isMobile ? 8 : 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradient),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: isMobile ? 18 : 20,
                      ),
                    ),
                    SizedBox(width: isMobile ? 10 : 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 8 : 10),
                Expanded(
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 13,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: isMobile ? 2 : 3,
                  ),
                ),
                SizedBox(height: isMobile ? 6 : 8),
                Row(
                  children: [
                    Text(
                      actionText,
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 14,
                        fontWeight: FontWeight.w600,
                        color: gradient.first,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: isMobile ? 14 : 16,
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

  Widget _buildFAQSection(BuildContext context, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
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
              fontSize: isMobile ? 20 : isTablet ? 24 : 26,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: isMobile ? 16 : 20),
          _buildFAQItem(
            'What is Live Captions XR?',
            'Live Captions XR is an AR app that provides real-time captions in 3D space, helping deaf and hard-of-hearing individuals identify who is speaking and what they\'re saying.',
            screenSize,
          ),
          _buildFAQItem(
            'How do I join the beta program?',
            'You can join our beta programs by clicking the iOS TestFlight or Android Beta buttons. This gives you early access to new features and helps us improve the app.',
            screenSize,
          ),
          _buildFAQItem(
            'Is the app free?',
            'Yes! Live Captions XR is completely free and open-source. Our mission is to make accessibility technology available to everyone.',
            screenSize,
          ),
          _buildFAQItem(
            'What devices are supported?',
            'We support iOS devices with ARKit capability and Android devices. We\'re working on expanding to more platforms including Android XR headsets in the future.',
            screenSize,
          ),
          _buildFAQItem(
            'How can I contribute to the project?',
            'As an open-source project, we welcome contributions! You can contribute code, report bugs, suggest features, or help with documentation on our GitHub repository.',
            screenSize,
          ),
          _buildFAQItem(
            'What technologies does Live Captions XR use?',
            'We use Flutter for cross-platform development, ARKit/ARCore for AR features, platform-specific speech recognition (Apple Speech Recognition on iOS, whisper_ggml on Android), Gemma 3n for AI processing, and various native plugins for audio processing.',
            screenSize,
          ),
          _buildFAQItem(
            'How do I set up the development environment?',
            'You\'ll need Flutter SDK, Xcode (for iOS development), Android Studio, and the necessary dependencies. Check our detailed setup guide in the Developer Resources section.',
            screenSize,
          ),
          _buildFAQItem(
            'Can I integrate Live Captions XR into my own app?',
            'Yes! Live Captions XR is open-source and can be integrated into other applications. Check our technical documentation and integration guides for details.',
            screenSize,
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 10 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              fontSize: isMobile ? 14 : 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: isMobile ? 4 : 6),
          Text(
            answer,
            style: TextStyle(
              fontSize: isMobile ? 12 : 13,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperDocsSection(BuildContext context, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
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
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.code_rounded,
                  size: isMobile ? 20 : 24,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              SizedBox(width: isMobile ? 10 : 12),
              Text(
                'Developer Resources',
                style: TextStyle(
                  fontSize: isMobile ? 20 : isTablet ? 24 : 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            'Comprehensive documentation and guides for developers who want to contribute to Live Captions XR or integrate with our technology.',
            style: TextStyle(
              fontSize: isMobile ? 13 : 15,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          SizedBox(height: isMobile ? 20 : 24),
          
          // Documentation Categories
          Wrap(
            spacing: isMobile ? 8 : 12,
            runSpacing: isMobile ? 8 : 12,
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
                screenSize,
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
                screenSize,
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
                screenSize,
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
                screenSize,
              ),
            ],
          ),
          
          SizedBox(height: isMobile ? 20 : 24),
          
          // Quick Start Guide
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
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
                    Container(
                      padding: EdgeInsets.all(isMobile ? 6 : 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.rocket_launch_rounded,
                        color: Theme.of(context).primaryColor,
                        size: isMobile ? 16 : 18,
                      ),
                    ),
                    SizedBox(width: isMobile ? 6 : 8),
                    Text(
                      'Quick Start for Contributors',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 10 : 12),
                _buildQuickStartStep(
                  '1. Fork the Repository',
                  'Start by forking the LiveCaptionsXR repository on GitHub',
                  screenSize,
                ),
                _buildQuickStartStep(
                  '2. Clone Your Fork',
                  'Clone your forked repository to your local machine',
                  screenSize,
                ),
                _buildQuickStartStep(
                  '3. Set Up Development Environment',
                  'Install Flutter, Xcode (for iOS), and Android Studio',
                  screenSize,
                ),
                _buildQuickStartStep(
                  '4. Install Dependencies',
                  'Run `flutter pub get` to install all required packages',
                  screenSize,
                ),
                _buildQuickStartStep(
                  '5. Run the App',
                  'Use `flutter run` to start the development server',
                  screenSize,
                ),
                _buildQuickStartStep(
                  '6. Make Changes',
                  'Create a feature branch and implement your changes',
                  screenSize,
                ),
                _buildQuickStartStep(
                  '7. Submit a Pull Request',
                  'Create a pull request with a detailed description of your changes',
                  screenSize,
                ),
                SizedBox(height: isMobile ? 12 : 16),
                ElevatedButton.icon(
                  onPressed: () => context.go('/docs'),
                  icon: const Icon(Icons.code, color: Colors.white),
                  label: Text(
                    'View Full Setup Guide',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: isMobile ? 12 : 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 24,
                      vertical: isMobile ? 12 : 16,
                    ),
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
    ScreenSize screenSize,
  ) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;
    
    return Container(
      width: isMobile ? double.infinity : isTablet ? 280 : 320,
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
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 8 : 10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: isMobile ? 18 : 20,
                  ),
                ),
                SizedBox(height: isMobile ? 6 : 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: isMobile ? 2 : 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
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

  Widget _buildQuickStartStep(String title, String description, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isMobile ? 20 : 24,
            height: isMobile ? 20 : 24,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
            ),
            child: Center(
              child: Text(
                title.split(' ').first,
                style: TextStyle(
                  fontSize: isMobile ? 10 : 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
          SizedBox(width: isMobile ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: isMobile ? 2 : 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 13,
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

  Widget _buildCommunitySection(BuildContext context, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : isTablet ? 28 : 32),
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
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 10 : 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.people_rounded,
                  size: isMobile ? 32 : 36,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Join Our Community',
                      style: TextStyle(
                        fontSize: isMobile ? 20 : isTablet ? 24 : 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: isMobile ? 4 : 6),
                    Text(
                      'Connect with other users, share feedback, and stay updated on the latest developments.',
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 16,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),
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
            label: Text(
              'View on GitHub',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 12 : 14,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
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

  Widget _buildContactSection(BuildContext context, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : isTablet ? 28 : 32),
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
              fontSize: isMobile ? 20 : isTablet ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Text(
            'Can\'t find what you\'re looking for? We\'re here to help!',
            style: TextStyle(
              fontSize: isMobile ? 13 : 16,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          SizedBox(height: isMobile ? 16 : 20),
          Wrap(
            spacing: isMobile ? 8 : 12,
            runSpacing: isMobile ? 8 : 12,
            children: [
              _buildContactCard(
                context,
                Icons.email_rounded,
                'GitHub Issues',
                'Create an issue on GitHub for technical support',
                screenSize,
              ),
              _buildContactCard(
                context,
                Icons.description_rounded,
                'Documentation',
                'Check our comprehensive docs and guides',
                screenSize,
              ),
              _buildContactCard(
                context,
                Icons.code_rounded,
                'Developer Chat',
                'Join our developer community discussions',
                screenSize,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    ScreenSize screenSize,
  ) {
    final isMobile = screenSize == ScreenSize.mobile;
    
    return Container(
      width: isMobile ? double.infinity : 280,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
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
          SizedBox(height: isMobile ? 8 : 12),
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isMobile ? 4 : 8),
          Text(
            description,
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              color: Colors.grey[600],
            ),
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
