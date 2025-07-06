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

  /// Start all services needed for AR mode, including automatic anchor placement
  Future<void> _startAllServicesForARMode() async {
    if (!mounted) return;

    try {
      _logger.i('🚀 Starting all services for AR mode...');

      // Ensure live captions are running
      final liveCaptionsCubit = context.read<LiveCaptionsCubit>();
      if (!liveCaptionsCubit.isActive) {
        _logger.i('🎤 Starting live captions for AR mode...');
        await liveCaptionsCubit.startCaptions();
        _logger.i('✅ Live captions started for AR mode');
      }

      // Initialize sound detection (method channel should be ready)
      _logger.i('🔊 Sound detection active for AR mode');

      // Initialize localization (ready to receive data)
      _logger.i('🧭 Localization active for AR mode');

      // Initialize visual identification (method channel ready)
      _logger.i('👁️ Visual identification active for AR mode');

      // Automatically place AR anchor after services are ready
      _logger.i('🎯 Auto-placing AR anchor for AR mode...');
      await _autoPlaceARAnchor();

      _logger.i('🎉 All AR mode services initialized successfully');
    } catch (e, stackTrace) {
      _logger.e('❌ Error starting AR mode services',
          error: e, stackTrace: stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Some AR services failed to start: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Automatically place AR anchor when entering AR mode
  Future<void> _autoPlaceARAnchor() async {
    try {
      _logger.i('🎯 Auto-placing AR anchor...');

      final homeCubit = context.read<HomeCubit>();
      final arAnchorManager = ARAnchorManager();

      _logger.i('🔄 Getting fused transform for automatic anchor placement...');
      final fusedTransform = await homeCubit.getFusedTransform();

      _logger.i('🌍 Creating AR anchor automatically with fused transform...');
      final anchorId = await arAnchorManager
          .createAnchorAtWorldTransform(fusedTransform);

      _logger.i('🎉 AR anchor auto-placed successfully: $anchorId');
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to auto-place AR Anchor',
          error: e, stackTrace: stackTrace);
      
      // Don't show error to user as this is automatic - just log it
      // The main AR mode functionality should still work without the anchor
    }
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
                        color: Colors.blue.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
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
              floatingActionButton: FloatingActionButton(
                heroTag: "ar_view_fab",
                onPressed: () async {
                  try {
                    _logger.i('🥽 Enter AR Mode button pressed...');

                    // Start AR view
                    await const MethodChannel(
                            'live_captions_xr/ar_navigation')
                        .invokeMethod('showARView');

                    _logger.i('✅ AR View launched successfully');

                    // Automatically start all services when entering AR mode
                    await _startAllServicesForARMode();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              '🥽 AR Mode activated! All services started automatically.'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  } on PlatformException catch (e) {
                    _logger.e('❌ AR View platform exception', error: e);

                    String errorMessage;
                    switch (e.code) {
                      case 'UNAVAILABLE':
                        errorMessage = '⚠️ AR not supported on this device';
                        break;
                      case 'NOT_AUTHORIZED':
                        errorMessage =
                            '⚠️ Camera permission required for AR';
                        break;
                      case 'AR_NOT_SUPPORTED':
                        errorMessage =
                            '⚠️ ARKit not supported (try on a physical device)';
                        break;
                      default:
                        errorMessage =
                            '⚠️ AR View not available: ${e.message}';
                    }

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(errorMessage),
                          backgroundColor: Colors.orange,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  } catch (e, stackTrace) {
                    _logger.e('❌ Failed to launch AR View',
                        error: e, stackTrace: stackTrace);

                    String errorMessage;
                    if (e.toString().contains('MissingPluginException')) {
                      errorMessage =
                          '⚠️ AR functionality not implemented in current build';
                    } else {
                      errorMessage = '❌ Failed to launch AR View: $e';
                    }

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(errorMessage),
                          backgroundColor: Colors.orange,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  }
                },
                tooltip: 'Enter AR Mode',
                child: const Icon(Icons.view_in_ar),
              ),
            ),
          ),
        );
      },
    );
  }
}
