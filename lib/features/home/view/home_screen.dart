import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import '../../sound_detection/cubit/sound_detection_cubit.dart';
import '../../localization/cubit/localization_cubit.dart';
import '../../visual_identification/cubit/visual_identification_cubit.dart';
import '../../live_captions/cubit/live_captions_cubit.dart';
import '../../live_captions/widgets/live_captions_widget.dart';
import '../../settings/cubit/settings_cubit.dart';
import '../../ar_session/cubit/ar_session_cubit.dart';
import '../../ar_session/cubit/ar_session_state.dart';
import '../cubit/home_cubit.dart';
import '../../../core/models/sound_event.dart';
import '../../../core/models/visual_object.dart';
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

    // Auto-start all main activities after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoStartServices();
    });
  }

  /// Automatically start all main app services
  void _autoStartServices() async {
    if (!mounted) return;

    try {
      _logger.i('🚀 Auto-starting all main services...');

      // Start live captions automatically
      final liveCaptionsCubit = context.read<LiveCaptionsCubit>();
      if (!liveCaptionsCubit.isActive) {
        _logger.i('🎤 Auto-starting live captions...');
        await liveCaptionsCubit.startCaptions();
        _logger.i('✅ Live captions auto-started');
      }

      // Initialize sound detection (it's already listening via method channel)
      _logger.i('🔊 Sound detection initialized and ready');

      // Initialize localization (it's already ready to receive data)
      _logger.i('🧭 Localization initialized and ready');

      // Initialize visual identification (it's already listening via method channel)
      _logger.i('👁️ Visual identification initialized and ready');

      // Show notification that services are running
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '🚀 Basic services initialized! Enter AR Mode for full experience.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      _logger.i('🎉 All main services initialized successfully');
    } catch (e, stackTrace) {
      _logger.e('❌ Error auto-starting services',
          error: e, stackTrace: stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Some services failed to start: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Start all services needed for AR mode using the ARSessionCubit
  Future<void> _startAllServicesForARMode() async {
    if (!mounted) return;

    final arSessionCubit = context.read<ARSessionCubit>();
    
    // Use the ARSessionCubit to manage starting all services
    await arSessionCubit.startAllARServices(
      startLiveCaptions: () async {
        final liveCaptionsCubit = context.read<LiveCaptionsCubit>();
        if (!liveCaptionsCubit.isActive) {
          _logger.i('🎤 Starting live captions for AR mode...');
          await liveCaptionsCubit.startCaptions();
          _logger.i('✅ Live captions started for AR mode');
        } else {
          _logger.i('🎤 Live captions already active');
        }
      },
      startSoundDetection: () async {
        final soundDetectionCubit = context.read<SoundDetectionCubit>();
        if (!soundDetectionCubit.isActive) {
          _logger.i('🔊 Starting sound detection for AR mode...');
          await soundDetectionCubit.start();
          _logger.i('✅ Sound detection started for AR mode');
        } else {
          _logger.i('🔊 Sound detection already active');
        }
      },
      startLocalization: () async {
        final localizationCubit = context.read<LocalizationCubit>();
        if (!localizationCubit.isActive) {
          _logger.i('🧭 Starting localization for AR mode...');
          await localizationCubit.start();
          _logger.i('✅ Localization started for AR mode');
        } else {
          _logger.i('🧭 Localization already active');
        }
      },
      startVisualIdentification: () async {
        final visualIdentificationCubit = context.read<VisualIdentificationCubit>();
        if (!visualIdentificationCubit.isActive) {
          _logger.i('👁️ Starting visual identification for AR mode...');
          await visualIdentificationCubit.start();
          _logger.i('✅ Visual identification started for AR mode');
        } else {
          _logger.i('👁️ Visual identification already active');
        }
      },
    );
  }

  @override
  void dispose() {
    _logger.i('🗑️ HomeScreen disposing...');
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
            listener: (context, state) {},
            child: Scaffold(
              body: Stack(
                children: [
                  // Camera preview background with instruction overlay
                  Container(
                    color: Colors.black,
                    child: Stack(
                      children: [
                        const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.view_in_ar,
                                  color: Colors.white24, size: 120),
                              SizedBox(height: 16),
                              Text(
                                'AR Experience Ready',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap "Enter AR Mode" to begin',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Welcome message overlay
                  Positioned(
                    top: 80,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha((255 * 0.9).round()),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((255 * 0.3).round()),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Welcome to Live Captions XR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Your integrated AR accessibility experience:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '• Live Captions for real-time speech\n'
                            '• Sound detection and monitoring\n'
                            '• Directional audio tracking\n'
                            '• Visual object identification\n'
                            '• AR anchors for spatial context',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
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
                              color: Colors.blue.withAlpha((255 * 0.8).round()),
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
                              color: Colors.black.withAlpha((255 * 0.3).round()),
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
              floatingActionButton: BlocListener<ARSessionCubit, ARSessionState>(
                listener: (context, state) {
                  if (state is ARSessionReady) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            '🥽 AR Mode activated! All services started automatically.'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  } else if (state is ARSessionError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('⚠️ ${state.message}'),
                        backgroundColor: Colors.orange,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                },
                child: FloatingActionButton(
                  heroTag: "ar_view_fab",
                  onPressed: () async {
                    _logger.i('🥽 Enter AR Mode button pressed...');
                    
                    final arSessionCubit = context.read<ARSessionCubit>();
                    
                    try {
                      // Show loading indicator to user
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              SizedBox(width: 16),
                              Text('🥽 Entering AR Mode...'),
                            ],
                          ),
                          backgroundColor: Colors.blue,
                          duration: Duration(seconds: 3),
                        ),
                      );
                      
                      // Initialize AR session using the cubit
                      await arSessionCubit.initializeARSession();
                      
                      // Check if AR session initialization succeeded
                      if (!arSessionCubit.isReady) {
                        _logger.w('⚠️ AR session not ready after initialization');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ Failed to enter AR mode. Please try again.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      // Give additional time for AR view to be fully presented
                      _logger.i('⏳ Waiting for AR view to be fully presented...');
                      await Future.delayed(const Duration(milliseconds: 1500));
                      
                      // Start all services if AR session is ready
                      _logger.i('🚀 Starting all services for AR mode...');
                      await _startAllServicesForARMode();
                      
                      _logger.i('🎉 Successfully entered AR mode with all services');
                      
                      // Hide the loading snackbar
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      
                    } catch (e, stackTrace) {
                      _logger.e('❌ Failed to enter AR mode', error: e, stackTrace: stackTrace);
                      
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Failed to enter AR mode: ${e.toString()}'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 5),
                        ),
                      );
                    }
                  },
                  tooltip: 'Enter AR Mode',
                  child: const Icon(Icons.view_in_ar),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
