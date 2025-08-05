import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/app_logger.dart';
// Permission requests will be implemented natively or elsewhere. No permission_handler import.

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final AppLogger _logger = AppLogger.instance;

  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLastPage = false;

  final List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      title: 'Welcome to LiveCaptionsXR',
      description:
          'See real-time captions anchored in AR. We use audio, vision, and motion sensors to place captions in your space.',
      imageAsset: Icons.spatial_audio,
    ),
    _OnboardingPageData(
      title: 'Spatial Anchoring',
      description:
          'Captions follow the speaker in 3D space using advanced localization. You always know who is speaking.',
      imageAsset: Icons.anchor,
    ),
    _OnboardingPageData(
      title: 'Permissions Needed',
      description:
          'We need access to your camera, microphone, and motion sensors to enable AR captioning.',
      imageAsset: Icons.privacy_tip,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _logger.i('🎯 OnboardingScreen initialized with ${_pages.length} pages', category: LogCategory.ui);
  }

  @override
  void dispose() {
    _logger.i('🗑️ OnboardingScreen disposing...', category: LogCategory.ui);
    _pageController.dispose();
    super.dispose();
    _logger.d('✅ OnboardingScreen disposed successfully', category: LogCategory.ui);
  }

  Future<void> _completeOnboarding() async {
    try {
      _logger.i('✅ Completing onboarding process...', category: LogCategory.ui);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);
      _logger.i('✅ Onboarding completion flag saved to SharedPreferences', category: LogCategory.ui);

      if (mounted) {
        Navigator.of(context).pop();
        _logger.i('🏠 Navigated back to main app after onboarding completion', category: LogCategory.ui);
      } else {
        _logger.w('⚠️ Widget not mounted, skipping navigation after onboarding', category: LogCategory.ui);
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Error completing onboarding', category: LogCategory.ui, error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _requestPermissions() async {
    try {
      _logger.i('🔐 Requesting permissions for AR captioning...', category: LogCategory.ui);
      // TODO: Implement permission requests natively or in the appropriate platform-specific layer.
      // This is a placeholder for where permission requests should occur.
      _logger.d('📝 Permission request placeholder - implement native permission requests', category: LogCategory.ui);
      return;
    } catch (e, stackTrace) {
      _logger.e('❌ Error requesting permissions', category: LogCategory.ui, error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  void _onContinue() async {
    try {
      _logger.d('👆 Continue button pressed on page ${_currentPage + 1}/${_pages.length}', category: LogCategory.ui);

      if (_currentPage == _pages.length - 1) {
        _logger.i('🏁 Reached final onboarding page - completing onboarding...', category: LogCategory.ui);
        await _requestPermissions();
        await _completeOnboarding();
      } else {
        _logger.d('📖 Advancing to next onboarding page...', category: LogCategory.ui);
        _pageController.nextPage(
            duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
        _logger.d('✅ Page transition initiated successfully', category: LogCategory.ui);
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Error in onboarding continue action', category: LogCategory.ui, error: e, stackTrace: stackTrace);
    }
  }

  void _onSkip() async {
    await _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                    _isLastPage = index == _pages.length - 1;
                  });
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _OnboardingPage(
                    title: page.title,
                    description: page.description,
                    imageAsset: page.imageAsset,
                  );
                },
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _onSkip,
                    child: const Text('Skip'),
                  ),
                  ElevatedButton(
                    onPressed: _onContinue,
                    child: Text(_isLastPage ? 'Get Started' : 'Continue'),
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

class _OnboardingPageData {
  final String title;
  final String description;
  final IconData imageAsset;

  _OnboardingPageData({
    required this.title,
    required this.description,
    required this.imageAsset,
  });
}

class _OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final IconData imageAsset;

  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.imageAsset,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(imageAsset, size: 120),
          const SizedBox(height: 32),
          Text(title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(description,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
