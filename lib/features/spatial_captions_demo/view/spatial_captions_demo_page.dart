import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vector_math/vector_math_64.dart' as vec;
import 'package:get_it/get_it.dart';
import 'dart:math' as math;

import 'package:spatial_captions/cubit/spatial_captions_cubit.dart';
import 'package:spatial_captions/cubit/spatial_captions_state.dart';
import 'package:live_captions_xr/core/services/spatial_caption_integration_service.dart';
import 'package:live_captions_xr/core/models/speech_result.dart';
import 'package:live_captions_xr/features/ar_session/cubit/ar_session_cubit.dart';
import 'package:live_captions_xr/features/ar_session/cubit/ar_session_state.dart';

class SpatialCaptionsDemoPage extends StatefulWidget {
  const SpatialCaptionsDemoPage({super.key});

  @override
  State<SpatialCaptionsDemoPage> createState() => _SpatialCaptionsDemoPageState();
}

class _SpatialCaptionsDemoPageState extends State<SpatialCaptionsDemoPage> {
  late final SpatialCaptionsCubit _spatialCaptionsCubit;
  late final SpatialCaptionIntegrationService _integrationService;
  late final ARSessionCubit _arSessionCubit;

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

  @override
  void initState() {
    super.initState();
    _spatialCaptionsCubit = GetIt.I<SpatialCaptionsCubit>();
    _integrationService = GetIt.I<SpatialCaptionIntegrationService>();
    _arSessionCubit = context.read<ARSessionCubit>();
    
    // Initialize the integration service
    _integrationService.initialize();
  }

