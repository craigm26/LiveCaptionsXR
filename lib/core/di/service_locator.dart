import 'package:get_it/get_it.dart';
import 'package:live_captions_xr/core/services/audio_capture_service.dart';
import 'package:live_captions_xr/core/services/google_auth_service.dart';
// ... imports

final sl = GetIt.instance;

void setupServiceLocator() {
  // ... existing registrations
  sl.registerLazySingleton<GoogleAuthService>(() => GoogleAuthService());
  sl.registerLazySingleton<AudioCaptureService>(() => AudioCaptureService());
  // ... existing registrations
}
