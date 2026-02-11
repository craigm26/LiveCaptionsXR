import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get_it/get_it.dart';
import 'package:live_captions_xr/core/services/audio_capture_service.dart';
import 'package:live_captions_xr/core/services/ar_anchor_manager.dart';
import 'package:live_captions_xr/core/services/camera_service.dart';
import 'package:live_captions_xr/core/services/ar_frame_service.dart';
import 'package:live_captions_xr/core/services/frame_capture_service.dart';
import 'package:live_captions_xr/core/services/google_auth_service.dart';
import 'package:live_captions_xr/core/services/hybrid_localization_engine.dart';
import 'package:live_captions_xr/core/services/ar_session_persistence_service.dart';
import 'package:live_captions_xr/core/services/gemma_3n_service.dart';
import 'package:live_captions_xr/core/services/apple_speech_service.dart';
import 'package:live_captions_xr/core/services/model_download_manager.dart';
import 'package:live_captions_xr/features/live_captions/cubit/live_captions_cubit.dart';
import 'package:live_captions_xr/core/services/enhanced_speech_processor.dart';
import 'package:live_captions_xr/core/services/whisper_service_impl.dart';
import 'package:live_captions_xr/features/sound_detection/cubit/sound_detection_cubit.dart';
import 'package:live_captions_xr/features/visual_identification/cubit/visual_identification_cubit.dart';
import 'package:live_captions_xr/features/settings/cubit/settings_cubit.dart';
import 'package:live_captions_xr/core/models/speech_config.dart';
import 'package:live_captions_xr/core/services/speech_localizer.dart';
import 'package:live_captions_xr/core/services/spatial_caption_integration_service.dart';
import 'package:spatial_captions/cubit/spatial_captions_cubit.dart';
import 'package:live_captions_xr/core/services/app_logger.dart';
import 'package:live_captions_xr/core/services/nexa_asr_service.dart';
import 'package:live_captions_xr/core/services/nexa_llm_service.dart';
import 'package:live_captions_xr/core/models/device_model_config.dart';
import 'package:live_captions_xr/core/services/download/download_state_persistence.dart';
import 'package:live_captions_xr/core/services/download/unified_download_manager.dart';
import 'package:live_captions_xr/core/services/ios_model_config_service.dart';
import 'package:live_captions_xr/core/services/translation_service.dart';
import 'package:live_captions_xr/features/translation/cubit/translation_cubit.dart';
import 'package:live_captions_xr/core/services/speaker_diarization_service.dart';

final sl = GetIt.instance;

