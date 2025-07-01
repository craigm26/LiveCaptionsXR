import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Permission requests will be implemented natively or elsewhere. No permission_handler import.

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLastPage = false;

  final List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      title: 'Welcome to LiveCaptionsXR',
      description: 'See real-time captions anchored in AR. We use audio, vision, and motion sensors to place captions in your space.',
      imageAsset: Icons.spatial_audio,
    ),
    _OnboardingPageData(
      title: 'Spatial Anchoring',
      description: 'Captions follow the speaker in 3D space using advanced localization. You always know who is speaking.',
      imageAsset: Icons.anchor,
    ),
    _OnboardingPageData(
      title: 'Permissions Needed',
      description: 'We need access to your camera, microphone, and motion sensors to enable AR captioning.',
      imageAsset: Icons.privacy_tip,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _requestPermissions() async {
    // TODO: Implement permission requests natively or in the appropriate platform-specific layer.
    // This is a placeholder for where permission requests should occur.
    return;
  }

  void _onContinue() async {
    if (_currentPage == _pages.length - 1) {
      await _requestPermissions();
      await _completeOnboarding();
    } else {
      _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
          Text(title, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(description, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