  @override
  void dispose() {
    _integrationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spatial Captions Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // AR Session Status
          _buildARSessionStatus(),
          
          // Caption Controls
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildControlCard(),
                  const SizedBox(height: 16),
                  _buildCaptionsList(),
                  const SizedBox(height: 16),
                  _buildSettingsCard(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildARSessionStatus() {
    return BlocBuilder<ARSessionCubit, ARSessionState>(
      builder: (context, state) {
        Color statusColor;
        String statusText;
        IconData statusIcon;

        if (state is ARSessionReady) {
          statusColor = Colors.green;
          statusText = 'AR Session Ready';
          statusIcon = Icons.check_circle;
        } else if (state is ARSessionError) {
          statusColor = Colors.red;
          statusText = 'AR Session Error';
          statusIcon = Icons.error;
        } else {
          statusColor = Colors.orange;
          statusText = 'AR Session Initializing...';
          statusIcon = Icons.hourglass_empty;
        }

        return Container(
          padding: const EdgeInsets.all(12),
          color: statusColor.withAlpha((255 * 0.1).round()),
          child: Row(
            children: [
              Icon(statusIcon, color: statusColor),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (state is! ARSessionReady)
                TextButton(
                  onPressed: () => _arSessionCubit.initializeARSession(),
                  child: const Text('Initialize AR'),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Caption Controls',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Add Partial Caption
            ElevatedButton.icon(
              onPressed: _addPartialCaption,
              icon: const Icon(Icons.add_comment),
              label: const Text('Add Partial Caption'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 8),
            
            // Add Final Caption
            ElevatedButton.icon(
              onPressed: _addFinalCaption,
              icon: const Icon(Icons.check),
              label: const Text('Add Final Caption'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 8),
            
            // Simulate Speech Flow
            OutlinedButton.icon(
              onPressed: _simulateSpeechFlow,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Simulate Speech Flow'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptionsList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Active Captions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                BlocBuilder<SpatialCaptionsCubit, SpatialCaptionsState>(
                  bloc: _spatialCaptionsCubit,
                  builder: (context, state) {
                    return Chip(
                      label: Text('${state.activeCaptions.length} active'),
                      backgroundColor: Colors.blue.withAlpha((255 * 0.2).round()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            BlocBuilder<SpatialCaptionsCubit, SpatialCaptionsState>(
              bloc: _spatialCaptionsCubit,
              builder: (context, state) {
                if (state.activeCaptions.isEmpty) {
                  return const Center(
                    child: Text(
                      'No active captions',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.activeCaptions.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final caption = state.activeCaptions[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getTypeColor(caption.type.toString()),
                        child: Text(
                          caption.type.toString().split('.').last[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(caption.text),
                      subtitle: Text(
                        'Speaker: ${caption.speakerId ?? "Unknown"} | '
                        'Pos: (${caption.position.x.toStringAsFixed(1)}, '
                        '${caption.position.y.toStringAsFixed(1)}, '
                        '${caption.position.z.toStringAsFixed(1)})',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => _spatialCaptionsCubit.removeCaption(caption.id),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Caption Duration Slider
            const Text('Caption Duration'),
            Slider(
              value: _spatialCaptionsCubit.captionDuration.inSeconds.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '${_spatialCaptionsCubit.captionDuration.inSeconds}s',
              onChanged: (value) {
                setState(() {
                  _spatialCaptionsCubit.setCaptionDuration(
                    Duration(seconds: value.toInt()),
                  );
                });
              },
            ),
            
            // Orientation Lock
            BlocBuilder<SpatialCaptionsCubit, SpatialCaptionsState>(
              bloc: _spatialCaptionsCubit,
              builder: (context, state) {
                return SwitchListTile(
                  title: const Text('Lock to Landscape'),
                  subtitle: const Text('Prevents portrait mode UI issues'),
                  value: state.isLandscapeLocked,
                  onChanged: (value) {
                    _spatialCaptionsCubit.setOrientationLock(value);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: 'clear',
          onPressed: _clearAllCaptions,
          tooltip: 'Clear All Captions',
          backgroundColor: Colors.red,
          child: const Icon(Icons.clear_all),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          heroTag: 'add',
          onPressed: _addRandomCaption,
          tooltip: 'Add Random Caption',
          child: const Icon(Icons.add),
        ),
      ],
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'CaptionType.partial':
        return Colors.orange;
      case 'CaptionType.final_':
        return Colors.blue;
      case 'CaptionType.enhanced':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _addPartialCaption() {
    final text = _demoTexts[_textIndex % _demoTexts.length];
    final direction = _directions[_directionIndex % _directions.length];
    
    final result = SpeechResult(
      text: text,
      confidence: 0.85,
      isFinal: false,
      timestamp: DateTime.now(),
      speakerDirection: direction,
    );
    
    _integrationService.processPartialResult(result);
    
    setState(() {
      _textIndex++;
      _directionIndex++;
    });
  }

  void _addFinalCaption() {
    final text = _demoTexts[_textIndex % _demoTexts.length];
    final direction = _directions[_directionIndex % _directions.length];
    
    final result = SpeechResult(
      text: text,
      confidence: 0.95,
      isFinal: true,
      timestamp: DateTime.now(),
      speakerDirection: direction,
    );
    
    _integrationService.processFinalResult(result);
    
    setState(() {
      _textIndex++;
      _directionIndex++;
    });
  }

  void _addRandomCaption() {
    final random = math.Random();
    final angle = (random.nextDouble() - 0.5) * math.pi; // -90° to +90°
    final distance = 1.5 + random.nextDouble() * 1.5; // 1.5m to 3m
    
    final position = vec.Vector3(
      distance * math.sin(angle),
      (random.nextDouble() - 0.5) * 0.5, // ±0.25m height variation
      -distance * math.cos(angle),
    );
    
    _spatialCaptionsCubit.addPartialCaption(
      text: 'Random caption at ${angle.toStringAsFixed(1)} rad',
      position: position,
      speakerId: 'random-${random.nextInt(3)}',
    );
  }

  Future<void> _simulateSpeechFlow() async {
    // Simulate a typical speech flow: partial → partial → final → enhanced
    const baseText = "This is a simulated speech";
    
    // First partial
    await _integrationService.processPartialResult(
      SpeechResult(
        text: "This is",
        confidence: 0.7,
        isFinal: false,
        timestamp: DateTime.now(),
        speakerDirection: 'center',
      ),
    );
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Second partial
    await _integrationService.processPartialResult(
      SpeechResult(
        text: "This is a simulated",
        confidence: 0.8,
        isFinal: false,
        timestamp: DateTime.now(),
        speakerDirection: 'center',
      ),
    );
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Final result
    await _integrationService.processFinalResult(
      SpeechResult(
        text: baseText,
        confidence: 0.95,
        isFinal: true,
        timestamp: DateTime.now(),
        speakerDirection: 'center',
      ),
    );
    
    // Enhancement will happen automatically after a delay
  }

  void _clearAllCaptions() {
    _integrationService.clearAllCaptions();
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Spatial Captions Demo'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('This demo allows you to test the spatial caption system:\n'),
              Text('• Partial captions (orange) - Real-time transcription'),
              Text('• Final captions (blue) - Completed transcription'),
              Text('• Enhanced captions (green) - AI-enhanced text'),
              Text('\nCaptions are positioned based on:'),
              Text('• Speaker direction (left/center/right)'),
              Text('• Audio localization'),
              Text('• Manual placement for testing'),
              Text('\nFeatures:'),
              Text('• Caption lifecycle management'),
              Text('• Automatic caption replacement'),
              Text('• Landscape orientation lock'),
              Text('• Configurable display duration'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
} 