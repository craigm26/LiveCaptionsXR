import 'package:flutter/material.dart';

class TechnologySection extends StatelessWidget {
  const TechnologySection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 64),
      decoration: BoxDecoration(
        color: Colors.grey[50],
      ),
      child: Column(
        children: [
          // Section Header
          Text(
            'Technology Stack',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Powered by Google Gemma 3n and cutting-edge mobile AI',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          
          const SizedBox(height: 64),
          
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Left Side - Gemma 3n Highlight
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withAlpha((255 * 0.7).round()),
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
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha((255 * 0.2).round()),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.psychology,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Gemma 3n',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Text(
                        'Revolutionary Multimodal AI',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      const Text(
                        'live_captions_xr is the first accessibility application to deliver real-time closed captioning using Gemma 3n\'s advanced AI. Unlike traditional systems, live_captions_xr provides instant, context-aware captions for spoken content in any environment.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Key Features
                      Column(
                        children: [
                          _TechFeature(
                            icon: Icons.merge_type,
                            text: 'Unified multimodal processing',
                          ),
                          _TechFeature(
                            icon: Icons.speed,
                            text: 'Real-time inference <100ms',
                          ),
                          _TechFeature(
                            icon: Icons.phone_android,
                            text: 'On-device processing',
                          ),
                          _TechFeature(
                            icon: Icons.language,
                            text: '140+ language support',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 32),
                
                // Right Side - Tech Stack
                Column(
                  children: [
                    // Mobile Development
                    _TechStackCard(
                      title: 'Mobile Development',
                      technologies: [
                        _TechItem(name: 'Flutter', description: 'Cross-platform UI framework'),
                        _TechItem(name: 'Dart', description: 'High-performance language'),
                        _TechItem(name: 'BLoC Pattern', description: 'State management'),
                      ],
                      color: Colors.blue,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // AI & Machine Learning
                    _TechStackCard(
                      title: 'AI & Machine Learning',
                      technologies: [
                        _TechItem(name: 'Gemma 3n', description: 'Multimodal AI model'),
                        _TechItem(name: 'Google MediaPipe', description: 'On-device inference engine'),
                        _TechItem(name: 'TDOA & Kalman Filter', description: 'Advanced localization'),
                      ],
                      color: Colors.green,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Hardware Integration
                    _TechStackCard(
                      title: 'Hardware Integration',
                      technologies: [
                        _TechItem(name: 'ARKit / ARCore', description: 'Augmented reality'),
                        _TechItem(name: 'AVAudioEngine / AudioRecord', description: 'Stereo audio capture'),
                        _TechItem(name: 'Vision Framework', description: 'Real-time face detection'),
                      ],
                      color: Colors.purple,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 64),
          
          // Architecture Diagram
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((255 * 0.1).round()),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'System Architecture',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Simplified Architecture
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ArchLayer(
                      title: 'Input Layer',
                      components: ['Camera', 'Microphone', 'Sensors'],
                      color: Colors.blue,
                    ),
                    const Icon(Icons.arrow_forward, color: Colors.grey),
                    _ArchLayer(
                      title: 'Processing Layer',
                      components: ['Gemma 3n', 'MediaPipe', 'Kalman Filter'],
                      color: Colors.green,
                    ),
                    const Icon(Icons.arrow_forward, color: Colors.grey),
                    _ArchLayer(
                      title: 'Output Layer',
                      components: ['AR Overlay', 'Haptic Feedback', 'Notifications'],
                      color: Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TechFeature extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TechFeature({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _TechStackCard extends StatelessWidget {
  final String title;
  final List<_TechItem> technologies;
  final Color color;

  const _TechStackCard({
    required this.title,
    required this.technologies,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha((255 * 0.3).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          ...technologies.map((tech) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color.withAlpha((255 * 0.6).round()),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tech.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      tech.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _TechItem {
  final String name;
  final String description;

  const _TechItem({
    required this.name,
    required this.description,
  });
}

class _ArchLayer extends StatelessWidget {
  final String title;
  final List<String> components;
  final Color color;

  const _ArchLayer({
    required this.title,
    required this.components,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha((255 * 0.1).round()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha((255 * 0.3).round())),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          
          const SizedBox(height: 12),
          
          ...components.map((component) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              component,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          )),
        ],
      ),
    );
  }
}