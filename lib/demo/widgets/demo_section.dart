import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../navigation/web_navigation_cubit.dart';

class DemoSection extends StatefulWidget {
  const DemoSection({Key? key}) : super(key: key);

  @override
  State<DemoSection> createState() => _DemoSectionState();
}

class _DemoSectionState extends State<DemoSection>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  String _currentScenario = 'Select a scenario to see live_captions_xr in action';
  String _currentOutput = '';
  bool _isProcessing = false;

  final Map<String, Map<String, String>> _scenarios = {
    'doorbell': {
      'title': 'Doorbell Detection',
      'description': 'Someone rings the doorbell while you\'re in another room',
      'output': '🔔 DOORBELL DETECTED\n\nLocation: Front door (Left, 15°)\nConfidence: 92%\nContext: Visitor waiting\n\nRecommended Action:\n• Check door camera\n• Respond to visitor\n\nHaptic Pattern: ●●● ○ ●●● ○',
    },
    'microwave': {
      'title': 'Kitchen Alert',
      'description': 'Microwave finishing while cooking',
      'output': '🍽️ MICROWAVE FINISHED\n\nLocation: Kitchen (Right, 45°)\nConfidence: 88%\nContext: Food ready\n\nRecommended Action:\n• Check microwave\n• Remove food safely\n\nHaptic Pattern: ●○●○●○',
    },
    'emergency': {
      'title': 'Emergency Vehicle',
      'description': 'Emergency vehicle approaching from behind',
      'output': '🚨 EMERGENCY VEHICLE\n\nLocation: Behind you (180°)\nConfidence: 95%\nContext: Move to safety\n\nURGENT ACTION:\n• Move to curb\n• Stay alert\n\nHaptic Pattern: ●●●●●●',
    },
    'conversation': {
      'title': 'Group Conversation',
      'description': 'Multiple people speaking in a meeting',
      'output': '👥 GROUP CONVERSATION\n\nSpeakers: 3 people detected\n• Person A (Left): "What do you think?"\n• Person B (Center): "I agree with..."\n• Person C (Right): [Nodding]\n\nContext: Meeting discussion\nYour turn to respond\n\nHaptic Pattern: ○●○ ○●○',
    },
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _runScenario(String scenarioKey) async {
    final scenario = _scenarios[scenarioKey]!;
    
    setState(() {
      _isProcessing = true;
      _currentScenario = scenario['title']!;
      _currentOutput = 'Processing multimodal inputs...\n\n🎤 Analyzing audio patterns\n👁️ Processing visual context\n🧠 Applying AI understanding';
    });

    // Simulate processing time
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isProcessing = false;
      _currentOutput = scenario['output']!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 64),
      child: Column(
        children: [
          // Section Header
          Text(
            'Interactive Demo',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Experience live_captions_xr\'s multimodal AI in real-world scenarios',
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
                // Left Side - Scenario Selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose a Scenario',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    ..._scenarios.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _ScenarioButton(
                          scenarioKey: entry.key,
                          title: entry.value['title']!,
                          description: entry.value['description']!,
                          onPressed: () => _runScenario(entry.key),
                          isProcessing: _isProcessing,
                        ),
                      );
                    }),
                    
                    const SizedBox(height: 32),
                    
                    // Demo Status
                    BlocBuilder<WebNavigationCubit, WebNavigationState>(
                      builder: (context, state) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: state.isDemoActive 
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: state.isDemoActive 
                                  ? Colors.green 
                                  : Colors.grey,
                            ),
                          ),
                          child: Row(
                            children: [
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: state.isDemoActive 
                                        ? _pulseAnimation.value 
                                        : 1.0,
                                    child: Icon(
                                      state.isDemoActive 
                                          ? Icons.radio_button_on 
                                          : Icons.radio_button_off,
                                      color: state.isDemoActive 
                                          ? Colors.green 
                                          : Colors.grey,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              Text(
                                state.isDemoActive 
                                    ? 'Demo Mode Active - Try scenarios above!'
                                    : 'Click "Start Demo" in navigation to begin',
                                style: TextStyle(
                                  color: state.isDemoActive 
                                      ? Colors.green 
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(width: 48),
                // Right Side - Output Display
                Container(
                  height: 600,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.phone_android,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'live_captions_xr Output',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            if (_isProcessing)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // Content Area
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Scenario Title
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _currentScenario,
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Output Content
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Text(
                                    _currentOutput.isEmpty 
                                        ? 'Select a scenario above to see live_captions_xr\'s AI analysis and recommendations.'
                                        : _currentOutput,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      height: 1.6,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenarioButton extends StatefulWidget {
  final String scenarioKey;
  final String title;
  final String description;
  final VoidCallback onPressed;
  final bool isProcessing;

  const _ScenarioButton({
    required this.scenarioKey,
    required this.title,
    required this.description,
    required this.onPressed,
    required this.isProcessing,
  });

  @override
  State<_ScenarioButton> createState() => _ScenarioButtonState();
}

class _ScenarioButtonState extends State<_ScenarioButton> {
  bool _isHovered = false;

  IconData _getScenarioIcon() {
    switch (widget.scenarioKey) {
      case 'doorbell':
        return Icons.doorbell;
      case 'microwave':
        return Icons.microwave;
      case 'emergency':
        return Icons.emergency;
      case 'conversation':
        return Icons.people;
      default:
        return Icons.play_arrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
        child: InkWell(
          onTap: widget.isProcessing ? null : widget.onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHovered 
                    ? Theme.of(context).primaryColor
                    : Colors.grey.withOpacity(0.3),
                width: _isHovered ? 2 : 1,
              ),
              boxShadow: [
                if (_isHovered)
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getScenarioIcon(),
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
                        widget.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                Icon(
                  Icons.play_arrow,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}