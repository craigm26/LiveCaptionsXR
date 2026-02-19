import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/models/device_model_config.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final AppLogger _logger = AppLogger.instance;

  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLastPage = false;
  
  // Device detection
  bool _isLoading = true;
  bool _isNexaDevice = false;
  String _deviceType = 'Unknown';
  String _asrEngine = 'Unknown';
  String _llmEngine = 'Unknown';

  @override
  void initState() {
    super.initState();
    _logger.i('🎯 OnboardingScreen initialized', category: LogCategory.ui);
    _detectDevice();
  }

  Future<void> _detectDevice() async {
    try {
      if (kIsWeb) {
        _deviceType = 'Web Browser';
        _asrEngine = 'Not available';
        _llmEngine = 'Not available';
        _isNexaDevice = false;
      } else if (Platform.isIOS) {
        _deviceType = 'iOS Device';
        _asrEngine = 'Apple Speech (built-in)';
        _llmEngine = 'Gemma 3n (download required)';
        _isNexaDevice = false;
      } else if (Platform.isAndroid) {
        // Check for Nexa/Snapdragon NPU support
        final registry = DeviceModelRegistry();
        final config = await registry.getDeviceConfig();
        _isNexaDevice = config.asrModel.name.startsWith('parakeet');
        
        if (_isNexaDevice) {
          _deviceType = 'Snapdragon NPU Device';
          _asrEngine = 'Nexa Parakeet NPU (~600MB, downloads on first launch)';
          _llmEngine = 'Nexa Granite/OmniNeural (auto-download via SDK)';
        } else {
          _deviceType = 'Android Device';
          _asrEngine = 'Whisper (download required)';
          _llmEngine = 'Gemma 3n (download required)';
        }
      } else {
        _deviceType = 'Desktop';
        _asrEngine = 'Whisper (download required)';
        _llmEngine = 'Gemma 3n (download required)';
      }
      
      _logger.i('📱 Device detected: $_deviceType, Nexa: $_isNexaDevice', 
          category: LogCategory.system);
    } catch (e) {
      _logger.w('⚠️ Device detection failed: $e', category: LogCategory.system);
      _deviceType = 'Unknown Device';
      _asrEngine = 'Check Settings → Models';
      _llmEngine = 'Check Settings → Models';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<_OnboardingPageData> get _pages => [
    _OnboardingPageData(
      title: 'Welcome to LiveCaptionsXR',
      description:
          'Real-time captions anchored in AR space. '
          'See who\'s speaking and what they\'re saying, positioned right where they are.',
      icon: Icons.spatial_audio,
      color: Colors.blue,
    ),
    _OnboardingPageData(
      title: 'Permissions Needed',
      description:
          '🎤 Microphone — to hear and transcribe speech\n'
          '📷 Camera — for AR scene understanding\n'
          '📍 Motion Sensors — for spatial tracking\n\n'
          'All data stays on your device. Nothing is sent to the cloud.',
      icon: Icons.shield,
      color: Colors.teal,
    ),
    _OnboardingPageData(
      title: 'Spatial Audio Intelligence',
      description:
          'Our AI uses stereo audio, camera, and motion sensors to track speakers in 3D space. '
          'Captions follow the speaker as they move — left, right, center.',
      icon: Icons.surround_sound,
      color: Colors.purple,
    ),
    _OnboardingPageData(
      title: 'Real-Time Translation',
      description:
          'Translate speech into 15+ languages instantly. '
          'All processing happens on-device for complete privacy.\n\n'
          'Powered by Nexa SDK on Qualcomm Snapdragon NPU.',
      icon: Icons.translate,
      color: Colors.green,
    ),
    _OnboardingPageData(
      title: 'Your Device: $_deviceType',
      description: _getDeviceDescription(),
      icon: _isNexaDevice ? Icons.bolt : Icons.download,
      color: _isNexaDevice ? Colors.green : Colors.orange,
      isDevicePage: true,
    ),
    _OnboardingPageData(
      title: _isNexaDevice ? 'Ready to Go!' : 'Download AI Models',
      description: _getModelInstructions(),
      icon: _isNexaDevice ? Icons.check_circle : Icons.download_for_offline,
      color: _isNexaDevice ? Colors.green : Colors.indigo,
      showModelPath: true,
    ),
  ];

  String _getDeviceDescription() {
    if (_isNexaDevice) {
      return 'Snapdragon NPU detected! The Parakeet ASR model (~600MB) will download automatically '
          'when you first use captions. Make sure you have WiFi connected.\n\n'
          '• Speech Recognition: $_asrEngine\n'
          '• AI Enhancement: $_llmEngine';
    } else if (kIsWeb) {
      return '🌐 Web mode has limited functionality.\n\n'
          'For the full AR experience, download the Android or iOS app.';
    } else if (!kIsWeb && Platform.isIOS) {
      return '🍎 iOS uses Apple\'s built-in speech recognition.\n\n'
          '• Speech Recognition: $_asrEngine\n'
          '• AI Enhancement: $_llmEngine\n\n'
          'You\'ll need to download the Gemma model for text enhancement.';
    } else {
      return '📱 Standard Android device detected.\n\n'
          '• Speech Recognition: $_asrEngine\n'
          '• AI Enhancement: $_llmEngine\n\n'
          'You\'ll need to download AI models before using AR mode.';
    }
  }

  String _getModelInstructions() {
    if (_isNexaDevice) {
      return 'Your Nexa models download automatically! 🎉\n\n'
          'Optional: You can also download Whisper/Gemma for offline fallback.\n\n'
          'Find them in:\n'
          '⚙️ Settings → AI Models';
    } else if (kIsWeb) {
      return 'Model downloads are not available in web mode.\n\n'
          'Please use the mobile app for full functionality.';
    } else {
      return 'Before using AR mode, download the required AI models.\n\n'
          'Find them in:\n'
          '⚙️ Settings → AI Models\n\n'
          'Or tap the ⚡ icon on the home screen.';
    }
  }

  @override
  void dispose() {
    _logger.i('🗑️ OnboardingScreen disposing...', category: LogCategory.ui);
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    try {
      _logger.i('✅ Completing onboarding process...', category: LogCategory.ui);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);
      
      if (mounted) {
        context.go('/home');
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Error completing onboarding', 
          category: LogCategory.ui, error: e, stackTrace: stackTrace);
    }
  }

  void _onContinue() {
    if (_currentPage == _pages.length - 1) {
      _completeOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onSkip() {
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Detecting your device...'),
            ],
          ),
        ),
      );
    }

    final pages = _pages;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Page indicator dots
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pages.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? pages[index].color
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                    _isLastPage = index == pages.length - 1;
                  });
                },
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return _OnboardingPage(
                    title: page.title,
                    description: page.description,
                    icon: page.icon,
                    color: page.color,
                    showModelPath: page.showModelPath,
                    isNexaDevice: _isNexaDevice,
                  );
                },
              ),
            ),
            
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _onSkip,
                    child: Text(
                      'Skip',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pages[_currentPage].color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: Text(_isLastPage ? 'Get Started' : 'Next'),
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
  final IconData icon;
  final Color color;
  final bool isDevicePage;
  final bool showModelPath;

  _OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.isDevicePage = false,
    this.showModelPath = false,
  });
}

class _OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool showModelPath;
  final bool isNexaDevice;

  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.showModelPath = false,
    this.isNexaDevice = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with colored background
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 60,
              color: color,
            ),
          ),
          const SizedBox(height: 40),
          
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade700,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          // Show path indicator on the model instructions page
          if (showModelPath && !isNexaDevice) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app, color: color),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Home Screen → ⚙️ Settings',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '→ AI Models → Download',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          
          // Nexa device success indicator
          if (showModelPath && isNexaDevice) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 12),
                  Text(
                    'Ready to go! Tap Start AR to begin.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
