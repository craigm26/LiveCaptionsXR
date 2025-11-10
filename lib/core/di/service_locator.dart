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
// ... imports

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
        
        logger.d('🔧 About to create EnhancedSpeechProcessor with all services...', category: LogCategory.system);
        final processor = EnhancedSpeechProcessor(
          gemma3nService: gemma,
          audioCaptureService: audio,
          whisperService: whisper,
          appleSpeechService: appleSpeech,
          frameCaptureService: frame,
        );
        logger.d('🔧 EnhancedSpeechProcessor created successfully!', category: LogCategory.system);
        return processor;
      },
    );
  }
  if (!sl.isRegistered<LiveCaptionsCubit>()) {
    final passThroughConfig = SpeechConfig.lowLatency.copyWith(
      enableRealTimeEnhancement: false,
    );
    sl.registerLazySingleton<LiveCaptionsCubit>(
      () => LiveCaptionsCubit(
        speechProcessor: sl<EnhancedSpeechProcessor>(),
        hybridLocalizationEngine: sl<HybridLocalizationEngine>(),
        spatialCaptionIntegrationService: sl<SpatialCaptionIntegrationService>(),
        useEnhancement: false,
        speechConfig: passThroughConfig,
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
  if (!sl.isRegistered<GoogleAuthService>()) {
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
  // Register SpatialCaptionIntegrationService
  if (!sl.isRegistered<SpatialCaptionIntegrationService>()) {
    sl.registerLazySingleton<SpatialCaptionIntegrationService>(
      () => SpatialCaptionIntegrationService(
        spatialCaptionsCubit: sl<SpatialCaptionsCubit>(),
        speechLocalizer: sl<SpeechLocalizer>(),
        gemmaService: sl<Gemma3nService>(),
        hybridLocalizationEngine: sl<HybridLocalizationEngine>(),
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
