import 'package:live_captions_xr/core/services/google_auth_service.dart';
// ... imports

void setupServiceLocator() {
  // ... existing registrations
  sl.registerLazySingleton<GoogleAuthService>(() => GoogleAuthService());
  // ... existing registrations
}
