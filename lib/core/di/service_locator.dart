import 'package:get_it/get_it.dart';
import '../services/hybrid_localization_engine.dart';

final sl = GetIt.instance;

/// Set up dependency injection for all services
void setupServiceLocator() {
  // Register HybridLocalizationEngine as a singleton
  // This ensures all parts of the app use the same instance
  sl.registerLazySingleton<HybridLocalizationEngine>(
    () => HybridLocalizationEngine(),
  );
} 