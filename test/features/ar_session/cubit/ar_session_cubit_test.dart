import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:live_captions_xr/features/ar_session/cubit/ar_session_cubit.dart';
import 'package:live_captions_xr/features/ar_session/cubit/ar_session_state.dart';
import 'package:live_captions_xr/core/services/hybrid_localization_engine.dart';
import 'package:live_captions_xr/core/services/ar_session_persistence_service.dart';

import 'ar_session_cubit_test.mocks.dart';

@GenerateMocks([HybridLocalizationEngine, ARSessionPersistenceService])
void main() {
  group('ARSessionCubit', () {
    late ARSessionCubit arSessionCubit;
    late MockHybridLocalizationEngine mockHybridLocalizationEngine;
    late MockARSessionPersistenceService mockPersistenceService;

    setUp(() {
      // Set up mock shared preferences
      SharedPreferences.setMockInitialValues({});
      
      mockHybridLocalizationEngine = MockHybridLocalizationEngine();
      mockPersistenceService = MockARSessionPersistenceService();
      
      arSessionCubit = ARSessionCubit(
        hybridLocalizationEngine: mockHybridLocalizationEngine,
        persistenceService: mockPersistenceService,
      );
    });

    tearDown(() {
      arSessionCubit.close();
    });

    test('initial state is ARSessionInitial', () {
      expect(arSessionCubit.state, isA<ARSessionInitial>());
    });

    test('isReady returns false initially', () {
      expect(arSessionCubit.isReady, false);
    });

    test('hasAnchor returns false initially', () {
      expect(arSessionCubit.hasAnchor, false);
    });

    test('anchorId returns null initially', () {
      expect(arSessionCubit.anchorId, null);
    });

    group('placeAutoAnchor', () {
      test('does nothing when AR session is not ready', () async {
        // Arrange - AR session is in initial state (not ready)
        expect(arSessionCubit.state, isA<ARSessionInitial>());

        // Act
        await arSessionCubit.placeAutoAnchor();

        // Assert - state should remain unchanged
        expect(arSessionCubit.state, isA<ARSessionInitial>());
        verifyNever(mockHybridLocalizationEngine.getFusedTransform());
      });

      test('places anchor when AR session is ready', () async {
        // Arrange - Set AR session to ready state
        arSessionCubit.emit(const ARSessionReady());
        
        when(mockHybridLocalizationEngine.getFusedTransform())
            .thenAnswer((_) async => List.generate(16, (i) => i.toDouble()));

        // Act
        await arSessionCubit.placeAutoAnchor();

        // Assert
        verify(mockHybridLocalizationEngine.getFusedTransform()).called(1);
        expect(arSessionCubit.state, isA<ARSessionReady>());
      });

      test('does not place anchor if already placed', () async {
        // Arrange - Set AR session to ready state with anchor already placed
        arSessionCubit.emit(const ARSessionReady(anchorPlaced: true, anchorId: 'test-anchor'));

        // Act
        await arSessionCubit.placeAutoAnchor();

        // Assert - should not try to get fused transform since anchor is already placed
        verifyNever(mockHybridLocalizationEngine.getFusedTransform());
        expect(arSessionCubit.state, isA<ARSessionReady>());
        expect(arSessionCubit.hasAnchor, true);
      });
    });

    group('startAllARServices', () {
      test('does nothing when AR session is not ready', () async {
        // Arrange
        bool liveCaptionsCalled = false;
        bool soundDetectionCalled = false;
        bool localizationCalled = false;
        bool visualIdentificationCalled = false;

        // Act
        await arSessionCubit.startAllARServices(
          startLiveCaptions: () async { liveCaptionsCalled = true; },
          startSoundDetection: () async { soundDetectionCalled = true; },
          startLocalization: () async { localizationCalled = true; },
          startVisualIdentification: () async { visualIdentificationCalled = true; },
        );

        // Assert - no services should be started if AR session is not ready
        expect(liveCaptionsCalled, false);
        expect(soundDetectionCalled, false);
        expect(localizationCalled, false);
        expect(visualIdentificationCalled, false);
      });

      test('starts all services when AR session is ready', () async {
        // Arrange - Set AR session to ready state
        arSessionCubit.emit(const ARSessionReady());
        
        bool liveCaptionsCalled = false;
        bool soundDetectionCalled = false;
        bool localizationCalled = false;
        bool visualIdentificationCalled = false;

        when(mockHybridLocalizationEngine.getFusedTransform())
            .thenAnswer((_) async => List.generate(16, (i) => i.toDouble()));

        // Act
        await arSessionCubit.startAllARServices(
          startLiveCaptions: () async { liveCaptionsCalled = true; },
          startSoundDetection: () async { soundDetectionCalled = true; },
          startLocalization: () async { localizationCalled = true; },
          startVisualIdentification: () async { visualIdentificationCalled = true; },
        );

        // Assert - all services should be started
        expect(liveCaptionsCalled, true);
        expect(soundDetectionCalled, true);
        expect(localizationCalled, true);
        expect(visualIdentificationCalled, true);
      });

      test('emits error state when service startup fails', () async {
        // Arrange - Set AR session to ready state
        arSessionCubit.emit(const ARSessionReady());

        // Act - one of the services throws an error
        await arSessionCubit.startAllARServices(
          startLiveCaptions: () async { throw Exception('Service startup failed'); },
          startSoundDetection: () async {},
          startLocalization: () async {},
          startVisualIdentification: () async {},
        );

        // Assert - should emit error state
        expect(arSessionCubit.state, isA<ARSessionError>());
        final errorState = arSessionCubit.state as ARSessionError;
        expect(errorState.message, 'Failed to start AR services');
      });
    });

    test('stopARSession changes state to stopping then initial', () async {
      // Arrange - Start with ready state
      arSessionCubit.emit(const ARSessionReady());

      // Act
      await arSessionCubit.stopARSession();

      // Assert - should end up in initial state
      expect(arSessionCubit.state, isA<ARSessionInitial>());
    });

    group('Persistence Integration', () {
      test('saves state when initializing session', () async {
        // Arrange
        when(mockPersistenceService.restoreSessionState())
            .thenAnswer((_) async => null);

        // Act
        await arSessionCubit.initializeARSession();

        // Assert
        verify(mockPersistenceService.saveSessionState(any)).called(1);
      });

      test('restores previous session when initializing', () async {
        // Arrange
        const restoredState = ARSessionReady(
          anchorPlaced: true,
          anchorId: 'restored_anchor',
        );
        when(mockPersistenceService.restoreSessionState())
            .thenAnswer((_) async => restoredState);
        when(mockPersistenceService.restoreAnchorData())
            .thenAnswer((_) async => {
              'anchorId': 'restored_anchor',
              'transform': List.generate(16, (i) => i.toDouble()),
            });

        // Act
        await arSessionCubit.initializeARSession();

        // Assert
        expect(arSessionCubit.state, isA<ARSessionReady>());
        final state = arSessionCubit.state as ARSessionReady;
        expect(state.anchorId, 'restored_anchor');
        expect(state.anchorPlaced, true);
      });

      test('clears persistence when stopping session', () async {
        // Arrange
        arSessionCubit.emit(const ARSessionReady());

        // Act
        await arSessionCubit.stopARSession();

        // Assert
        verify(mockPersistenceService.clearAllSessionData()).called(1);
      });
    });

    group('Granular State Management', () {
      test('pauseARSession saves current state', () async {
        // Arrange
        arSessionCubit.emit(const ARSessionReady(
          anchorPlaced: true,
          anchorId: 'test_anchor',
        ));
        when(mockHybridLocalizationEngine.getFusedTransform())
            .thenAnswer((_) async => List.generate(16, (i) => i.toDouble()));

        // Act
        await arSessionCubit.pauseARSession();

        // Assert
        expect(arSessionCubit.state, isA<ARSessionPaused>());
        final state = arSessionCubit.state as ARSessionPaused;
        expect(state.previousAnchorPlaced, true);
        expect(state.previousAnchorId, 'test_anchor');
        
        verify(mockPersistenceService.saveSessionState(any)).called(1);
        verify(mockPersistenceService.saveAnchorData(
          anchorId: 'test_anchor',
          transform: any,
          metadata: any,
        )).called(1);
      });

      test('resumeARSession restores from paused state', () async {
        // Arrange
        final pausedState = ARSessionPaused(
          previousAnchorPlaced: true,
          previousAnchorId: 'paused_anchor',
          pausedAt: DateTime.now(),
        );
        arSessionCubit.emit(pausedState);

        // Act
        await arSessionCubit.resumeARSession();

        // Assert
        expect(arSessionCubit.state, isA<ARSessionReady>());
        final state = arSessionCubit.state as ARSessionReady;
        expect(state.anchorPlaced, true);
        expect(state.anchorId, 'paused_anchor');
      });

      test('handleTrackingLost emits tracking lost state', () async {
        // Arrange
        const reason = 'Poor lighting conditions';

        // Act
        await arSessionCubit.handleTrackingLost(reason);

        // Assert
        expect(arSessionCubit.state, isA<ARSessionTrackingLost>());
        final state = arSessionCubit.state as ARSessionTrackingLost;
        expect(state.reason, reason);
      });

      test('calibration goes through proper states', () async {
        // Arrange
        final states = <ARSessionState>[];
        arSessionCubit.stream.listen(states.add);

        // Act
        when(mockPersistenceService.restoreSessionState())
            .thenAnswer((_) async => null);
        await arSessionCubit.initializeARSession();

        // Assert
        expect(states.any((s) => s is ARSessionConfiguring), true);
        expect(states.any((s) => s is ARSessionInitializing), true);
        expect(states.any((s) => s is ARSessionCalibrating), true);
        expect(states.any((s) => s is ARSessionReady), true);
      });
    });

    group('New State Properties', () {
      test('ARSessionCalibrating has progress and type', () {
        const state = ARSessionCalibrating(
          progress: 0.5,
          calibrationType: 'advanced',
        );
        
        expect(state.progress, 0.5);
        expect(state.calibrationType, 'advanced');
      });

      test('ARSessionTrackingLost has reason and timestamp', () {
        final now = DateTime.now();
        final state = ARSessionTrackingLost(
          reason: 'Test reason',
          lostAt: now,
        );
        
        expect(state.reason, 'Test reason');
        expect(state.lostAt, now);
      });

      test('ARSessionPaused preserves previous state', () {
        final now = DateTime.now();
        final state = ARSessionPaused(
          previousAnchorPlaced: true,
          previousAnchorId: 'previous_123',
          pausedAt: now,
        );
        
        expect(state.previousAnchorPlaced, true);
        expect(state.previousAnchorId, 'previous_123');
        expect(state.pausedAt, now);
      });

      test('ARSessionResuming tracks restoration progress', () {
        const state = ARSessionResuming(
          restoringAnchorId: 'restoring_456',
          progress: 0.75,
        );
        
        expect(state.restoringAnchorId, 'restoring_456');
        expect(state.progress, 0.75);
      });
    });
  });
}