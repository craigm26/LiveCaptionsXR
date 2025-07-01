import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../../sound_detection/cubit/sound_detection_cubit.dart';
import '../../localization/cubit/localization_cubit.dart';
import '../../visual_identification/cubit/visual_identification_cubit.dart';
import '../cubit/home_cubit.dart';
import '../../../core/models/sound_event.dart';
import '../../../core/models/visual_object.dart';
import 'dart:ui';
import '../../../core/services/ar_anchor_manager.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _demoTimer;

  void _onDemoModePressed(BuildContext context) {
    context.read<HomeCubit>().toggleDemoMode();
  }

  void _startDemoMode() {
    _demoTimer?.cancel();
    _demoTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      // Inject fake sound event
      context.read<SoundDetectionCubit>().detectSound(
        SoundEvent(type: 'Beep', confidence: 0.9, timestamp: DateTime.now()),
      );
      // Inject fake localization
      final directions = ['left', 'right', 'center'];
      final dir = directions[DateTime.now().second % 3];
      context.read<LocalizationCubit>().localize(dir, 0.8);
      // Inject fake visual object
      context.read<VisualIdentificationCubit>().detectObjects([
        VisualObject(
          label: 'Microwave',
          confidence: 0.95,
          boundingBox: const Rect.fromLTWH(0, 0, 100, 100),
        ),
      ]);
    });
  }

  void _stopDemoMode() {
    _demoTimer?.cancel();
    _demoTimer = null;
  }

  @override
  void dispose() {
    _stopDemoMode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeCubit, HomeState>(
      listenWhen: (prev, curr) => prev.demoMode != curr.demoMode,
      listener: (context, state) {
        if (state.demoMode) {
          _startDemoMode();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Demo mode ON: Injecting fake events')), // Show ON
          );
        } else {
          _stopDemoMode();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Demo mode OFF')), // Show OFF
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('live_captions_xr Home (AR Fusion)'),
          actions: [
            BlocBuilder<HomeCubit, HomeState>(
              builder: (context, state) => IconButton(
                icon: Icon(
                  Icons.science,
                  color: state.demoMode ? Colors.amber : null,
                ),
                tooltip: 'Toggle Demo Mode',
                onPressed: () => _onDemoModePressed(context),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            // Simulated camera preview background
            Container(
              color: Colors.black,
              child: Center(
                child: Icon(Icons.camera_alt, color: Colors.white24, size: 200),
              ),
            ),
            // Sound event overlay (top left)
            Positioned(
              top: 32,
              left: 16,
              child: BlocBuilder<SoundDetectionCubit, SoundDetectionState>(
                builder: (context, state) {
                  if (state is SoundDetectionLoaded && state.events.isNotEmpty) {
                    final SoundEvent event = state.events.last;
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.hearing, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            '${event.type} (${(event.confidence * 100).toStringAsFixed(0)}%)',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            // Directional cue overlay (center)
            Center(
              child: BlocBuilder<LocalizationCubit, LocalizationState>(
                builder: (context, state) {
                  if (state is LocalizationLoaded) {
                    IconData arrowIcon;
                    switch (state.direction) {
                      case 'left':
                        arrowIcon = Icons.arrow_back;
                        break;
                      case 'right':
                        arrowIcon = Icons.arrow_forward;
                        break;
                      case 'center':
                        arrowIcon = Icons.arrow_upward;
                        break;
                      default:
                        arrowIcon = Icons.navigation;
                    }
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(arrowIcon, color: Colors.orange, size: 64),
                        const SizedBox(height: 8),
                        Text(
                          'Sound from ${state.direction} (${(state.confidence * 100).toStringAsFixed(0)}%)',
                          style: const TextStyle(color: Colors.orange, fontSize: 18),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            // Visual object highlight overlay (bottom right)
            BlocBuilder<VisualIdentificationCubit, VisualIdentificationState>(
              builder: (context, state) {
                if (state is VisualIdentificationLoaded && state.objects.isNotEmpty) {
                  final VisualObject obj = state.objects.first;
                  return Positioned(
                    bottom: 48,
                    right: 24,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.greenAccent, width: 3),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black.withOpacity(0.3),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.visibility, color: Colors.greenAccent),
                          const SizedBox(width: 8),
                          Text(
                            '${obj.label} (${(obj.confidence * 100).toStringAsFixed(0)}%)',
                            style: const TextStyle(color: Colors.greenAccent),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: () async {
                final homeCubit = context.read<HomeCubit>();
                final arAnchorManager = ARAnchorManager();
                try {
                  final fusedTransform = await homeCubit.getFusedTransform();
                  final anchorId = await arAnchorManager.createAnchorAtWorldTransform(fusedTransform);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('AR Anchor placed! ID: $anchorId')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to place AR Anchor: $e')),
                  );
                }
              },
              tooltip: 'Place AR Anchor (Fused)',
              child: const Icon(Icons.add_location_alt),
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              onPressed: () async {
                const MethodChannel('live_captions_xr/ar_navigation').invokeMethod('showARView');
              },
              tooltip: 'Enter AR Mode',
              child: const Icon(Icons.view_in_ar),
            ),
          ],
        ),
      ),
    );
  }
} 