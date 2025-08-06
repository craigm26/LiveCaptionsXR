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
  late AnimationController _staggerController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _staggerAnimation;

  // Track hover states for interactive elements
  final Map<String, bool> _hoverStates = {};

  @override
  void initState() {
    super.initState();

    // Enhanced animation setup with staggered effects
    _fadeController = AnimationController(
      duration: WebPerformanceConfig.normalAnimationDuration,
      vsync: this,
    );
    _slideController = AnimationController(
      duration: WebPerformanceConfig.slowAnimationDuration,
      vsync: this,
    );
    _staggerController = AnimationController(
      duration: WebPerformanceConfig.slowAnimationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _staggerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _staggerController, curve: Curves.easeOutCubic),
    );

    // Start animations with optimized timing
    _fadeController.forward();
    Future.delayed(WebPerformanceConfig.fastAnimationDuration, () {
      if (mounted) {
        _slideController.forward();
      }
    });
    Future.delayed(WebPerformanceConfig.normalAnimationDuration, () {
      if (mounted) {
        _staggerController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = ResponsiveUtils.getScreenSize(context);
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const NavBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroSection(context, screenSize),
                      SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
                      _buildSupportGrid(context, screenSize),
                      SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
                      _buildFAQSection(context, screenSize),
                      SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
                      _buildDeveloperDocsSection(context, screenSize),
                      SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
                      _buildCommunitySection(context, screenSize),
                      SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
                      _buildContactSection(context, screenSize),
                      SizedBox(height: 40), // Bottom padding
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _staggerAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _staggerAnimation.value)),
          child: Opacity(
            opacity: _staggerAnimation.value,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(isMobile ? 24 : isTablet ? 32 : 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.primaryColor.withValues(alpha: 0.08),
                    theme.primaryColor.withValues(alpha: 0.03),
                    Colors.white.withValues(alpha: 0.9),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: isMobile 
                ? _buildMobileHeroContent(context, screenSize, theme)
                : _buildDesktopHeroContent(context, screenSize, theme),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileHeroContent(BuildContext context, ScreenSize screenSize, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.primaryColor.withValues(alpha: 0.2),
            ),
          ),
          child: Icon(
            Icons.support_agent_rounded,
            size: 32,
            color: theme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Support & Help',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Get help with Live Captions XR and connect with our community',
          style: TextStyle(
            fontSize: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopHeroContent(BuildContext context, ScreenSize screenSize, ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(screenSize == ScreenSize.tablet ? 20 : 24),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.primaryColor.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.support_agent_rounded,
            size: screenSize == ScreenSize.tablet ? 40 : 48,
            color: theme.primaryColor,
          ),
        ),
        SizedBox(width: screenSize == ScreenSize.tablet ? 24 : 32),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Support & Help',
                style: TextStyle(
                  fontSize: screenSize == ScreenSize.tablet ? 32 : 36,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Get help with Live Captions XR and connect with our community',
                style: TextStyle(
                  fontSize: screenSize == ScreenSize.tablet ? 18 : 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSupportGrid(BuildContext context, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;
    
    return AnimatedBuilder(
      animation: _staggerAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _staggerAnimation.value)),
          child: Opacity(
            opacity: _staggerAnimation.value,
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isMobile ? 1 : isTablet ? 2 : 3,
              crossAxisSpacing: isMobile ? 16 : 20,
              mainAxisSpacing: isMobile ? 16 : 20,
              childAspectRatio: isMobile ? 2.0 : isTablet ? 2.3 : 2.6,
              children: [
                _buildSupportCard(
                  context,
                  key: const ValueKey('bug-report'),
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
                  key: const ValueKey('feature-request'),
                  icon: Icons.lightbulb_rounded,
                  title: 'Feature Requests',
                  description: 'Have an idea? Share your feature suggestions with our team.',
                  actionText: 'Submit Ideas',
                  onTap: () => WebInteractionHandler.safeButtonPress(
                    () async {
                      await TestFlightUtils.openGitHub();
                    },
                    context,
                  ),
                  gradient: [Colors.amber.shade400, Colors.amber.shade300],
                  screenSize: screenSize,
                ),
                _buildSupportCard(
                  context,
                  key: const ValueKey('contribute'),
                  icon: Icons.code_rounded,
                  title: 'Contribute',
                  description: 'Help build the future of accessible AR technology.',
                  actionText: 'View Source Code',
                  onTap: () => WebInteractionHandler.safeButtonPress(
                    () async {
                      await TestFlightUtils.openGitHub();
                    },
                    context,
                  ),
                  gradient: [Colors.green.shade400, Colors.green.shade300],
                  screenSize: screenSize,
                ),
                _buildSupportCard(
                  context,
                  key: const ValueKey('ios-beta'),
                  icon: Icons.apple_rounded,
                  title: 'iOS Beta Testing',
                  description: 'Join our TestFlight program to test new features early.',
                  actionText: 'Join TestFlight',
                  onTap: () => WebInteractionHandler.safeButtonPress(
                    () async {
                      await TestFlightUtils.openTestFlight();
                    },
                    context,
                  ),
                  gradient: [Colors.blue.shade400, Colors.blue.shade300],
                  screenSize: screenSize,
                ),
                _buildSupportCard(
                  context,
                  key: const ValueKey('android-beta'),
                  icon: Icons.android_rounded,
                  title: 'Android Beta Testing',
                  description: 'Join our Google Play Beta program to test new features early.',
                  actionText: 'Join Beta',
                  onTap: () => WebInteractionHandler.safeButtonPress(
                    () async {
                      await GooglePlayUtils.openGooglePlayBeta();
                    },
                    context,
                  ),
                  gradient: [Colors.green.shade400, Colors.green.shade300],
                  screenSize: screenSize,
                ),
                _buildSupportCard(
                  context,
                  key: const ValueKey('docs'),
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
                  key: const ValueKey('setup'),
                  icon: Icons.build_rounded,
                  title: 'Setup Guide',
                  description: 'Step-by-step instructions for setting up the development environment and contributing.',
                  actionText: 'Get Started',
                  onTap: () => context.go('/docs'),
                  gradient: [Colors.teal.shade400, Colors.teal.shade300],
                  screenSize: screenSize,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSupportCard(
    BuildContext context, {
    Key? key,
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
    final theme = Theme.of(context);
    final cardKey = key ?? ValueKey(title);
    
    return StatefulBuilder(
      key: cardKey,
      builder: (context, setState) {
        final isHovered = _hoverStates[cardKey.toString()] ?? false;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isHovered 
                ? gradient.first.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.1),
              width: isHovered ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isHovered 
                  ? gradient.first.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.1),
                blurRadius: isHovered ? 15 : 10,
                offset: Offset(0, isHovered ? 6 : 4),
                spreadRadius: isHovered ? 2 : 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              onHover: (hovered) {
                setState(() {
                  _hoverStates[cardKey.toString()] = hovered;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.all(isMobile ? 10 : 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: gradient.first.withValues(alpha: 0.3),
                                blurRadius: isHovered ? 8 : 4,
                                offset: Offset(0, isHovered ? 3 : 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: isMobile ? 20 : 24,
                          ),
                        ),
                        SizedBox(width: isMobile ? 12 : 16),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: -0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    Expanded(
                      child: Text(
                        description,
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          height: 1.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: isMobile ? 3 : 4,
                      ),
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: Row(
                        children: [
                          Text(
                            actionText,
                            style: TextStyle(
                              fontSize: isMobile ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: isHovered ? gradient.first : gradient.first.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(width: 4),
                                                     AnimatedContainer(
                             duration: const Duration(milliseconds: 200),
                             transform: Matrix4.translationValues(
                               isHovered ? 4 : 0,
                               0,
                               0,
                             ),
                             child: Icon(
                               Icons.arrow_forward_rounded,
                               size: isMobile ? 16 : 18,
                               color: isHovered ? gradient.first : gradient.first.withValues(alpha: 0.8),
                             ),
                           ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFAQSection(BuildContext context, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _staggerAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 40 * (1 - _staggerAnimation.value)),
          child: Opacity(
            opacity: _staggerAnimation.value,
            child: Container(
              padding: EdgeInsets.all(isMobile ? 24 : 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.surface,
                    theme.colorScheme.surface.withValues(alpha: 0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isMobile ? 10 : 12),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.primaryColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Icon(
                          Icons.help_outline_rounded,
                          size: isMobile ? 24 : 28,
                          color: theme.primaryColor,
                        ),
                      ),
                      SizedBox(width: isMobile ? 12 : 16),
                      Expanded(
                        child: Text(
                          'Frequently Asked Questions',
                          style: TextStyle(
                            fontSize: isMobile ? 22 : isTablet ? 26 : 28,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 20 : 24),
                  _buildFAQItem(
                    'What is Live Captions XR?',
                    'Live Captions XR is an AR app that provides real-time captions in 3D space, helping deaf and hard-of-hearing individuals identify who is speaking and what they\'re saying.',
                    screenSize,
                    theme,
                  ),
                  _buildFAQItem(
                    'How do I join the beta program?',
                    'You can join our beta programs by clicking the iOS TestFlight or Android Beta buttons. This gives you early access to new features and helps us improve the app.',
                    screenSize,
                    theme,
                  ),
                  _buildFAQItem(
                    'Is the app free?',
                    'Yes! Live Captions XR is completely free and open-source. Our mission is to make accessibility technology available to everyone.',
                    screenSize,
                    theme,
                  ),
                  _buildFAQItem(
                    'What devices are supported?',
                    'We support iOS devices with ARKit capability and Android devices. We\'re working on expanding to more platforms including Android XR headsets in the future.',
                    screenSize,
                    theme,
                  ),
                  _buildFAQItem(
                    'How can I contribute to the project?',
                    'As an open-source project, we welcome contributions! You can contribute code, report bugs, suggest features, or help with documentation on our GitHub repository.',
                    screenSize,
                    theme,
                  ),
                  _buildFAQItem(
                    'What technologies does Live Captions XR use?',
                    'We use Flutter for cross-platform development, ARKit/ARCore for AR features, platform-specific speech recognition (Apple Speech Recognition on iOS, whisper_ggml on Android), Gemma 3n for AI processing, and various native plugins for audio processing.',
                    screenSize,
                    theme,
                  ),
                  _buildFAQItem(
                    'How do I set up the development environment?',
                    'You\'ll need Flutter SDK, Xcode (for iOS development), Android Studio, and the necessary dependencies. Check our detailed setup guide in the Developer Resources section.',
                    screenSize,
                    theme,
                  ),
                  _buildFAQItem(
                    'Can I integrate Live Captions XR into my own app?',
                    'Yes! Live Captions XR is open-source and can be integrated into other applications. Check our technical documentation and integration guides for details.',
                    screenSize,
                    theme,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFAQItem(String question, String answer, ScreenSize screenSize, ThemeData theme) {
    final isMobile = screenSize == ScreenSize.mobile;
    
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 16 : 20),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.question_mark_rounded,
                  size: 16,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question,
                  style: TextStyle(
                    fontSize: isMobile ? 15 : 16,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Padding(
            padding: EdgeInsets.only(left: 36),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
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
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _staggerAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _staggerAnimation.value)),
          child: Opacity(
            opacity: _staggerAnimation.value,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(isMobile ? 24 : isTablet ? 32 : 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.primaryColor.withValues(alpha: 0.08),
                    theme.primaryColor.withValues(alpha: 0.03),
                    Colors.white.withValues(alpha: 0.95),
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.primaryColor.withValues(alpha: 0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isMobile ? 12 : 16),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.primaryColor.withValues(alpha: 0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primaryColor.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.people_rounded,
                          size: isMobile ? 32 : 40,
                          color: theme.primaryColor,
                        ),
                      ),
                      SizedBox(width: isMobile ? 16 : 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Join Our Community',
                              style: TextStyle(
                                fontSize: isMobile ? 22 : isTablet ? 26 : 30,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: isMobile ? 6 : 8),
                            Text(
                              'Connect with other users, share feedback, and stay updated on the latest developments.',
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 20 : 24),
                  _buildCommunityButton(context, screenSize, theme),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommunityButton(BuildContext context, ScreenSize screenSize, ThemeData theme) {
    final isMobile = screenSize == ScreenSize.mobile;
    
    return StatefulBuilder(
      builder: (context, setState) {
        final isHovered = _hoverStates['community-button'] ?? false;
        
        return MouseRegion(
          onEnter: (_) => setState(() => _hoverStates['community-button'] = true),
          onExit: (_) => setState(() => _hoverStates['community-button'] = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: ElevatedButton.icon(
              onPressed: () => WebInteractionHandler.safeButtonPress(
                () async {
                  await TestFlightUtils.openGitHub();
                },
                context,
              ),
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: Matrix4.translationValues(
                  isHovered ? -2 : 0,
                  0,
                  0,
                ),
                child: Icon(
                  Icons.code,
                  color: Colors.white,
                  size: isMobile ? 18 : 20,
                ),
              ),
              label: Text(
                'View on GitHub',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 13 : 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isHovered 
                  ? theme.primaryColor.withValues(alpha: 0.9)
                  : theme.primaryColor,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 28,
                  vertical: isMobile ? 14 : 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: isHovered ? 8 : 4,
                shadowColor: theme.primaryColor.withValues(alpha: 0.3),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactSection(BuildContext context, ScreenSize screenSize) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _staggerAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 60 * (1 - _staggerAnimation.value)),
          child: Opacity(
            opacity: _staggerAnimation.value,
            child: Container(
              padding: EdgeInsets.all(isMobile ? 24 : isTablet ? 32 : 40),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.primaryColor.withValues(alpha: 0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isMobile ? 10 : 12),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.primaryColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Icon(
                          Icons.contact_support_rounded,
                          size: isMobile ? 24 : 28,
                          color: theme.primaryColor,
                        ),
                      ),
                      SizedBox(width: isMobile ? 12 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Need More Help?',
                              style: TextStyle(
                                fontSize: isMobile ? 22 : isTablet ? 26 : 28,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: isMobile ? 4 : 6),
                            Text(
                              'Can\'t find what you\'re looking for? We\'re here to help!',
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 20 : 24),
                  Wrap(
                    spacing: isMobile ? 12 : 16,
                    runSpacing: isMobile ? 12 : 16,
                    children: [
                      _buildContactCard(
                        context,
                        Icons.email_rounded,
                        'GitHub Issues',
                        'Create an issue on GitHub for technical support',
                        screenSize,
                        theme,
                      ),
                      _buildContactCard(
                        context,
                        Icons.description_rounded,
                        'Documentation',
                        'Check our comprehensive docs and guides',
                        screenSize,
                        theme,
                      ),
                      _buildContactCard(
                        context,
                        Icons.code_rounded,
                        'Developer Chat',
                        'Join our developer community discussions',
                        screenSize,
                        theme,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    ScreenSize screenSize,
    ThemeData theme,
  ) {
    final isMobile = screenSize == ScreenSize.mobile;
    
    return StatefulBuilder(
      builder: (context, setState) {
        final isHovered = _hoverStates['contact-$title'] ?? false;
        
        return MouseRegion(
          onEnter: (_) => setState(() => _hoverStates['contact-$title'] = true),
          onExit: (_) => setState(() => _hoverStates['contact-$title'] = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isMobile ? double.infinity : 280,
            padding: EdgeInsets.all(isMobile ? 20 : 24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isHovered 
                  ? theme.primaryColor.withValues(alpha: 0.3)
                  : theme.primaryColor.withValues(alpha: 0.1),
                width: isHovered ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isHovered 
                    ? theme.primaryColor.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.05),
                  blurRadius: isHovered ? 12 : 8,
                  offset: Offset(0, isHovered ? 4 : 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(isMobile ? 12 : 14),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor.withValues(alpha: 0.2),
                        blurRadius: isHovered ? 8 : 4,
                        offset: Offset(0, isHovered ? 3 : 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: theme.primaryColor,
                    size: isMobile ? 24 : 28,
                  ),
                ),
                SizedBox(height: isMobile ? 12 : 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: isMobile ? 6 : 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class WebInteractionHandler {
  static void safeButtonPress(Future<void> Function() action, BuildContext context) async {
    try {
      await action();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Action failed: ${e.toString()}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
