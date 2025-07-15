import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:live_captions_xr/features/ar_session/cubit/ar_session_cubit.dart';
import 'package:live_captions_xr/core/services/hybrid_localization_engine.dart';
import 'package:live_captions_xr/core/services/ar_session_persistence_service.dart';

// Generate mocks
@GenerateNiceMocks([
  MockSpec<HybridLocalizationEngine>(),
  MockSpec<ARSessionPersistenceService>(),
])
import 'ar_session_cleanup_test.mocks.dart';

void main() {
  group('AR Session Cleanup Tests', () {
    late ARSessionCubit cubit;
    late MockHybridLocalizationEngine mockHybridEngine;
    late MockARSessionPersistenceService mockPersistenceService;

    setUp(() {
      mockHybridEngine = MockHybridLocalizationEngine();
      mockPersistenceService = MockARSessionPersistenceService();
      
      cubit = ARSessionCubit(
        hybridLocalizationEngine: mockHybridEngine,
        persistenceService: mockPersistenceService,
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('stopARSession should handle service cleanup with timeouts', () async {
      // Arrange
      bool liveCaptionsStopped = false;
      bool soundDetectionStopped = false;
      bool localizationStopped = false;
      bool visualIdentificationStopped = false;

      // Mock service stop functions that complete successfully
      Future<void> stopLiveCaptions() async {
        await Future.delayed(const Duration(milliseconds: 100));
        liveCaptionsStopped = true;
      }

      Future<void> stopSoundDetection() async {
        await Future.delayed(const Duration(milliseconds: 150));
        soundDetectionStopped = true;
      }

      Future<void> stopLocalization() async {
        await Future.delayed(const Duration(milliseconds: 200));
        localizationStopped = true;
      }

      Future<void> stopVisualIdentification() async {
        await Future.delayed(const Duration(milliseconds: 250));
        visualIdentificationStopped = true;
      }

      // Mock persistence service
      when(mockPersistenceService.clearAllSessionData())
          .thenAnswer((_) async {});

      // Start AR session first
      await cubit.startAllARServices(
        startLiveCaptions: () async {},
        startSoundDetection: () async {},
        startLocalization: () async {},
        startVisualIdentification: () async {},
        stopLiveCaptions: stopLiveCaptions,
        stopSoundDetection: stopSoundDetection,
        stopLocalization: stopLocalization,
        stopVisualIdentification: stopVisualIdentification,
      );

      // Act
      final stopwatch = Stopwatch()..start();
      await cubit.stopARSession();
      stopwatch.stop();

      // Assert
      expect(liveCaptionsStopped, isTrue, reason: 'Live captions should be stopped');
      expect(soundDetectionStopped, isTrue, reason: 'Sound detection should be stopped');
      expect(localizationStopped, isTrue, reason: 'Localization should be stopped');
      expect(visualIdentificationStopped, isTrue, reason: 'Visual identification should be stopped');
      
      // Verify persistence service was called
      verify(mockPersistenceService.clearAllSessionData()).called(1);
      
      // Ensure the method completed in reasonable time (should include the 1s delay)
      expect(stopwatch.elapsedMilliseconds, greaterThan(1000));
      expect(stopwatch.elapsedMilliseconds, lessThan(15000), 
          reason: 'Should complete within timeout limits');
    });

    test('stopARSession should handle slow service cleanup with timeouts', () async {
      // Arrange
      bool liveCaptionsStopped = false;
      bool timedOutService = false;

      // Mock a service that takes too long (will timeout)
      Future<void> stopLiveCaptions() async {
        await Future.delayed(const Duration(seconds: 6)); // Longer than 5s timeout
        liveCaptionsStopped = true;
      }

      // Mock a service that times out and doesn't complete
      Future<void> stopSoundDetection() async {
        await Future.delayed(const Duration(seconds: 6));
        timedOutService = true;
      }

      when(mockPersistenceService.clearAllSessionData())
          .thenAnswer((_) async {});

      // Start AR session first
      await cubit.startAllARServices(
        startLiveCaptions: () async {},
        startSoundDetection: () async {},
        startLocalization: () async {},
        startVisualIdentification: () async {},
        stopLiveCaptions: stopLiveCaptions,
        stopSoundDetection: stopSoundDetection,
        stopLocalization: () async {},
        stopVisualIdentification: () async {},
      );

      // Act
      final stopwatch = Stopwatch()..start();
      await cubit.stopARSession();
      stopwatch.stop();

      // Assert
      // The method should complete due to timeouts, not wait forever
      expect(stopwatch.elapsedMilliseconds, lessThan(15000), 
          reason: 'Should timeout rather than hang indefinitely');
      
      // Services that time out shouldn't have completed normally
      expect(liveCaptionsStopped, isFalse, reason: 'Service should have timed out');
      expect(timedOutService, isFalse, reason: 'Service should have timed out');
      
      // But persistence cleanup should still have been called
      verify(mockPersistenceService.clearAllSessionData()).called(1);
    });

    test('stopARSession should handle service errors gracefully', () async {
      // Arrange
      Future<void> stopLiveCaptions() async {
        throw Exception('Simulated service error');
      }

      when(mockPersistenceService.clearAllSessionData())
          .thenAnswer((_) async {});

      // Start AR session first
      await cubit.startAllARServices(
        startLiveCaptions: () async {},
        startSoundDetection: () async {},
        startLocalization: () async {},
        startVisualIdentification: () async {},
        stopLiveCaptions: stopLiveCaptions,
        stopSoundDetection: () async {},
        stopLocalization: () async {},
        stopVisualIdentification: () async {},
      );

      // Act & Assert
      // Should not throw an exception despite service errors
      await expectLater(cubit.stopARSession(), completes);
      
      // Should still call persistence cleanup
      verify(mockPersistenceService.clearAllSessionData()).called(1);
    });
  });
}