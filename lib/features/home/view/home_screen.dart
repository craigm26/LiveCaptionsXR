import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';

import '../../sound_detection/cubit/sound_detection_cubit.dart';
import '../../localization/cubit/localization_cubit.dart';
import '../../visual_identification/cubit/visual_identification_cubit.dart';
import '../../live_captions/cubit/live_captions_cubit.dart';
import '../../live_captions/widgets/live_captions_widget.dart';
import '../../settings/cubit/settings_cubit.dart';
import '../cubit/home_cubit.dart';
import '../../../core/models/sound_event.dart';
import '../../../core/models/visual_object.dart';
import '../../../core/services/ar_anchor_manager.dart';
import '../../../core/services/debug_capturing_logger.dart';
import '../../../shared/widgets/debug_logging_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static final DebugCapturingLogger _logger = DebugCapturingLogger();

  Timer? _demoTimer;

  @override
  void initState() {
    super.initState();
    _logger.i('🏠 HomeScreen initialized');
  }

  void _onDemoModePressed(BuildContext context) {
    _logger.i('🎭 Demo mode toggle requested');
    try {
      context.read<HomeCubit>().toggleDemoMode();
      _logger.d('✅ Demo mode toggle completed successfully');
    } catch (e, stackTrace) {
      _logger.e('❌ Error toggling demo mode', error: e, stackTrace: stackTrace);
    }
  }

  void _startDemoMode() {
    try {
      _logger.i('🎭 Starting demo mode with periodic fake events...');
      _demoTimer?.cancel();
      _demoTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        try {
          _logger.d('🎭 Injecting demo events - cycle ${timer.tick}');

          // Inject fake sound event
          final soundEvent = SoundEvent(
              type: 'Beep', confidence: 0.9, timestamp: DateTime.now());
          context.read<SoundDetectionCubit>().detectSound(soundEvent);
          _logger.d('🔊 Injected fake sound event: ${soundEvent.type}');

          // Inject fake localization
          final directions = ['left', 'right', 'center'];
          final dir = directions[DateTime.now().second % 3];
          context.read<LocalizationCubit>().localize(dir, 0.8);
          _logger.d('🧭 Injected fake localization: $dir (confidence: 0.8)');

          // Inject fake visual object
          final visualObject = VisualObject(
            label: 'Microwave',
            confidence: 0.95,
            boundingBox: const Rect.fromLTWH(0, 0, 100, 100),
          );
          context
              .read<VisualIdentificationCubit>()
              .detectObjects([visualObject]);
          _logger.d(
              '👁️ Injected fake visual object: ${visualObject.label} (confidence: ${visualObject.confidence})');
        } catch (e, stackTrace) {
          _logger.e('❌ Error injecting demo events',
              error: e, stackTrace: stackTrace);
        }
      });
      _logger.i('✅ Demo mode started successfully');
    } catch (e, stackTrace) {
      _logger.e('❌ Error starting demo mode', error: e, stackTrace: stackTrace);
    }
  }

  void _stopDemoMode() {
    try {
      _logger.i('🛑 Stopping demo mode...');
      _demoTimer?.cancel();
      _demoTimer = null;
      _logger.i('✅ Demo mode stopped successfully');
    } catch (e, stackTrace) {
      _logger.e('❌ Error stopping demo mode', error: e, stackTrace: stackTrace);
    }
  }

  /// Test method to generate various types of logs for debugging the logging overlay
  void _testLogging() {
    _logger.d('🔍 Testing debug logging functionality...');

    // Generate different types of logs to test the overlay
    _logger.t('🔍 This is a trace message - very detailed debugging info');
    _logger.d('🐛 This is a debug message - general debugging info');
    _logger.i('ℹ️ This is an info message - general information');
    _logger.w('⚠️ This is a warning message - something to be cautious about');
    _logger.e('❌ This is an error message - something went wrong');

    // Test with error and stack trace
    try {
      throw Exception('Test exception for logging demonstration');
    } catch (e, stackTrace) {
      _logger.e('💥 Test exception caught', error: e, stackTrace: stackTrace);
    }

    _logger.i('✅ Debug logging test completed - check the overlay!');

    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Debug logs generated! Check the logging overlay.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _logger.i('🗑️ HomeScreen disposing...');
    _stopDemoMode();
    super.dispose();
    _logger.d('✅ HomeScreen disposed successfully');
  }

  @override
  Widget build(BuildContext context) {
    _logger.d('🏗️ Building HomeScreen UI');

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        return DebugLoggingOverlay(
          isEnabled: settingsState.debugLoggingEnabled,
          child: BlocListener<HomeCubit, HomeState>(
            listenWhen: (prev, curr) => prev.demoMode != curr.demoMode,
            listener: (context, state) {
              _logger.d(
                  '🎭 Demo mode state changed: ${state.demoMode ? "ON" : "OFF"}');

              if (state.demoMode) {
                _startDemoMode();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Demo mode ON: Injecting fake events')),
                );
                _logger.i('📢 Demo mode ON notification shown');
              } else {
                _stopDemoMode();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Demo mode OFF')),
                );
                _logger.i('📢 Demo mode OFF notification shown');
              }
            },
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Home'),
                actions: [
                  BlocBuilder<HomeCubit, HomeState>(
                    builder: (context, state) {
                      _logger.d(
                          '🏗️ Building AppBar demo mode button - state: ${state.demoMode}');
                      return IconButton(
                        icon: Icon(
                          Icons.science,
                          color: state.demoMode ? Colors.amber : null,
                        ),
                        tooltip: 'Toggle Demo Mode',
                        onPressed: () => _onDemoModePressed(context),
                      );
                    },
                  ),
                ],
              ),
              body: Stack(
                children: [
                  // Simulated camera preview background
                  Container(
                    color: Colors.black,
                    child: Center(
                      child: Icon(Icons.camera_alt,
                          color: Colors.white24, size: 200),
                    ),
                  ),
                  // Live Captions overlay (bottom center)
                  Positioned(
                    bottom: 120,
                    left: 16,
                    right: 16,
                    child: LiveCaptionsWidget(
                      onToggle: () {
                        final cubit = context.read<LiveCaptionsCubit>();
                        if (cubit.isActive) {
                          cubit.stopCaptions();
                        } else {
                          cubit.startCaptions();
                        }
                      },
                      onClear: () {
                        context.read<LiveCaptionsCubit>().clearCaptions();
                      },
                      maxWidth: 600,
                      showHistory: false,
                    ),
                  ),
                  // Sound event overlay (top left)
                  Positioned(
                    top: 32,
                    left: 16,
                    child:
                        BlocBuilder<SoundDetectionCubit, SoundDetectionState>(
                      builder: (context, state) {
                        if (state is SoundDetectionLoaded &&
                            state.events.isNotEmpty) {
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
                                style: const TextStyle(
                                    color: Colors.orange, fontSize: 18),
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  // Visual object highlight overlay (bottom right)
                  BlocBuilder<VisualIdentificationCubit,
                      VisualIdentificationState>(
                    builder: (context, state) {
                      if (state is VisualIdentificationLoaded &&
                          state.objects.isNotEmpty) {
                        final VisualObject obj = state.objects.first;
                        return Positioned(
                          bottom: 48,
                          right: 24,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.greenAccent, width: 3),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.black.withOpacity(0.3),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.visibility,
                                    color: Colors.greenAccent),
                                const SizedBox(width: 8),
                                Text(
                                  '${obj.label} (${(obj.confidence * 100).toStringAsFixed(0)}%)',
                                  style: const TextStyle(
                                      color: Colors.greenAccent),
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
                  // Test Logging Button (only visible when debug logging is enabled)
                  BlocBuilder<SettingsCubit, SettingsState>(
                    builder: (context, settingsState) {
                      if (settingsState.debugLoggingEnabled) {
                        return Column(
                          children: [
                            FloatingActionButton(
                              heroTag: "test_logging_fab",
                              mini: true,
                              backgroundColor: Colors.orange,
                              onPressed: () => _testLogging(),
                              tooltip: 'Test Debug Logging',
                              child: const Icon(Icons.bug_report, size: 20),
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  FloatingActionButton(
                    heroTag: "ar_anchor_fab",
                    onPressed: () async {
                      final homeCubit = context.read<HomeCubit>();
                      final arAnchorManager = ARAnchorManager();
                      try {
                        final fusedTransform =
                            await homeCubit.getFusedTransform();
                        final anchorId = await arAnchorManager
                            .createAnchorAtWorldTransform(fusedTransform);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('AR Anchor placed! ID: $anchorId')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Failed to place AR Anchor: $e')),
                        );
                      }
                    },
                    tooltip: 'Place AR Anchor (Fused)',
                    child: const Icon(Icons.add_location_alt),
                  ),
                  const SizedBox(height: 16),
                  FloatingActionButton(
                    heroTag: "ar_view_fab",
                    onPressed: () async {
                      try {
                        await const MethodChannel(
                                'live_captions_xr/ar_navigation')
                            .invokeMethod('showARView');
                      } on PlatformException catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('AR View not available: ${e.message}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to launch AR View: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    tooltip: 'Enter AR Mode',
                    child: const Icon(Icons.view_in_ar),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
