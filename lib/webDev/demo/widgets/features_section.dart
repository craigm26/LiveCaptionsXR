import 'package:flutter/material.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 64),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Section Header
            Text(
              'Core Features',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Real-time multimodal AI processing for comprehensive accessibility, powered by Google\'s MediaPipe.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 64),
            
            // Features Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 1.2,
              crossAxisSpacing: 32,
              mainAxisSpacing: 32,
              children: const [
                _FeatureCard(
                  icon: Icons.hearing,
                  title: 'Sound Detection',
                  description: 'Real-time audio analysis identifying sounds and speech with directional awareness.',
                  gradient: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                _FeatureCard(
                  icon: Icons.visibility,
                  title: 'Visual Recognition',
                  description: 'On-device computer vision for face detection and speaker identification.',
                  gradient: [Color(0xFFf093fb), Color(0xFFf5576c)],
                ),
                _FeatureCard(
                  icon: Icons.navigation,
                  title: 'Spatial Localization',
                  description: 'Precise 3D positioning of sounds using advanced sensor fusion and TDOA.',
                  gradient: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                ),
                _FeatureCard(
                  icon: Icons.psychology,
                  title: 'Contextual AI',
                  description: 'Gemma 3n integration via MediaPipe for intelligent context understanding and multimodal data fusion.',
                  gradient: [Color(0xFF43e97b), Color(0xFF38f9d7)],
                ),
                _FeatureCard(
                  icon: Icons.vibration,
                  title: 'Haptic Feedback',
                  description: 'Rich tactile responses synchronized with visual and audio cues for enhanced accessibility.',
                  gradient: [Color(0xFFfa709a), Color(0xFFfee140)],
                ),
                _FeatureCard(
                  icon: Icons.language,
                  title: 'Multilingual ASR',
                  description: 'Streaming Automatic Speech Recognition for over 100 languages, powered by Gemma 3n.',
                  gradient: [Color(0xFFa8edea), Color(0xFFfed6e3)],
                ),
              ],
            ),
            
            const SizedBox(height: 64),
            
            // Interactive Process Flow
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Multimodal Processing Pipeline',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ProcessStep(
                        icon: Icons.mic,
                        title: 'Audio Input',
                        description: 'Capture & Analyze',
                        color: Colors.blue,
                      ),
                      const _ProcessArrow(),
                      _ProcessStep(
                        icon: Icons.camera_alt,
                        title: 'Visual Input',
                        description: 'Detect & Recognize',
                        color: Colors.green,
                      ),
                      const _ProcessArrow(),
                      _ProcessStep(
                        icon: Icons.psychology,
                        title: 'MediaPipe Fusion',
                        description: 'Gemma 3n Inference',
                        color: Colors.purple,
                      ),
                      const _ProcessArrow(),
                      _ProcessStep(
                        icon: Icons.output,
                        title: 'Accessible Output',
                        description: 'Visual + Haptic',
                        color: Colors.orange,
                      ),
                    ],
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

class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradient;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.gradient,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradient.first.withOpacity(0.3),
                    blurRadius: _isHovered ? 20 : 10,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    widget.icon,
                    size: 48,
                    color: Colors.white,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Expanded(
                    child: Text(
                      widget.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        height: 1.5,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProcessStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _ProcessStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(
            icon,
            size: 36,
            color: color,
          ),
        ),
        
        const SizedBox(height: 12),
        
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 4),
        
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _ProcessArrow extends StatelessWidget {
  const _ProcessArrow();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.arrow_forward,
      size: 32,
      color: Colors.grey[400],
    );
  }
}