import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';

import '../../sound_detection/cubit/sound_detection_cubit.dart';
import '../../localization/cubit/localization_cubit.dart';
import '../../visual_identification/cubit/visual_identification_cubit.dart';
import '../../live_captions/cubit/live_captions_cubit.dart';
import '../../live_captions/cubit/live_captions_state.dart';
import '../../live_captions/widgets/live_captions_widget.dart';
import '../../settings/cubit/settings_cubit.dart';
import '../../ar_session/cubit/ar_session_cubit.dart';
import '../../ar_session/cubit/ar_session_state.dart';
import '../../translation/cubit/translation_cubit.dart';
import '../../translation/cubit/translation_state.dart';
import '../cubit/home_cubit.dart';
import '../../../core/models/sound_event.dart';
import '../../../core/models/visual_object.dart';
import '../../../core/services/app_logger.dart';
import '../../../shared/widgets/debug_logging_overlay.dart';
import '../../../shared/widgets/ar_session_status_widget.dart';
import '../../../core/services/model_download_manager.dart';
import '../../../core/services/debug_logger_service.dart';
import '../../../core/services/whisper_service_impl.dart';
import '../../../core/services/gemma_3n_service.dart';
import 'package:live_captions_xr/core/di/service_locator.dart';
import 'package:live_captions_xr/core/services/camera_service.dart';
import '../../../core/services/apple_speech_service.dart';
import '../../../core/services/nexa_asr_service.dart';
import '../../../core/services/enhanced_speech_processor.dart';
import '../../../core/services/spatial_caption_integration_service.dart';
import '../../../core/models/device_model_config.dart';

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
  bool _isWhisperModelAvailable = false;
  bool _isAndroidXrDevice = false;
  bool _forceWhisperOnlyMode = false;
  bool? _nexaDevice; // cached result of Nexa device check
  bool _modelsMissing = false; // Track if required models are missing
  bool _isNexaDeviceDetected = false; // Track if this is a Nexa device

  // Nexa SDK progress tracking
  StreamSubscription<NexaAsrEvent>? _nexaEventSubscription;
  StreamSubscription<DirectionUpdate>? _directionUpdateSubscription;
  double _nexaProgress = 0.0;
  String _nexaStatusMessage = 'Detecting device...';
  bool _nexaReady = false;
  bool _nexaInitializing = false;
  Future<void>? _emulatorCameraStartFuture;
  bool _emulatorCameraPreviewActive = false;
  String? _lastDirection;
  DateTime _lastDirectionAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _logger.i('🏠 HomeScreen initialized', category: LogCategory.ui);
    _modelDownloadManager = ModelDownloadManager();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkAndPromptModelDownload();
      if (!mounted) return;

      _directionUpdateSubscription ??=
          sl<SpatialCaptionIntegrationService>().directionUpdates.listen((update) {
        if (!mounted) return;

        final now = DateTime.now();
        final shouldEmit =
            update.direction != _lastDirection || now.difference(_lastDirectionAt).inMilliseconds > 400;

        if (!shouldEmit) return;

        _lastDirection = update.direction;
        _lastDirectionAt = now;

        try {
          context.read<LocalizationCubit>().localize(update.direction, update.confidence);
        } catch (_) {}

        try {
          context.read<SoundDetectionCubit>().detectSound(
            SoundEvent(
              type: 'speech',
              confidence: update.confidence,
              timestamp: update.timestamp,
              sourceDirection: update.direction,
              description: 'Speech detected from ${update.direction} direction',
              isMultimodal: false,
              priority: 'medium',
            ),
          );
        } catch (_) {}
      });

      if (_forceWhisperOnlyMode) {
        context.read<LiveCaptionsCubit>().setEnhancementEnabled(false);
      }
      // On NPU devices, start Nexa initialization immediately
      if (_isNexaDeviceDetected && !_forceWhisperOnlyMode) {
        _startNexaInitialization();
      }
      // Initialize Gemma after model checks
      if (!_forceWhisperOnlyMode) {
        await _initializeGemmaBeforeAR();
      }
    });
  }

  /// Check if the current device uses Nexa/Parakeet ASR (Snapdragon with NPU).
  /// On such devices, Whisper and Gemma are optional since Nexa SDK handles ASR/LLM.
  Future<bool> _isNexaDevice() async {
    if (_nexaDevice != null) return _nexaDevice!;
    if (kIsWeb || !Platform.isAndroid) {
      _nexaDevice = false;
      return false;
    }
    try {
      final registry = DeviceModelRegistry();
      final config = await registry.getDeviceConfig();
      _isAndroidXrDevice =
        config.formFactor == DeviceFormFactor.xrHeadset ||
        config.formFactor == DeviceFormFactor.arGlasses;
      _forceWhisperOnlyMode = Platform.isAndroid && _isAndroidXrDevice;

      // Nexa device if ASR model is Parakeet-based (not Whisper)
      _nexaDevice =
        !_forceWhisperOnlyMode && config.asrModel.name.startsWith('parakeet');
      _logger.i(
        '📱 Device config: ${config.deviceId}, formFactor: ${config.formFactor.name}, ASR: ${config.asrModel.name}, isNexa: $_nexaDevice, forceWhisperOnly: $_forceWhisperOnlyMode',
          category: LogCategory.system);
      return _nexaDevice!;
    } catch (e) {
      _logger.w('⚠️ Could not detect device config, assuming non-Nexa',
          category: LogCategory.system);
      _nexaDevice = false;
      return false;
    }
  }

  Future<void> _checkAndPromptModelDownload() async {
    _logger.d('🔍 Checking model availability on app startup...',
        category: LogCategory.system);

    // Check if this is a Nexa-capable device (Snapdragon with Parakeet ASR)
    final isNexa = await _isNexaDevice();

    // Check if optional models exist
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
        '📊 Model availability summary - Gemma: $gemmaExists, Whisper: $whisperExists, isNexaDevice: $isNexa',
        category: LogCategory.system);

    // On Nexa devices: Whisper and Gemma are optional (Nexa SDK handles ASR/LLM)
    // On iOS: Whisper not needed (Apple Speech), Gemma optional
    // On generic Android: Whisper required for ASR, Gemma required for enhancement
    final bool needsWhisper;
    final bool needsGemma;
    if (_forceWhisperOnlyMode) {
      needsWhisper = !kIsWeb;
      needsGemma = false;
    } else if (isNexa) {
      needsWhisper = false; // Nexa Parakeet handles ASR
      needsGemma = false;   // Nexa Granite/OmniNeural handles LLM
    } else if (!kIsWeb && Platform.isIOS) {
      needsWhisper = false;  // Apple Speech handles ASR
      needsGemma = true;     // Gemma needed for enhancement on iOS
    } else {
      needsWhisper = !kIsWeb; // Whisper needed on non-Nexa Android
      needsGemma = true;      // Gemma needed on non-Nexa Android
    }

    // Check if any required models are missing
    final hasMissingModels =
        (needsGemma && !gemmaExists) || (needsWhisper && !whisperExists);

    // Store model status for UI indicator (no blocking modal)
    if (mounted) {
      setState(() {
        _modelsMissing = hasMissingModels;
        _isNexaDeviceDetected = isNexa;
        _isWhisperModelAvailable = whisperExists;
      });
    }

    // Log status but DON'T show blocking modal
    // Users are guided to Settings → AI Models via onboarding tour
    if (hasMissingModels) {
      _logger.i(
          '📦 Models needed: Gemma=$needsGemma (exists: $gemmaExists), Whisper=$needsWhisper (exists: $whisperExists). '
          'User can download via Settings → AI Models.',
          category: LogCategory.system);
    } else if (isNexa) {
      _logger.i(
          '✅ Nexa device - models download automatically via SDK',
          category: LogCategory.system);
      // Whisper/Gemma if they want. Skip for now to not block.
    } else {
      _logger.i(
          '✅ All required models are available for this platform (Gemma: $needsGemma, Whisper: $needsWhisper, isNexa: $isNexa)',
          category: LogCategory.system);
    }
  }

  /// Initialize Gemma 3n service before caption session launch.
  /// On Nexa devices, this runs as fire-and-forget in the background since
  /// the Nexa LLM service handles text enhancement; Gemma is a bonus.
  Future<void> _initializeGemmaBeforeAR() async {
    if (_forceWhisperOnlyMode) {
      _logger.i('🎤 Whisper-only mode active (Android XR) - skipping Gemma init',
          category: LogCategory.gemma);
      return;
    }

    if (_isGemmaInitialized || _isGemmaInitializing) {
      _logger.i('🤖 Gemma already initialized or initializing, skipping',
          category: LogCategory.gemma);
      return;
    }

    final isNexa = await _isNexaDevice();

    if (!isNexa && _modelsMissing) {
      _logger.w(
          '⚠️ Skipping Gemma init because required models are missing; running captions without enhancement',
          category: LogCategory.gemma);
      return;
    }

    // On Nexa devices, skip Gemma entirely — Nexa SDK provides its own LLM
    if (isNexa) {
      _logger.i(
          '🤖 Nexa device detected - skipping Gemma init (using Nexa LLM instead)',
          category: LogCategory.gemma);
      return;
    }

    // On non-Nexa devices, initialize synchronously (blocks FAB until ready)
    await _initializeGemmaSync();
  }

  /// Synchronous Gemma init for non-Nexa devices
  Future<void> _initializeGemmaSync() async {
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

      if (mounted) setState(() {});

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
      if (mounted) setState(() {});
    }
  }

  /// Start all services needed for the caption session using the ARSessionCubit
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

      // Platform-specific STT setup
      if (!kIsWeb && Platform.isIOS) {
        _logger.i(
            '🔍 [HOME] Step 4: Setting up Apple Speech STT event listener...',
            category: LogCategory.ui);
        final appleSpeechService = sl<AppleSpeechService>();
        arSessionCubit.listenToAppleSpeechSTT(appleSpeechService);
        _logger.i(
            '✅ [HOME] Step 4 complete: Apple Speech STT event listener configured',
            category: LogCategory.speech);
      } else if (_nexaDevice == true) {
        _logger.i(
            '🔍 [HOME] Step 4: Setting up Nexa ASR STT event listener (Snapdragon device)...',
            category: LogCategory.ui);
        final nexaAsrService = sl<NexaAsrService>();
        arSessionCubit.listenToNexaASR(nexaAsrService);
        _logger.i(
            '✅ [HOME] Step 4 complete: Nexa ASR STT event listener configured',
            category: LogCategory.speech);
      } else {
        _logger.i('🔍 [HOME] Step 4: Setting up Whisper STT event listener...',
            category: LogCategory.ui);
        arSessionCubit.listenToWhisperSTT(whisperService);
        _logger.i(
            '✅ [HOME] Step 4 complete: Whisper STT event listener configured',
            category: LogCategory.speech);
      }

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
              '🎤 [HOME] Step 6c: Starting live captions...',
              category: LogCategory.captions);
            await liveCaptionsCubit.startCaptions();
            _logger.i(
              '✅ [HOME] Step 6c complete: Live captions started',
                category: LogCategory.captions);
          } else {
            _logger.i('🎤 [HOME] Step 6c: Live captions already active',
                category: LogCategory.captions);
          }
        },
        startSoundDetection: () async {
          final soundDetectionCubit = context.read<SoundDetectionCubit>();
          if (!soundDetectionCubit.isActive) {
            _logger.i('🔊 Starting sound detection...',
                category: LogCategory.audio);
            await soundDetectionCubit.start();
            _logger.i('✅ Sound detection started',
                category: LogCategory.audio);
          } else {
            _logger.i('🔊 Sound detection already active',
                category: LogCategory.audio);
          }
        },
        startLocalization: () async {
          final localizationCubit = context.read<LocalizationCubit>();
          if (!localizationCubit.isActive) {
            _logger.i('🧭 Starting localization...',
                category: LogCategory.ar);
            await localizationCubit.start();
            _logger.i('✅ Localization started',
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
            _logger.i('👁️ Starting visual identification...',
                category: LogCategory.camera);
            await visualIdentificationCubit.start();
            _logger.i('✅ Visual identification started',
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

  /// Start Nexa SDK initialization and listen to progress events
  void _startNexaInitialization() {
    if (_nexaInitializing || _nexaReady) return;
    _nexaInitializing = true;

    try {
      final nexaService = sl<NexaAsrService>();

      // Listen to Nexa events for progress
      _nexaEventSubscription = nexaService.nexaEvents.listen((event) {
        if (!mounted) return;
        setState(() {
          _nexaProgress = event.progress;
          _nexaStatusMessage = event.message;
          if (event.isComplete) {
            _nexaReady = true;
            _nexaInitializing = false;
          }
          if (event.error != null) {
            _nexaStatusMessage = 'Error: ${event.error}';
            _nexaInitializing = false;
          }
        });
      });

      // Fire-and-forget initialization
      nexaService.initialize(preferNpu: true).then((success) {
        if (mounted) {
          setState(() {
            _nexaReady = success;
            _nexaInitializing = false;
            if (success) {
              _nexaStatusMessage = 'Nexa ASR Ready';
              _nexaProgress = 1.0;
            }
          });
        }
      }).catchError((e) {
        _logger.e('❌ Nexa initialization failed', error: e);
        if (mounted) {
          setState(() {
            _nexaInitializing = false;
            _nexaStatusMessage = 'Initialization failed';
          });
        }
      });
    } catch (e) {
      _logger.e('❌ Could not start Nexa initialization', error: e);
      _nexaInitializing = false;
    }
  }

  /// Build NPU-specific bottom bar (replaces orange "models missing" bar)
  Widget _buildNexaBottomBar(BuildContext context) {
    final Color barColor = _nexaReady ? Colors.green.shade700 : Colors.blue.shade700;

    return Container(
      color: barColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Icon(
              _nexaReady ? Icons.check_circle : Icons.downloading,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _nexaReady
                    ? 'Nexa NPU ready — tap Start Captions'
                    : 'Setting up NPU models... ${(_nexaProgress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            if (!_nexaReady && _nexaProgress > 0)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: _nexaProgress,
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Pipeline status dashboard showing model status, spatial, and translation info
  Widget _buildPipelineStatusDashboard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(200),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              const Icon(Icons.dashboard, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              const Text(
                'Caption Pipeline',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              // Settings gear
              GestureDetector(
                onTap: () => context.push('/settings'),
                child: const Icon(Icons.settings, color: Colors.white54, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Model status row
          Row(
            children: [
              _buildStatusChip(
                label: 'ASR',
                ready: _isNexaDeviceDetected
                    ? _nexaReady
                    : (!kIsWeb && Platform.isIOS ? true : _isWhisperModelAvailable),
                loading: _isNexaDeviceDetected ? _nexaInitializing : false,
                icon: Icons.mic,
              ),
              const SizedBox(width: 8),
              _buildStatusChip(
                label: _forceWhisperOnlyMode ? 'LLM Off' : 'LLM',
                ready: _forceWhisperOnlyMode
                    ? false
                    : (_isGemmaInitialized || (_isNexaDeviceDetected && _nexaReady)),
                loading: _forceWhisperOnlyMode ? false : _isGemmaInitializing,
                icon: Icons.auto_awesome,
              ),
              const SizedBox(width: 8),
              _buildTranslationStatusChip(context),
              const SizedBox(width: 8),
              _buildLocalizationStatusChip(context),
            ],
          ),
          // Nexa NPU progress (if applicable)
          if (_isNexaDeviceDetected && !_nexaReady) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _nexaProgress > 0 ? _nexaProgress : null,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _nexaStatusMessage,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required bool ready,
    required bool loading,
    required IconData icon,
  }) {
    final Color color;
    final IconData statusIcon;
    if (ready) {
      color = Colors.greenAccent;
      statusIcon = Icons.check_circle;
    } else if (loading) {
      color = Colors.orangeAccent;
      statusIcon = Icons.hourglass_top;
    } else {
      color = Colors.grey;
      statusIcon = Icons.cancel_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(width: 3),
          Icon(statusIcon, color: color, size: 10),
        ],
      ),
    );
  }

  Widget _buildTranslationStatusChip(BuildContext context) {
    try {
      return BlocBuilder<TranslationCubit, TranslationState>(
        builder: (context, state) {
          final ready = state is TranslationReady && state.isEnabled;
          final loading = state is TranslationLoading;
          return _buildStatusChip(
            label: 'Trans',
            ready: ready,
            loading: loading,
            icon: Icons.translate,
          );
        },
      );
    } catch (_) {
      return _buildStatusChip(label: 'Trans', ready: false, loading: false, icon: Icons.translate);
    }
  }

  Widget _buildLocalizationStatusChip(BuildContext context) {
    return BlocBuilder<LocalizationCubit, LocalizationState>(
      builder: (context, state) {
        final active = state is LocalizationLoaded;
        return _buildStatusChip(
          label: 'Spatial',
          ready: active,
          loading: false,
          icon: Icons.spatial_audio,
        );
      },
    );
  }

  @override
  void dispose() {
    _nexaEventSubscription?.cancel();
    _directionUpdateSubscription?.cancel();
    if (_emulatorCameraPreviewActive) {
      try {
        sl<CameraService>().stopCamera();
      } catch (_) {}
    }
    _logger.i('🗑️ HomeScreen disposing...');
    super.dispose();
    _logger.d('✅ HomeScreen disposed successfully');
  }

  Future<void> _ensureEmulatorCameraPreviewStarted() {
    return _emulatorCameraStartFuture ??= (() async {
      final cameraService = sl<CameraService>();
      await cameraService.initialize();
      cameraService.startCamera();
      _emulatorCameraPreviewActive = true;
    })();
  }

  Widget _buildCameraOrFallback() {
    return FutureBuilder<bool>(
      future: isAndroidEmulator(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data == true) {
          _logger.w('🧪 Emulator detected: showing camera fallback.');
          final cameraService = sl<CameraService>();
          return FutureBuilder<void>(
            future: _ensureEmulatorCameraPreviewStarted(),
            builder: (context, camSnapshot) {
              if (camSnapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final preview = cameraService.getCameraPreviewWidget();
              if (preview != null) {
                final orientedPreview = RotatedBox(
                  quarterTurns: 1,
                  child: preview,
                );
                return Stack(
                  children: [
                    Positioned.fill(child: orientedPreview),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        color: Colors.black54,
                        padding: const EdgeInsets.all(16),
                        child: const Text(
                          'Emulator Camera Preview (Fallback)',
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
          // Real device: show start captions area
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.spatial_audio_off, color: Colors.white24, size: 100),
                const SizedBox(height: 16),
                const Text(
                  'Live Captions',
                  style: TextStyle(color: Colors.white54, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Real-time captions with speaker direction cues',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),
                const SizedBox(height: 32),
                // Big Start Captions button
                BlocBuilder<LiveCaptionsCubit, LiveCaptionsState>(
                  builder: (context, captionsState) {
                    final isActive = captionsState is LiveCaptionsActive && captionsState.isListening;
                    final isLoading = captionsState is LiveCaptionsLoading;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 220,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: isLoading ? null : () {
                              final cubit = context.read<LiveCaptionsCubit>();
                              if (isActive) {
                                cubit.stopCaptions();
                              } else {
                                cubit.startCaptions();
                              }
                            },
                            icon: isLoading
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Icon(isActive ? Icons.stop_circle : Icons.play_circle_fill, size: 28),
                            label: Text(
                              isLoading ? 'Starting...' : (isActive ? 'Stop Captions' : 'Start Captions'),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isActive ? Colors.red.shade700 : Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                              elevation: 4,
                            ),
                          ),
                        ),
                        // Live preview area when captions are active
                        if (isActive) ...[
                          const SizedBox(height: 20),
                          Container(
                            constraints: const BoxConstraints(maxWidth: 360),
                            child: LiveCaptionsWidget(
                              onToggle: () {
                                final cubit = context.read<LiveCaptionsCubit>();
                                if (isActive) {
                                  cubit.stopCaptions();
                                } else {
                                  cubit.startCaptions();
                                }
                              },
                              onClear: () => context.read<LiveCaptionsCubit>().clearCaptions(),
                              maxWidth: 360,
                              showHistory: true,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildMicLevelOverlay() {
    final speechProcessor = sl<EnhancedSpeechProcessor>();
    return StreamBuilder<double>(
      stream: speechProcessor.micLevels,
      initialData: 0.0,
      builder: (context, snapshot) {
        final level = (snapshot.data ?? 0.0).clamp(0.0, 1.0);
        final threshold = 0.012;
        final aboveThreshold = level >= threshold;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: aboveThreshold ? Colors.greenAccent : Colors.orangeAccent,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mic level ${aboveThreshold ? 'OK' : 'Low'}',
                style: TextStyle(
                  color: aboveThreshold ? Colors.greenAccent : Colors.orangeAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 110,
                child: LinearProgressIndicator(
                  value: level,
                  minHeight: 6,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    aboveThreshold ? Colors.greenAccent : Colors.orangeAccent,
                  ),
                ),
              ),
            ],
          ),
        );
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
            final liveCaptionsState = context.watch<LiveCaptionsCubit>().state;
            final hideStatusChrome =
                liveCaptionsState is LiveCaptionsActive && liveCaptionsState.isListening;

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

                      if (!hideStatusChrome)
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 8,
                          left: 0,
                          right: 0,
                          child: _buildPipelineStatusDashboard(context),
                        ),

                      if (!hideStatusChrome)
                        BlocBuilder<ARSessionCubit, ARSessionState>(
                          builder: (context, arSessionState) {
                            if (arSessionState is! ARSessionInitial) {
                              return Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: ARSessionStatusWidget(
                                  showCloseButton:
                                      arSessionState is ARSessionReady,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),

                      BlocBuilder<ARSessionCubit, ARSessionState>(
                        builder: (context, arSessionState) {
                          final inARMode = arSessionState is ARSessionReady;
                          // Only log significant state changes
                          return BlocBuilder<LiveCaptionsCubit,
                              LiveCaptionsState>(
                            builder: (context, captionsState) {
                              // Removed verbose caption state logging
                              // Removed verbose caption details logging

                              // Only show overlay when in spatial mode and captions are active
                              // or when explicitly requested for fallback
                              bool showOverlay = false;
                              if (captionsState is LiveCaptionsActive &&
                                  captionsState.isListening) {
                                showOverlay = inARMode ||
                                    captionsState.showOverlayFallback ||
                                    arSessionState is ARSessionError ||
                                    arSessionState is ARSessionInitial ||
                                    arSessionState is ARSessionTrackingLost;
                                if (showOverlay) {
                                  _logger.i(
                                    '🎯 [UI] Showing captions overlay (${inARMode ? 'spatial' : 'fallback'})',
                                    category: LogCategory.ui,
                                  );
                                }
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
                                          if (cubit.state
                                                  is LiveCaptionsActive &&
                                              (cubit.state
                                                      as LiveCaptionsActive)
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
                        child: BlocBuilder<SoundDetectionCubit,
                            SoundDetectionState>(
                          builder: (context, state) {
                            if (state is SoundDetectionLoaded &&
                                state.events.isNotEmpty) {
                              final SoundEvent event = state.events.last;
                              return Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue
                                      .withAlpha((255 * 0.8).round()),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.hearing,
                                        color: Colors.white),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${event.type} (${(event.confidence * 100).toStringAsFixed(0)}%)',
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
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
                        child:
                            BlocBuilder<LocalizationCubit, LocalizationState>(
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
                                  Icon(arrowIcon,
                                      color: Colors.orange, size: 64),
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

                      BlocBuilder<LiveCaptionsCubit, LiveCaptionsState>(
                        builder: (context, captionsState) {
                          final isActive =
                              captionsState is LiveCaptionsActive && captionsState.isListening;
                          if (!isActive) return const SizedBox.shrink();
                          return Positioned(
                            top: MediaQuery.of(context).padding.top + 12,
                            right: 12,
                            child: _buildMicLevelOverlay(),
                          );
                        },
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
                                  color: Colors.black
                                      .withAlpha((255 * 0.3).round()),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.visibility,
                                        color: Colors.greenAccent),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${obj.label} (${(obj.confidence * 100).toStringAsFixed(0)}%)',
                                        style: const TextStyle(
                                            color: Colors.greenAccent),
                                      ),
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
                    // Hide extra status bars while captions are active.
                    bottomNavigationBar: hideStatusChrome
                      ? null
                      : (_isNexaDeviceDetected
                        ? _buildNexaBottomBar(context)
                        : null),
                      // Unified Start/Stop button
                  floatingActionButton:
                      BlocListener<ARSessionCubit, ARSessionState>(
                    listener: (context, state) {
                      if (state is ARSessionReady) {
                        _logger.i(
                            '🔄 Spatial session ready. Services should already be started.');
                      } else if (state is ARSessionError) {
                        _logger.e('❌ Session error: ${state.message}');
                      } else if (state is ARSessionInitial) {
                        // Session was closed - ensure all services are stopped
                        _logger.i('✅ Session closed and all services stopped');

                        // Double-check that live captions are stopped
                        final liveCaptionsCubit =
                            context.read<LiveCaptionsCubit>();
                        if (liveCaptionsCubit.state is LiveCaptionsActive &&
                            (liveCaptionsCubit.state as LiveCaptionsActive)
                                .isListening) {
                            _logger.w(
                              '⚠️ Live captions still active after session end, stopping...');
                          liveCaptionsCubit.stopCaptions();
                        }

                        // Double-check that other services are stopped
                        final soundDetectionCubit =
                            context.read<SoundDetectionCubit>();
                        if (soundDetectionCubit.isActive) {
                            _logger.w(
                              '⚠️ Sound detection still active after session end, stopping...');
                          soundDetectionCubit.stop();
                        }

                        final localizationCubit =
                            context.read<LocalizationCubit>();
                        if (localizationCubit.isActive) {
                            _logger.w(
                              '⚠️ Localization still active after session end, stopping...');
                          localizationCubit.stop();
                        }

                        final visualIdentificationCubit =
                            context.read<VisualIdentificationCubit>();
                        if (visualIdentificationCubit.isActive) {
                            _logger.w(
                              '⚠️ Visual identification still active after session end, stopping...');
                          visualIdentificationCubit.stop();
                        }

                        _logger.i(
                          '✅ All services verified as stopped after session end');
                      }
                    },
                    child: BlocBuilder<LiveCaptionsCubit, LiveCaptionsState>(
                      builder: (context, captionsState) {
                        final isActive = captionsState is LiveCaptionsActive && captionsState.isListening;
                        final isLoading = captionsState is LiveCaptionsLoading;

                        return FloatingActionButton.extended(
                          heroTag: "unified_captions_fab",
                          backgroundColor: isActive ? Colors.red.shade700 : Colors.blue.shade700,
                          onPressed: isLoading
                              ? null
                              : () async {
                                  if (isActive) {
                                    // Stop everything
                                    _logger.i('⏹️ Stop Captions pressed', category: LogCategory.ui);
                                    final arSessionCubit = context.read<ARSessionCubit>();
                                    if (arSessionCubit.state is ARSessionReady) {
                                      await arSessionCubit.stopARSession();
                                    }
                                    context.read<LiveCaptionsCubit>().stopCaptions();
                                  } else {
                                    // Start captions + spatial session if available
                                    _logger.i('▶️ Start Captions pressed', category: LogCategory.ui);
                                    try {
                                      if (_nexaDevice != true &&
                                          !_modelsMissing &&
                                          !_isGemmaInitialized &&
                                          !_isGemmaInitializing) {
                                        await _initializeGemmaBeforeAR();
                                      }
                                      await _startAllServicesForARMode();
                                      // Try to start spatial session
                                      // Falls back to flat captions if AR unavailable
                                      try {
                                        final arSessionCubit = context.read<ARSessionCubit>();
                                        await arSessionCubit.initializeARSession(
                                            restoreFromPersistence: false);
                                      } catch (arError) {
                                        _logger.w('⚠️ Spatial session not available, using standard captions: $arError',
                                            category: LogCategory.ar);
                                      }
                                    } catch (e, stackTrace) {
                                      _logger.e('❌ Failed to start captions',
                                          error: e, stackTrace: stackTrace);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('❌ Failed to start: ${e.toString()}'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                          icon: isLoading
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Icon(isActive ? Icons.stop_circle : Icons.play_circle_fill),
                          label: Text(
                            isLoading ? 'Starting...' : (isActive ? 'Stop' : 'Start Captions'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
