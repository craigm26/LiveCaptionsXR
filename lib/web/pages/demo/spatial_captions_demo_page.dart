import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/nav_bar.dart';
import '../../utils/responsive_utils.dart';

class SpatialCaptionsDemoPage extends StatefulWidget {
  const SpatialCaptionsDemoPage({super.key});

  @override
  State<SpatialCaptionsDemoPage> createState() => _SpatialCaptionsDemoPageState();
}

class _SpatialCaptionsDemoPageState extends State<SpatialCaptionsDemoPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _demoTexts = [
    "Hello, this is a test caption",
    "AR captions are amazing!",
    "This caption is on your left",
    "Look right for this caption",
    "Center caption here",
    "Testing partial captions...",
    "Final caption with enhancement",
  ];

  final List<String> _directions = ['left', 'center', 'right'];
  int _textIndex = 0;
  int _directionIndex = 0;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _nextCaption() {
    setState(() {
      _textIndex = (_textIndex + 1) % _demoTexts.length;
      _directionIndex = (_directionIndex + 1) % _directions.length;
    });
  }

  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final currentText = _demoTexts[_textIndex];
    final currentDirection = _directions[_directionIndex];

    return Scaffold(
      appBar: const NavBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24.0 : 48.0,
                vertical: isMobile ? 32.0 : 64.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Spatial Captions Demo',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Experience how Live Captions XR places captions in 3D space. This demo simulates the AR experience on web.',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 48),

                  // Demo Controls
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Demo Controls',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _nextCaption,
                              icon: const Icon(Icons.skip_next),
                              label: const Text('Next Caption'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: _togglePlayback,
                              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                              label: Text(_isPlaying ? 'Pause' : 'Auto Play'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isPlaying ? Colors.orange : Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // AR Scene Simulation
                  Container(
                    height: 400,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.shade50,
                          Colors.purple.shade50,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Stack(
                      children: [
                        // Background elements to simulate AR scene
                        Positioned(
                          top: 50,
                          left: 50,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.person, color: Colors.blue),
                          ),
                        ),
                        Positioned(
                          top: 100,
                          right: 80,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.person, color: Colors.green),
                          ),
                        ),
                        Positioned(
                          bottom: 80,
                          left: 100,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.person, color: Colors.orange),
                          ),
                        ),

                        // Caption bubble based on direction
                        Positioned(
                          top: currentDirection == 'left' ? 120 : 80,
                          left: currentDirection == 'left' ? 20 : null,
                          right: currentDirection == 'right' ? 20 : null,
                          child: currentDirection == 'center' 
                            ? Center(
                                child: Container(
                                  constraints: const BoxConstraints(maxWidth: 300),
                                  child: _buildCaptionBubble(currentText, currentDirection),
                                ),
                              )
                            : Container(
                                constraints: const BoxConstraints(maxWidth: 250),
                                child: _buildCaptionBubble(currentText, currentDirection),
                              ),
                        ),

                        // Direction indicator
                        Positioned(
                          bottom: 20,
                          left: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Direction: $currentDirection',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Features explanation
                  Container(
                    padding: const EdgeInsets.all(24),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How It Works',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureExplanation(
                          Icons.hearing,
                          'Spatial Audio Detection',
                          'The app detects the direction of sound using stereo microphones and advanced audio processing.',
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureExplanation(
                          Icons.visibility,
                          'Visual Speaker Identification',
                          'Computer vision identifies who is speaking and their location in 3D space.',
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureExplanation(
                          Icons.view_in_ar,
                          'AR Caption Placement',
                          'Captions are positioned in augmented reality space, appearing to float near the speaker.',
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureExplanation(
                          Icons.psychology,
                          'AI Context Enhancement',
                          'Gemma 3n AI enhances captions with context and improves accuracy.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // CTA Section
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          Colors.blue.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Ready to Experience the Real Thing?',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Download the mobile app to experience true AR spatial captions with real-time audio processing.',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => context.go('/'),
                              icon: const Icon(Icons.home),
                              label: const Text('Back to Home'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
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
        ),
      ),
    );
  }

  Widget _buildCaptionBubble(String text, String direction) {
    Color bubbleColor;
    IconData directionIcon;

    switch (direction) {
      case 'left':
        bubbleColor = Colors.blue;
        directionIcon = Icons.arrow_back;
        break;
      case 'right':
        bubbleColor = Colors.green;
        directionIcon = Icons.arrow_forward;
        break;
      default:
        bubbleColor = Colors.purple;
        directionIcon = Icons.center_focus_strong;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bubbleColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: bubbleColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(directionIcon, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                'Speaker $direction',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureExplanation(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 