import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:live_captions_xr/features/ar_session/cubit/ar_session_cubit.dart';
import 'package:live_captions_xr/features/ar_session/cubit/ar_session_state.dart';
import 'package:live_captions_xr/core/services/hybrid_localization_engine.dart';

import 'ar_session_cubit_test.mocks.dart';

@GenerateMocks([HybridLocalizationEngine])
void main() {
  group('ARSessionCubit', () {
    late ARSessionCubit arSessionCubit;
    late MockHybridLocalizationEngine mockHybridLocalizationEngine;

    setUp(() {
      mockHybridLocalizationEngine = MockHybridLocalizationEngine();
      arSessionCubit = ARSessionCubit(
        hybridLocalizationEngine: mockHybridLocalizationEngine,
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
  });
}