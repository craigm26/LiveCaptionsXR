import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
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
import '../../../core/services/app_logger.dart';
import '../../../shared/widgets/debug_logging_overlay.dart';
import '../../../shared/widgets/ar_session_status_widget.dart';
import '../../../core/services/model_download_manager.dart';
import 'package:provider/provider.dart';
import '../../../core/services/debug_logger_service.dart';
import '../../../core/services/whisper_service_impl.dart';
import '../../../core/services/gemma_3n_service.dart';
import 'package:live_captions_xr/core/di/service_locator.dart';
import 'package:live_captions_xr/core/services/camera_service.dart';
import '../../../core/services/frame_capture_service.dart';
import '../../../core/services/apple_speech_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static final AppLogger _logger = AppLogger.instance;

  late ModelDownloadManager _modelDownloadManager;
  bool _isGemmaInitialized = false;
  bool _isGemmaInitializing = false;

  @override
  void initState() {
    super.initState();
    _logger.i('🏠 HomeScreen initialized', category: LogCategory.ui);
    _modelDownloadManager = ModelDownloadManager();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkAndPromptModelDownload();
      // Initialize Gemma after model checks
      await _initializeGemmaBeforeAR();
    });
  }

  Future<void> _checkAndPromptModelDownload() async {
    _logger.d('🔍 Checking model availability on app startup...',
        category: LogCategory.system);

    // Check if required models exist
    _logger.d('🔍 Checking Gemma model availability...',
        category: LogCategory.gemma);
    final gemmaExists =
        await _modelDownloadManager.modelExists('gemma-3n-E4B-it-int4');
    _logger.d('📦 Gemma model exists: $gemmaExists',
        category: LogCategory.gemma);

    _logger.d('🔍 Checking Whisper model availability...',
        category: LogCategory.speech);
    final whisperExists =
        await _modelDownloadManager.modelExists('whisper-base');
    _logger.d('📦 Whisper model exists: $whisperExists',
        category: LogCategory.speech);

    _logger.d(
        '📊 Model availability summary - Gemma: $gemmaExists, Whisper: $whisperExists',
        category: LogCategory.system);

    if ((!gemmaExists || !whisperExists) && mounted) {
      _logger.w('⚠️ Missing models detected, showing download dialog',
          category: LogCategory.system);
      _showModelDownloadDialog(
          gemmaExists: gemmaExists, whisperExists: whisperExists);
    } else {
      _logger.i('✅ All required models are available',
          category: LogCategory.system);
    }
  }

  /// Initialize Gemma 3n service before AR launch to prevent freezing during AR session
  Future<void> _initializeGemmaBeforeAR() async {
    if (_isGemmaInitialized || _isGemmaInitializing) {
      _logger.i('🤖 Gemma already initialized or initializing, skipping',
          category: LogCategory.gemma);
      return;
    }

    try {
      _isGemmaInitializing = true;
      _logger.i('🤖 Pre-initializing Gemma 3n service before AR launch...',
          category: LogCategory.gemma);

      final gemma3nService = sl<Gemma3nService>();

      if (gemma3nService.isReady) {
        _logger.i('✅ Gemma 3n service already ready',
            category: LogCategory.gemma);
        _isGemmaInitialized = true;
        return;
      }

      // Show loading state if needed
      if (mounted) {
        setState(() {});
      }

      // Initialize with platform-specific timeout
      final timeout =
          Platform.isIOS ? Duration(seconds: 90) : Duration(seconds: 120);
      _logger.i(
          '⏱️ Initializing Gemma with ${timeout.inSeconds}s timeout for ${Platform.isIOS ? 'iOS' : 'Android'}',
          category: LogCategory.gemma);

      await gemma3nService.initialize().timeout(timeout);

      if (gemma3nService.isReady) {
        _logger.i('✅ Gemma 3n service pre-initialized successfully!',
            category: LogCategory.gemma);
        _isGemmaInitialized = true;
      } else {
        _logger.w('⚠️ Gemma 3n service initialized but not ready',
            category: LogCategory.gemma);
      }
    } on TimeoutException catch (e) {
      _logger.e('⏱️ Gemma 3n service initialization timed out',
          category: LogCategory.gemma, error: e);
      _logger.w('⚠️ Continuing without Gemma enhancement',
          category: LogCategory.gemma);
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to pre-initialize Gemma 3n service',
          category: LogCategory.gemma, error: e, stackTrace: stackTrace);
      _logger.w('⚠️ Continuing without Gemma enhancement',
          category: LogCategory.gemma);
    } finally {
      _isGemmaInitializing = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _showModelDownloadDialog(
      {required bool gemmaExists, required bool whisperExists}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ChangeNotifierProvider<ModelDownloadManager>.value(
          value: _modelDownloadManager,
          child: Consumer<ModelDownloadManager>(
            builder: (context, manager, _) {
              const gemmaKey = 'gemma-3n-E4B-it-int4';
              const whisperKey = 'whisper-base';

              final gemmaDownloading = manager.isDownloading(gemmaKey);
              final gemmaProgress = manager.getProgress(gemmaKey);
              final gemmaError = manager.getError(gemmaKey);
              final gemmaCompleted = manager.isCompleted(gemmaKey);

              final whisperDownloading = manager.isDownloading(whisperKey);
              final whisperProgress = manager.getProgress(whisperKey);
              final whisperError = manager.getError(whisperKey);
              final whisperCompleted = manager.isCompleted(whisperKey);

              return AlertDialog(
                title: const Text('Download Required Models'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LiveCaptionsXR requires two AI models for full functionality:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Gemma Model Section
                      if (!gemmaExists || !gemmaCompleted)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.auto_awesome,
                                      color: Colors.blue.shade600),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Gemma 3n Multimodal Model',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'For caption enhancement and multimodal processing (4.1 GB)',
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              if (gemmaDownloading)
                                Column(
                                  children: [
                                    LinearProgressIndicator(
                                        value: gemmaProgress),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Downloading: ${(gemmaProgress * 100).toStringAsFixed(1)}%',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                )
                              else if (gemmaError != null)
                                Column(
                                  children: [
                                    Text(
                                      'Error: $gemmaError',
                                      style: const TextStyle(
                                          color: Colors.red, fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    ElevatedButton(
                                      onPressed: () {
                                        manager.resetModel(gemmaKey);
                                        manager.downloadModel(gemmaKey);
                                      },
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                )
                              else if (!gemmaCompleted)
                                ElevatedButton(
                                  onPressed: () =>
                                      manager.downloadModel(gemmaKey),
                                  child: const Text('Download Gemma Model'),
                                ),
                              if (gemmaCompleted)
                                const Text('✅ Gemma model ready',
                                    style: TextStyle(color: Colors.green)),
                            ],
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Whisper Model Section
                      if (!whisperExists || !whisperCompleted)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.mic, color: Colors.green.shade600),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Whisper Speech Recognition Model',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'For speech-to-text transcription (147.95 MB)',
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              if (whisperDownloading)
                                Column(
                                  children: [
                                    LinearProgressIndicator(
                                        value: whisperProgress),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Downloading: ${(whisperProgress * 100).toStringAsFixed(1)}%',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                )
                              else if (whisperError != null)
                                Column(
                                  children: [
                                    Text(
                                      'Error: $whisperError',
                                      style: const TextStyle(
                                          color: Colors.red, fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    ElevatedButton(
                                      onPressed: () {
                                        manager.resetModel(whisperKey);
                                        manager.downloadModel(whisperKey);
                                      },
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                )
                              else if (!whisperCompleted)
                                ElevatedButton(
                                  onPressed: () =>
                                      manager.downloadModel(whisperKey),
                                  child: const Text('Download Whisper Model'),
                                ),
                              if (whisperCompleted)
                                const Text('✅ Whisper model ready',
                                    style: TextStyle(color: Colors.green)),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Info section
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: Colors.blueGrey),
                          const SizedBox(width: 4),
                          const Text(
                            'Estimated total download time: ~20-45 min on a 50 Mbps connection',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => launchUrl(Uri.parse(
                            'https://huggingface.co/google/gemma-3n-E2B-it')),
                        child: const Text(
                          'Learn more about the models',
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  if (!gemmaDownloading &&
                      !whisperDownloading &&
                      (!gemmaCompleted || !whisperCompleted))
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
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
    _logger.i('🚀🚀🚀 [HOME] _startAllServicesForARMode STARTED!',
        category: LogCategory.ui);

    try {
      if (!mounted) {
        _logger.w('⚠️ [HOME] Widget not mounted, returning',
            category: LogCategory.ui);
        return;
      }

      _logger.i('🔍 [HOME] Step 1: Getting ARSessionCubit...',
          category: LogCategory.ui);
      final arSessionCubit = context.read<ARSessionCubit>();
      _logger.i('✅ [HOME] Step 1 complete: Got arSessionCubit',
          category: LogCategory.ui);

      _logger.i('🔍 [HOME] Step 2: Getting Whisper service...',
          category: LogCategory.ui);
      final whisperService = sl<WhisperService>();
      _logger.i(
          '✅ [HOME] Step 2 complete: Retrieved Whisper service from service locator',
          category: LogCategory.speech);

      _logger.i('🔍 [HOME] Step 3: Getting Gemma 3n service...',
          category: LogCategory.ui);
      final gemma3nService = sl<Gemma3nService>();
      _logger.i(
          '✅ [HOME] Step 3 complete: Retrieved Gemma 3n service from service locator',
          category: LogCategory.gemma);

      _logger.i('🔍 [HOME] Step 4: Setting up Whisper STT event listener...',
          category: LogCategory.ui);
      arSessionCubit.listenToWhisperSTT(whisperService);
      _logger.i(
          '✅ [HOME] Step 4 complete: Whisper STT event listener configured',
          category: LogCategory.speech);

      _logger.i(
          '🔍 [HOME] Step 5: Setting up Gemma 3n enhancement event listener...',
          category: LogCategory.ui);
      arSessionCubit.listenToGemma3nEnhancement(gemma3nService);
      _logger.i(
          '✅ [HOME] Step 5 complete: Gemma 3n enhancement event listener configured',
          category: LogCategory.gemma);

      _logger.i(
          '🔍 [HOME] Step 6: Starting all AR services through ARSessionCubit...',
          category: LogCategory.ui);
      await arSessionCubit.startAllARServices(
        startLiveCaptions: () async {
          _logger.i('🔍 [HOME] Step 6a: Getting LiveCaptionsCubit...',
              category: LogCategory.ui);
          final liveCaptionsCubit = context.read<LiveCaptionsCubit>();
          _logger.i('✅ [HOME] Step 6a complete: Got LiveCaptionsCubit',
              category: LogCategory.ui);

          _logger.i('🔍 [HOME] Step 6b: Checking LiveCaptions state...',
              category: LogCategory.ui);
          if (liveCaptionsCubit.state is! LiveCaptionsActive ||
              !(liveCaptionsCubit.state as LiveCaptionsActive).isListening) {
            _logger.i(
                '🎤 [HOME] Step 6c: Starting live captions for AR mode...',
                category: LogCategory.captions);
            await liveCaptionsCubit.startCaptions();
            _logger.i(
                '✅ [HOME] Step 6c complete: Live captions started for AR mode',
                category: LogCategory.captions);
          } else {
            _logger.i('🎤 [HOME] Step 6c: Live captions already active',
                category: LogCategory.captions);
          }
        },
        startSoundDetection: () async {
          final soundDetectionCubit = context.read<SoundDetectionCubit>();
          if (!soundDetectionCubit.isActive) {
            _logger.i('🔊 Starting sound detection for AR mode...',
                category: LogCategory.audio);
            await soundDetectionCubit.start();
            _logger.i('✅ Sound detection started for AR mode',
                category: LogCategory.audio);
          } else {
            _logger.i('🔊 Sound detection already active',
                category: LogCategory.audio);
          }
        },
        startLocalization: () async {
          final localizationCubit = context.read<LocalizationCubit>();
          if (!localizationCubit.isActive) {
            _logger.i('🧭 Starting localization for AR mode...',
                category: LogCategory.ar);
            await localizationCubit.start();
            _logger.i('✅ Localization started for AR mode',
                category: LogCategory.ar);
          } else {
            _logger.i('🧭 Localization already active',
                category: LogCategory.ar);
          }
        },
        startVisualIdentification: () async {
          final visualIdentificationCubit =
              context.read<VisualIdentificationCubit>();
          if (!visualIdentificationCubit.isActive) {
            _logger.i('👁️ Starting visual identification for AR mode...',
                category: LogCategory.camera);
            await visualIdentificationCubit.start();
            _logger.i('✅ Visual identification started for AR mode',
                category: LogCategory.camera);
          } else {
            _logger.i('👁️ Visual identification already active',
                category: LogCategory.camera);
          }
        },
        // Provide stop callbacks for proper cleanup
        stopLiveCaptions: () async {
          final liveCaptionsCubit = context.read<LiveCaptionsCubit>();
          if (liveCaptionsCubit.state is LiveCaptionsActive &&
              (liveCaptionsCubit.state as LiveCaptionsActive).isListening) {
            _logger.i('🎤 Stopping live captions...',
                category: LogCategory.captions);
            await liveCaptionsCubit.stopCaptions();
            _logger.i('✅ Live captions stopped',
                category: LogCategory.captions);
          }
        },
        stopSoundDetection: () async {
          final soundDetectionCubit = context.read<SoundDetectionCubit>();
          if (soundDetectionCubit.isActive) {
            _logger.i('🔊 Stopping sound detection...');
            await soundDetectionCubit.stop();
            _logger.i('✅ Sound detection stopped');
          }
        },
        stopLocalization: () async {
          final localizationCubit = context.read<LocalizationCubit>();
          if (localizationCubit.isActive) {
            _logger.i('🧭 Stopping localization...');
            await localizationCubit.stop();
            _logger.i('✅ Localization stopped');
          }
        },
        stopVisualIdentification: () async {
          final visualIdentificationCubit =
              context.read<VisualIdentificationCubit>();
          if (visualIdentificationCubit.isActive) {
            _logger.i('👁️ Stopping visual identification...');
            await visualIdentificationCubit.stop();
            _logger.i('✅ Visual identification stopped');
          }
        },
      );
      _logger.i(
          '✅ [HOME] Step 6 complete: All AR services started successfully through ARSessionCubit',
          category: LogCategory.ui);
      _logger.i(
          '🎉🎉🎉 [HOME] _startAllServicesForARMode COMPLETED SUCCESSFULLY!',
          category: LogCategory.ui);
    } catch (e, stackTrace) {
      _logger.e('❌ [HOME] _startAllServicesForARMode FAILED!',
          category: LogCategory.ui, error: e, stackTrace: stackTrace);
      rethrow;
    }
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
            future: cameraService
                .initialize()
                .then((_) => cameraService.startCamera()),
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

    return BlocBuilder<SettingsCubit, dynamic>(
        builder: (context, settingsState) {
      final debugOverlayEnabled = (settingsState != null &&
              settingsState.debugLoggingOverlayEnabled != null)
          ? settingsState.debugLoggingOverlayEnabled
          : false;
      return BlocBuilder<HomeCubit, HomeState>(
        builder: (context, homeState) {
          return DebugLoggingOverlay(
            isEnabled: debugOverlayEnabled,
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

                    // AR Session Status Widget (top of screen)
                    BlocBuilder<ARSessionCubit, ARSessionState>(
                      builder: (context, arSessionState) {
                        // Show status widget when AR session is not in initial state
                        if (arSessionState is! ARSessionInitial) {
                          return Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: ARSessionStatusWidget(
                              showCloseButton: arSessionState is ARSessionReady,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    BlocBuilder<ARSessionCubit, ARSessionState>(
                      builder: (context, arSessionState) {
                        final inARMode = arSessionState is ARSessionReady;
                        // Only log significant AR state changes
                        return BlocBuilder<LiveCaptionsCubit,
                            LiveCaptionsState>(
                          builder: (context, captionsState) {
                            // Removed verbose caption state logging
                            // Removed verbose caption details logging

                            // Only show overlay when in AR mode and captions are active
                            // or when explicitly requested for fallback
                            bool showOverlay = false;
                            if (inARMode &&
                                captionsState is LiveCaptionsActive) {
                              showOverlay = true;
                              _logger.i(
                                  '🎯 [UI] Showing captions overlay in AR mode',
                                  category: LogCategory.ui);
                            } else if (inARMode &&
                                captionsState is LiveCaptionsActive &&
                                captionsState.showOverlayFallback) {
                              showOverlay = true;
                              // Fallback mode
                            } else {
                              // Not showing captions overlay
                            }

                            return showOverlay
                                ? Positioned(
                                    bottom: 120,
                                    left: 16,
                                    right: 16,
                                    child: LiveCaptionsWidget(
                                      onToggle: () {
                                        final cubit =
                                            context.read<LiveCaptionsCubit>();
                                        if (cubit.state is LiveCaptionsActive &&
                                            (cubit.state as LiveCaptionsActive)
                                                .isListening) {
                                          cubit.stopCaptions();
                                        } else {
                                          cubit.startCaptions();
                                        }
                                      },
                                      onClear: () {
                                        context
                                            .read<LiveCaptionsCubit>()
                                            .clearCaptions();
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
                                color:
                                    Colors.blue.withAlpha((255 * 0.8).round()),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.hearing,
                                      color: Colors.white),
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
                                color:
                                    Colors.black.withAlpha((255 * 0.3).round()),
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
                floatingActionButton:
                    BlocListener<ARSessionCubit, ARSessionState>(
                  listener: (context, state) {
                    if (state is ARSessionReady) {
                      // AR session is ready. No need to start services here anymore.
                      _logger.i(
                          '🔄 AR session ready. Services should already be started.');
                    } else if (state is ARSessionError) {
                      _logger.e('❌ AR session error: ${state.message}');
                    } else if (state is ARSessionInitial) {
                      // AR mode was closed - ensure all services are stopped
                      _logger.i('✅ AR mode closed and all services stopped');

                      // Double-check that live captions are stopped
                      final liveCaptionsCubit =
                          context.read<LiveCaptionsCubit>();
                      if (liveCaptionsCubit.state is LiveCaptionsActive &&
                          (liveCaptionsCubit.state as LiveCaptionsActive)
                              .isListening) {
                        _logger.w(
                            '⚠️ Live captions still active after AR session end, stopping...');
                        liveCaptionsCubit.stopCaptions();
                      }

                      // Double-check that other services are stopped
                      final soundDetectionCubit =
                          context.read<SoundDetectionCubit>();
                      if (soundDetectionCubit.isActive) {
                        _logger.w(
                            '⚠️ Sound detection still active after AR session end, stopping...');
                        soundDetectionCubit.stop();
                      }

                      final localizationCubit =
                          context.read<LocalizationCubit>();
                      if (localizationCubit.isActive) {
                        _logger.w(
                            '⚠️ Localization still active after AR session end, stopping...');
                        localizationCubit.stop();
                      }

                      final visualIdentificationCubit =
                          context.read<VisualIdentificationCubit>();
                      if (visualIdentificationCubit.isActive) {
                        _logger.w(
                            '⚠️ Visual identification still active after AR session end, stopping...');
                        visualIdentificationCubit.stop();
                      }

                      _logger.i(
                          '✅ All services verified as stopped after AR session end');
                    }
                  },
                  child: FloatingActionButton(
                    heroTag: "ar_view_fab",
                    onPressed: _isGemmaInitializing
                        ? null
                        : () async {
                            _logger.i('🥽 Enter AR Mode button pressed...',
                                category: LogCategory.ui);

                            final arSessionCubit =
                                context.read<ARSessionCubit>();
                            _logger.i('🎯 Got ARSessionCubit instance',
                                category: LogCategory.ui);

                            try {
                              // Ensure Gemma is initialized before starting AR
                              if (!_isGemmaInitialized &&
                                  !_isGemmaInitializing) {
                                _logger.i(
                                    '🤖 Gemma not yet initialized, initializing now...',
                                    category: LogCategory.ar);
                                await _initializeGemmaBeforeAR();
                              }

                              // Start all AR services
                              await _startAllServicesForARMode();
                              _logger.i(
                                  '✅ [HOME] All AR services started successfully',
                                  category: LogCategory.ui);

                              // Initialize AR session (this will block until AR view is closed)
                              _logger.i(
                                  '🎯 [HOME] Now calling initializeARSession...',
                                  category: LogCategory.ui);
                              await arSessionCubit.initializeARSession(
                                  restoreFromPersistence: false);
                              _logger.i('✅ [HOME] AR session completed',
                                  category: LogCategory.ui);
                            } catch (e, stackTrace) {
                              _logger.e('❌ Failed to enter AR mode',
                                  error: e, stackTrace: stackTrace);

                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '❌ Failed to enter AR mode: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                            }
                          },
                    tooltip: _isGemmaInitializing
                        ? 'Initializing Gemma...'
                        : 'Enter AR Mode',
                    child: _isGemmaInitializing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.view_in_ar),
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}
