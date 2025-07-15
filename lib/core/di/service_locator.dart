import '../services/gemma3n_service.dart';
import '../services/visual_service.dart';
import 'package:get_it/get_it.dart';
import '../services/hybrid_localization_engine.dart';
import '../services/ar_anchor_manager.dart';
import '../services/audio_service.dart';
import '../services/visual_identification_service.dart';
import '../services/localization_service.dart';
import '../services/camera_service.dart';
import '../services/speech_processor.dart';
import '../services/ar_session_persistence_service.dart';
import '../services/native_stt_service.dart';
import '../services/contextual_enhancer.dart';
import '../../features/sound_detection/cubit/sound_detection_cubit.dart';
import '../../features/visual_identification/cubit/visual_identification_cubit.dart';

final sl = GetIt.instance;

/// Set up dependency injection for all services
void setupServiceLocator() {
  // Core services
  sl.registerLazySingleton<HybridLocalizationEngine>(
    () => HybridLocalizationEngine(),
  );

  sl.registerLazySingleton<ARAnchorManager>(
    () => ARAnchorManager(),
  );

  sl.registerLazySingleton<LocalizationService>(
    () => LocalizationService(),
  );

  sl.registerLazySingleton<CameraService>(
    () => CameraService(),
  );

  sl.registerLazySingleton<ARSessionPersistenceService>(
    () => ARSessionPersistenceService(),
  );

  sl.registerLazySingleton<Gemma3nService>(
    () => Gemma3nService(),
  );

  sl.registerLazySingleton<VisualService>(
    () => VisualService(),
  );

  sl.registerLazySingleton<NativeSttService>(
    () => NativeSttService(),
  );

  sl.registerLazySingleton<ContextualEnhancer>(
    () => ContextualEnhancer(sl<Gemma3nService>(), sl<VisualService>()),
  );

  sl.registerLazySingleton<SpeechProcessor>(
    () => SpeechProcessor(),
  );

  

  // Services that depend on cubits need to be registered as factories
  // since cubits are created fresh for each screen
  sl.registerFactory<AudioService>(
    () => AudioService(
      soundDetectionCubit: sl<SoundDetectionCubit>(),
      hybridLocalizationEngine: sl<HybridLocalizationEngine>(),
    ),
  );

  sl.registerFactory<VisualIdentificationService>(
    () => VisualIdentificationService(sl<VisualIdentificationCubit>()),
  );

  // Register cubits as factories (they should be fresh for each usage)
  sl.registerFactory<SoundDetectionCubit>(
    () => SoundDetectionCubit(),
  );

  sl.registerFactory<VisualIdentificationCubit>(
    () => VisualIdentificationCubit(
      hybridLocalizationEngine: sl<HybridLocalizationEngine>(),
    ),
  );
}