void setupServiceLocator() {
  final logger = AppLogger.instance;
// ... existing registrations
  if (!sl.isRegistered<ModelDownloadManager>()) {
    sl.registerLazySingleton<ModelDownloadManager>(() => ModelDownloadManager());
  }
  if (!sl.isRegistered<Gemma3nService>()) {
    sl.registerLazySingleton<Gemma3nService>(() => Gemma3nService(
    modelManager: sl<ModelDownloadManager>(),
  ));
  }
  if (!sl.isRegistered<WhisperService>()) {
    sl.registerLazySingleton<WhisperService>(() => WhisperService(
      modelDownloadManager: sl<ModelDownloadManager>(),
    ));
  }
  if (!sl.isRegistered<AppleSpeechService>()) {
    logger.d('🍎 Registering AppleSpeechService in service locator', category: LogCategory.system);
    sl.registerLazySingleton<AppleSpeechService>(() {
      logger.d('🍎 Creating AppleSpeechService instance', category: LogCategory.system);
      return AppleSpeechService();
    });
  }
  // Register DeviceModelRegistry for device-specific model selection
  if (!sl.isRegistered<DeviceModelRegistry>()) {
    logger.d('📱 Registering DeviceModelRegistry in service locator', category: LogCategory.system);
    sl.registerLazySingleton<DeviceModelRegistry>(() {
      logger.d('📱 Creating DeviceModelRegistry instance', category: LogCategory.system);
      return DeviceModelRegistry();
    });
  }

  // Register DownloadStatePersistence for crash recovery
  if (!sl.isRegistered<DownloadStatePersistence>()) {
    logger.d('💾 Registering DownloadStatePersistence in service locator', category: LogCategory.system);
    sl.registerLazySingleton<DownloadStatePersistence>(() {
      logger.d('💾 Creating DownloadStatePersistence instance', category: LogCategory.system);
      return DownloadStatePersistence();
    });
  }

  // Register UnifiedDownloadManager for package-native model downloads
  if (!sl.isRegistered<UnifiedDownloadManager>()) {
    logger.d('📥 Registering UnifiedDownloadManager in service locator', category: LogCategory.system);
    sl.registerLazySingleton<UnifiedDownloadManager>(() {
      logger.d('📥 Creating UnifiedDownloadManager instance', category: LogCategory.system);
      return UnifiedDownloadManager(
        deviceRegistry: sl<DeviceModelRegistry>(),
        legacyManager: sl<ModelDownloadManager>(),
        statePersistence: sl<DownloadStatePersistence>(),
      );
    });
  }

  // Register Nexa SDK services for NPU-accelerated AI (Android only, not web)
  if (!kIsWeb) {
    if (!sl.isRegistered<NexaAsrService>()) {
      logger.d('🚀 Registering NexaAsrService in service locator', category: LogCategory.system);
      sl.registerLazySingleton<NexaAsrService>(() {
        logger.d('🚀 Creating NexaAsrService instance', category: LogCategory.system);
        return NexaAsrService();
      });
    }
    if (!sl.isRegistered<NexaLlmService>()) {
      logger.d('🚀 Registering NexaLlmService in service locator', category: LogCategory.system);
      sl.registerLazySingleton<NexaLlmService>(() {
        logger.d('🚀 Creating NexaLlmService instance', category: LogCategory.system);
        return NexaLlmService();
      });
    }
    // Register TranslationService (depends on NexaLlmService)
    if (!sl.isRegistered<TranslationService>()) {
      logger.d('🌐 Registering TranslationService in service locator', category: LogCategory.system);
      sl.registerLazySingleton<TranslationService>(() {
        logger.d('🌐 Creating TranslationService instance', category: LogCategory.system);
        return TranslationService(
          nexaLlmService: sl<NexaLlmService>(),
        );
      });
    }
    // Register TranslationCubit
    if (!sl.isRegistered<TranslationCubit>()) {
      logger.d('🌐 Registering TranslationCubit in service locator', category: LogCategory.system);
      sl.registerLazySingleton<TranslationCubit>(() {
        logger.d('🌐 Creating TranslationCubit instance', category: LogCategory.system);
        return TranslationCubit(
          translationService: sl<TranslationService>(),
        );
      });
    }
  }
  if (!sl.isRegistered<EnhancedSpeechProcessor>()) {
    logger.d('🔧 Registering EnhancedSpeechProcessor in service locator', category: LogCategory.system);
    sl.registerLazySingleton<EnhancedSpeechProcessor>(
      () {
        logger.d('🔧 Creating EnhancedSpeechProcessor instance', category: LogCategory.system);
        logger.d('🍎 Getting AppleSpeechService from service locator', category: LogCategory.system);
        final appleSpeech = sl<AppleSpeechService>();
        logger.d('🍎 AppleSpeechService retrieved: ${appleSpeech.runtimeType}', category: LogCategory.system);

        logger.d('🔧 Getting Gemma3nService...', category: LogCategory.system);
        final gemma = sl<Gemma3nService>();
        logger.d('🔧 Gemma3nService OK', category: LogCategory.system);

        logger.d('🔧 Getting AudioCaptureService...', category: LogCategory.system);
        final audio = sl<AudioCaptureService>();
        logger.d('🔧 AudioCaptureService OK', category: LogCategory.system);

        logger.d('🔧 Getting WhisperService...', category: LogCategory.system);
        final whisper = sl<WhisperService>();
        logger.d('🔧 WhisperService OK', category: LogCategory.system);

        logger.d('🔧 Getting FrameCaptureService...', category: LogCategory.system);
        final frame = sl<FrameCaptureService>();
        logger.d('🔧 FrameCaptureService OK', category: LogCategory.system);

        // Get Nexa services if available (Android only, not web)
        NexaAsrService? nexaAsr;
        NexaLlmService? nexaLlm;
        if (!kIsWeb) {
          logger.d('🚀 Getting NexaAsrService...', category: LogCategory.system);
          nexaAsr = sl.isRegistered<NexaAsrService>() ? sl<NexaAsrService>() : null;
          logger.d('🚀 NexaAsrService: ${nexaAsr != null ? "OK" : "not available"}', category: LogCategory.system);

          logger.d('🚀 Getting NexaLlmService...', category: LogCategory.system);
          nexaLlm = sl.isRegistered<NexaLlmService>() ? sl<NexaLlmService>() : null;
          logger.d('🚀 NexaLlmService: ${nexaLlm != null ? "OK" : "not available"}', category: LogCategory.system);
        }

        logger.d('🔧 About to create EnhancedSpeechProcessor with all services...', category: LogCategory.system);
        final processor = EnhancedSpeechProcessor(
          gemma3nService: gemma,
          audioCaptureService: audio,
          whisperService: whisper,
          appleSpeechService: appleSpeech,
          frameCaptureService: frame,
          nexaAsrService: nexaAsr,
          nexaLlmService: nexaLlm,
        );
        logger.d('🔧 EnhancedSpeechProcessor created successfully!', category: LogCategory.system);
        return processor;
      },
    );
  }
  if (!sl.isRegistered<LiveCaptionsCubit>()) {
    sl.registerLazySingleton<LiveCaptionsCubit>(
      () => LiveCaptionsCubit(
        speechProcessor: sl<EnhancedSpeechProcessor>(),
        hybridLocalizationEngine: sl<HybridLocalizationEngine>(),
        spatialCaptionIntegrationService: sl<SpatialCaptionIntegrationService>(),
        useEnhancement: true,
        speechConfig: const SpeechConfig(), // Pass default config with whisper settings
      ),
    );
  }
  if (!sl.isRegistered<SoundDetectionCubit>()) {
    sl.registerFactory<SoundDetectionCubit>(() => SoundDetectionCubit());
  }
  if (!sl.isRegistered<VisualIdentificationCubit>()) {
    sl.registerFactory<VisualIdentificationCubit>(() => VisualIdentificationCubit(
      hybridLocalizationEngine: sl<HybridLocalizationEngine>(),
    ));
  }
  // Skip GoogleAuthService on web (requires OAuth client ID configuration)
  if (!kIsWeb && !sl.isRegistered<GoogleAuthService>()) {
    sl.registerLazySingleton<GoogleAuthService>(() => GoogleAuthService());
  }
  if (!sl.isRegistered<AudioCaptureService>()) {
    sl.registerLazySingleton<AudioCaptureService>(() => AudioCaptureService());
  }
  if (!sl.isRegistered<CameraService>()) {
    sl.registerLazySingleton<CameraService>(() => CameraService());
  }
  if (!sl.isRegistered<ARFrameService>()) {
    sl.registerLazySingleton<ARFrameService>(() => ARFrameService());
  }
  if (!sl.isRegistered<FrameCaptureService>()) {
    sl.registerLazySingleton<FrameCaptureService>(() => FrameCaptureService());
  }
  if (!sl.isRegistered<ARAnchorManager>()) {
    sl.registerLazySingleton<ARAnchorManager>(() => ARAnchorManager());
  }
  if (!sl.isRegistered<HybridLocalizationEngine>()) {
    sl.registerLazySingleton<HybridLocalizationEngine>(() => HybridLocalizationEngine());
  }
  if (!sl.isRegistered<ARSessionPersistenceService>()) {
    sl.registerLazySingleton<ARSessionPersistenceService>(() => ARSessionPersistenceService());
  }
  // Register SpeechLocalizer
  if (!sl.isRegistered<SpeechLocalizer>()) {
    sl.registerLazySingleton<SpeechLocalizer>(() => SpeechLocalizer());
  }
  // Register SpatialCaptionsCubit
  if (!sl.isRegistered<SpatialCaptionsCubit>()) {
    sl.registerLazySingleton<SpatialCaptionsCubit>(() => SpatialCaptionsCubit());
  }
  // Register SpeakerDiarizationService for 3D/4D spatial speaker tracking
  if (!sl.isRegistered<SpeakerDiarizationService>()) {
    logger.d('🎙️ Registering SpeakerDiarizationService in service locator', category: LogCategory.system);
    sl.registerLazySingleton<SpeakerDiarizationService>(() {
      logger.d('🎙️ Creating SpeakerDiarizationService instance', category: LogCategory.system);
      return SpeakerDiarizationService(
        speechLocalizer: sl<SpeechLocalizer>(),
      );
    });
  }
  // Register SpatialCaptionIntegrationService (with speaker diarization)
  if (!sl.isRegistered<SpatialCaptionIntegrationService>()) {
    sl.registerLazySingleton<SpatialCaptionIntegrationService>(
      () => SpatialCaptionIntegrationService(
        spatialCaptionsCubit: sl<SpatialCaptionsCubit>(),
        speechLocalizer: sl<SpeechLocalizer>(),
        gemmaService: sl<Gemma3nService>(),
        hybridLocalizationEngine: sl<HybridLocalizationEngine>(),
        speakerDiarizationService: sl<SpeakerDiarizationService>(),
      ),
    );
  }
  // Register SettingsCubit
  if (!sl.isRegistered<SettingsCubit>()) {
    sl.registerFactory<SettingsCubit>(() => SettingsCubit(
      speechProcessor: sl<EnhancedSpeechProcessor>(),
    ));
  }
  // ... existing registrations
}
