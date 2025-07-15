import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

import '../../sound_detection/cubit/sound_detection_cubit.dart';
import '../../localization/cubit/localization_cubit.dart';
import '../../visual_identification/cubit/visual_identification_cubit.dart';
import '../../live_captions/cubit/live_captions_cubit.dart';
import '../../live_captions/cubit/live_captions_state.dart';
import '../../live_captions/widgets/live_captions_widget.dart';
import '../../settings/cubit/settings_cubit.dart';
import '../../ar_session/cubit/ar_session_cubit.dart';
import '../../ar_session/cubit/ar_session_state.dart';
import '../cubit/home_cubit.dart';
import '../../../core/models/sound_event.dart';
import '../../../core/models/visual_object.dart';
import '../../../core/services/debug_capturing_logger.dart';
import '../../../shared/widgets/debug_logging_overlay.dart';
import '../../../core/services/model_download_manager.dart';
import 'package:provider/provider.dart';
import '../../../core/services/debug_logger_service.dart';
import 'package:live_captions_xr/core/di/service_locator.dart';
import 'package:live_captions_xr/core/services/camera_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static final DebugCapturingLogger _logger = DebugCapturingLogger();

  late ModelDownloadManager _modelDownloadManager;

  @override
  void initState() {
    super.initState();
    _logger.i('🏠 HomeScreen initialized');
    _modelDownloadManager = ModelDownloadManager();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkAndPromptModelDownload();
    });
  }

  Future<void> _checkAndPromptModelDownload() async {
    final exists = await _modelDownloadManager.modelExists();
    if (!exists && mounted) {
      _showModelDownloadDialog();
    }
  }

  void _showModelDownloadDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ChangeNotifierProvider<ModelDownloadManager>.value(
          value: _modelDownloadManager,
          child: Consumer<ModelDownloadManager>(
            builder: (context, manager, _) {
              // Remove disk space check and warning
              return AlertDialog(
                title: const Text('Download Required Model'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'To enable speech recognition, a 4GB model file must be downloaded. This is a one-time download.'
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: Colors.blueGrey),
                        SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => launchUrl(Uri.parse('https://huggingface.co/google/gemma-3n-E2B-it')),
                          child: Text('Learn more about the model', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Estimated download time: ~15-30 min on a 50 Mbps connection.'),
                    const SizedBox(height: 16),
                    if (manager.downloading)
                      Column(
                        children: [
                          LinearProgressIndicator(value: manager.progress),
                          const SizedBox(height: 8),
                          Text('Downloading:  ${(manager.progress * 100).toStringAsFixed(1)}%'),
                        ],
                      )
                    else if (manager.error != null)
                      Column(
                        children: [
                          Text('Error:  ${manager.error}', style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              manager.reset();
                              manager.downloadModel();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      )
                    else if (!manager.completed)
                      ElevatedButton(
                        onPressed: () {
                          manager.downloadModel();
                        },
                        child: const Text('Download Model'),
                      ),
                    if (manager.completed)
                      const Text('Model downloaded!'),
                  ],
                ),
                actions: [
                  if (!manager.downloading && !manager.completed)
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
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

  Widget _buildCameraOrFallback() {
    return FutureBuilder<bool>(
      future: isAndroidEmulator(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data == true) {
          _logger.w('🧪 Emulator detected: showing AR/camera fallback.');
          final cameraService = sl<CameraService>();
          return FutureBuilder<void>(
            future: cameraService.initialize().then((_) => cameraService.startCamera()),
            builder: (context, camSnapshot) {
              if (camSnapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final preview = cameraService.getCameraPreviewWidget();
              if (preview != null) {
                return Stack(
                  children: [
                    Positioned.fill(child: preview),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        color: Colors.black54,
                        padding: const EdgeInsets.all(16),
                        child: const Text(
                          'Emulator Camera Preview (Fallback AR Mode)',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.videocam_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Camera not available in emulator.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }
            },
          );
        } else {
          // Real device: show actual camera/AR widget (replace with your AR widget)
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.view_in_ar, color: Colors.white24, size: 120),
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
          );
        }
      },
    );
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
                    child: _buildCameraOrFallback(),
                  ),
                  
                  BlocBuilder<ARSessionCubit, ARSessionState>(
                    builder: (context, arSessionState) {
                      final inARMode = arSessionState is ARSessionReady;
                      return BlocBuilder<LiveCaptionsCubit, LiveCaptionsState>(
                        builder: (context, captionsState) {
                          bool showOverlay = false;
                          if (!inARMode) {
                            showOverlay = true;
                          } else if (captionsState is LiveCaptionsActive && captionsState.showOverlayFallback) {
                            showOverlay = true;
                          }
                          return showOverlay
                              ? Positioned(
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
                                )
                              : const SizedBox.shrink();
                        },
                      );
                    },
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
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            '🥽 AR Mode activated! Starting services...'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 3),
                      ),
                    );
                    _logger.i('🚀 Starting all services for AR mode...');
                    _startAllServicesForARMode();
                  } else if (state is ARSessionError) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
                        const SnackBar(
                          content: Row(
                            children: [
                              CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                              SizedBox(width: 16),
                              Text('🥽 Entering AR Mode...'),
                            ],
                          ),
                          backgroundColor: Colors.blue,
                          duration: Duration(seconds: 10), // Increased duration
                        ),
                      );

                      // Initialize AR session. The BlocListener will handle state changes.
                      await arSessionCubit.initializeARSession(
                          restoreFromPersistence: false);
                    } catch (e, stackTrace) {
                      _logger.e('�� Failed to enter AR mode',
                          error: e, stackTrace: stackTrace);

                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('❌ Failed to enter AR mode: ${e.toString()}'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 5),
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
