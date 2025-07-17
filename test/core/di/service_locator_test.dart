import 'package:flutter_test/flutter_test.dart';
import 'package:live_captions_xr/core/di/service_locator.dart';
import 'package:live_captions_xr/core/services/hybrid_localization_engine.dart';
import 'package:live_captions_xr/core/services/ar_anchor_manager.dart';

import 'package:live_captions_xr/core/services/camera_service.dart';
import 'package:live_captions_xr/core/services/ar_session_persistence_service.dart';
import 'package:live_captions_xr/features/sound_detection/cubit/sound_detection_cubit.dart';
import 'package:live_captions_xr/features/visual_identification/cubit/visual_identification_cubit.dart';

void main() {
  group('Service Locator', () {
    setUp(() {
      // Reset service locator before each test
      sl.reset();
    });

    tearDown(() {
      // Clean up after each test
      sl.reset();
    });

    test('setupServiceLocator registers all services', () {
      // Act
      setupServiceLocator();

      // Assert - Core singleton services
      expect(sl.isRegistered<HybridLocalizationEngine>(), true);
      expect(sl.isRegistered<ARAnchorManager>(), true);
      
      expect(sl.isRegistered<CameraService>(), true);
      expect(sl.isRegistered<ARSessionPersistenceService>(), true);
      
      // Assert - Factory services
      expect(sl.isRegistered<SoundDetectionCubit>(), true);
      expect(sl.isRegistered<VisualIdentificationCubit>(), true);
    });

    test('singleton services return same instance', () {
      // Arrange
      setupServiceLocator();

      // Act & Assert - Verify singletons return identical instances
      final hybridEngine1 = sl<HybridLocalizationEngine>();
      final hybridEngine2 = sl<HybridLocalizationEngine>();
      expect(identical(hybridEngine1, hybridEngine2), true);
      
      final anchorManager1 = sl<ARAnchorManager>();
      final anchorManager2 = sl<ARAnchorManager>();
      expect(identical(anchorManager1, anchorManager2), true);
      
      final persistence1 = sl<ARSessionPersistenceService>();
      final persistence2 = sl<ARSessionPersistenceService>();
      expect(identical(persistence1, persistence2), true);
    });

    test('factory services return new instances', () {
      // Arrange
      setupServiceLocator();

      // Act & Assert - Verify factories return different instances
      final cubit1 = sl<SoundDetectionCubit>();
      final cubit2 = sl<SoundDetectionCubit>();
      expect(identical(cubit1, cubit2), false);
      
      final visualCubit1 = sl<VisualIdentificationCubit>();
      final visualCubit2 = sl<VisualIdentificationCubit>();
      expect(identical(visualCubit1, visualCubit2), false);
    });

    test('HybridLocalizationEngine is registered as lazy singleton', () {
      // Arrange
      setupServiceLocator();

      // Act - Get the instance
      final instance = sl<HybridLocalizationEngine>();

      // Assert
      expect(instance, isA<HybridLocalizationEngine>());
    });

    test('can resolve all services after setup', () {
      // Arrange
      setupServiceLocator();

      // Act & Assert - Should not throw
      expect(() => sl<HybridLocalizationEngine>(), returnsNormally);
      expect(() => sl<ARAnchorManager>(), returnsNormally);
      
      expect(() => sl<CameraService>(), returnsNormally);
      expect(() => sl<ARSessionPersistenceService>(), returnsNormally);
      expect(() => sl<SoundDetectionCubit>(), returnsNormally);
      expect(() => sl<VisualIdentificationCubit>(), returnsNormally);
    });

    test('throws error when trying to resolve unregistered service', () {
      // Arrange - Don't call setupServiceLocator

      // Act & Assert
      expect(() => sl<HybridLocalizationEngine>(), throwsA(isA<StateError>()));
    });
  });
}