import 'package:get_it/get_it.dart';
import 'package:live_captions_xr/core/services/audio_capture_service.dart';
import 'package:live_captions_xr/core/services/ar_anchor_manager.dart';
import 'package:live_captions_xr/core/services/camera_service.dart';
import 'package:live_captions_xr/core/services/google_auth_service.dart';
import 'package:live_captions_xr/core/services/hybrid_localization_engine.dart';
import 'package:live_captions_xr/core/services/ar_session_persistence_service.dart';
import 'package:live_captions_xr/core/services/gemma3n_service.dart';
import 'package:live_captions_xr/core/services/model_download_manager.dart';
import 'package:live_captions_xr/features/live_captions/cubit/live_captions_cubit.dart';
import 'package:live_captions_xr/core/services/enhanced_speech_processor.dart';
import 'package:live_captions_xr/core/services/whisper_service.dart';
import 'package:live_captions_xr/features/sound_detection/cubit/sound_detection_cubit.dart';
import 'package:live_captions_xr/features/visual_identification/cubit/visual_identification_cubit.dart';
import 'package:live_captions_xr/features/settings/cubit/settings_cubit.dart';
import 'package:live_captions_xr/core/models/speech_config.dart';
// ... imports

final sl = GetIt.instance;

void setupServiceLocator() {
// ... existing registrations
  if (!sl.isRegistered<ModelDownloadManager>()) {
    sl.registerLazySingleton<ModelDownloadManager>(() => ModelDownloadManager());
  }
  if (!sl.isRegistered<Gemma3nService>()) {
    sl.registerLazySingleton<Gemma3nService>(() => Gemma3nService());
  }
  if (!sl.isRegistered<WhisperService>()) {
    sl.registerLazySingleton<WhisperService>(() => WhisperService(
      modelDownloadManager: sl<ModelDownloadManager>(),
    ));
  }
  if (!sl.isRegistered<EnhancedSpeechProcessor>()) {
    sl.registerLazySingleton<EnhancedSpeechProcessor>(
      () => EnhancedSpeechProcessor(
        gemma3nService: sl<Gemma3nService>(),
        audioCaptureService: sl<AudioCaptureService>(),
        whisperService: sl<WhisperService>(),
      ),
    );
  }
  if (!sl.isRegistered<LiveCaptionsCubit>()) {
    sl.registerLazySingleton<LiveCaptionsCubit>(
      () => LiveCaptionsCubit(
        speechProcessor: sl<EnhancedSpeechProcessor>(),
        hybridLocalizationEngine: sl<HybridLocalizationEngine>(),
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
  if (!sl.isRegistered<GoogleAuthService>()) {
    sl.registerLazySingleton<GoogleAuthService>(() => GoogleAuthService());
  }
  if (!sl.isRegistered<AudioCaptureService>()) {
    sl.registerLazySingleton<AudioCaptureService>(() => AudioCaptureService());
  }
  if (!sl.isRegistered<CameraService>()) {
    sl.registerLazySingleton<CameraService>(() => CameraService());
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
  // Register SettingsCubit
  if (!sl.isRegistered<SettingsCubit>()) {
    sl.registerFactory<SettingsCubit>(() => SettingsCubit(
      speechProcessor: sl<EnhancedSpeechProcessor>(),
    ));
  }
  // ... existing registrations
}
