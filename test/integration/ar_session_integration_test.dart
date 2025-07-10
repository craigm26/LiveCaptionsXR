import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:live_captions_xr/features/ar_session/cubit/ar_session_cubit.dart';
import 'package:live_captions_xr/features/ar_session/cubit/ar_session_state.dart';
import 'package:live_captions_xr/core/services/hybrid_localization_engine.dart';
import 'package:live_captions_xr/core/services/ar_session_persistence_service.dart';
import 'package:live_captions_xr/core/services/ar_anchor_manager.dart';

import '../features/ar_session/cubit/ar_session_cubit_test.mocks.dart' as ar_session_mocks;
import '../features/live_captions/live_captions_cubit_test.mocks.dart';


@GenerateMocks([HybridLocalizationEngine, ARSessionPersistenceService])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('AR Session Integration Tests', () {
    late ARSessionCubit arSessionCubit;
    late ar_session_mocks.MockHybridLocalizationEngine mockHybridLocalizationEngine;
    late ar_session_mocks.MockARSessionPersistenceService mockPersistenceService;
    late ARAnchorManager anchorManager;

    setUp(() {
      mockHybridLocalizationEngine = ar_session_mocks.MockHybridLocalizationEngine();
      mockPersistenceService = ar_session_mocks.MockARSessionPersistenceService();
      anchorManager = ARAnchorManager();

      arSessionCubit = ARSessionCubit(
        hybridLocalizationEngine: mockHybridLocalizationEngine,
        persistenceService: mockPersistenceService,
      );

      // Set up default mocks
      when(mockHybridLocalizationEngine.getFusedTransform())
          .thenAnswer((_) async => List.filled(16, 1.0));
      when(mockPersistenceService.restoreSessionState())
          .thenAnswer((_) async => null);
    });

    tearDown(() {
      arSessionCubit.close();
    });

    group('ARSession timing fix validation', () {
      test('should handle NO_SESSION error gracefully during anchor placement', () async {
        // Arrange - Set up method channel to simulate NO_SESSION error
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('live_captions_xr/ar_navigation'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'showARView') {
              return null; // Simulate successful AR view launch
            }
            return null;
          },
        );

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('live_captions_xr/ar_anchor_methods'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'createAnchorAtWorldTransform') {
              throw PlatformException(
                code: 'NO_SESSION',
                message: 'ARSession not available',
                details: null,
              );
            }
            return null;
          },
        );

        // Act - Initialize AR session
        await arSessionCubit.initializeARSession();
        
        // Simulate the fix: session becomes ready after proper initialization
        arSessionCubit.emit(const ARSessionReady());

        // Try to place an anchor - this should handle the NO_SESSION error gracefully
        await arSessionCubit.placeAutoAnchor();

        // Assert - Should remain in ready state despite anchor placement failure
        expect(arSessionCubit.state, isA<ARSessionReady>());
        expect(arSessionCubit.isReady, true);
        expect(arSessionCubit.hasAnchor, false); // Anchor placement failed, so no anchor
      });

      test('should successfully place anchor when session is properly initialized', () async {
        // Arrange - Set up method channel to simulate successful operations
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('live_captions_xr/ar_navigation'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'showARView') {
              return null; // Simulate successful AR view launch
            }
            return null;
          },
        );

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('live_captions_xr/ar_anchor_methods'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'createAnchorAtWorldTransform') {
              return 'test-anchor-id'; // Simulate successful anchor creation
            }
            return null;
          },
        );

        // Mock successful persistence operations
        when(mockPersistenceService.saveSessionState(any))
            .thenAnswer((_) async => {});
        when(mockPersistenceService.saveAnchorData(
          anchorId: anyNamed('anchorId'),
          transform: anyNamed('transform'),
          metadata: anyNamed('metadata'),
        )).thenAnswer((_) async => {});

        // Act - Initialize AR session
        await arSessionCubit.initializeARSession();
        
        // Simulate proper initialization with the fix
        arSessionCubit.emit(const ARSessionReady());

        // Place an anchor - this should succeed
        await arSessionCubit.placeAutoAnchor();

        // Assert - Should have successfully placed anchor
        expect(arSessionCubit.state, isA<ARSessionReady>());
        expect(arSessionCubit.isReady, true);
        expect(arSessionCubit.hasAnchor, true);
        expect(arSessionCubit.anchorId, 'test-anchor-id');
      });

      test('should retry anchor placement on SESSION_NOT_READY error', () async {
        // Arrange - Set up method channel to simulate SESSION_NOT_READY then success
        int callCount = 0;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('live_captions_xr/ar_anchor_methods'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'createAnchorAtWorldTransform') {
              callCount++;
              if (callCount == 1) {
                throw PlatformException(
                  code: 'SESSION_NOT_READY',
                  message: 'ARSession not ready - no camera frame or tracking not normal',
                  details: null,
                );
              } else {
                return 'retry-anchor-id'; // Success on retry
              }
            }
            return null;
          },
        );

        // Mock successful persistence operations
        when(mockPersistenceService.saveSessionState(any))
            .thenAnswer((_) async => {});
        when(mockPersistenceService.saveAnchorData(
          anchorId: anyNamed('anchorId'),
          transform: anyNamed('transform'),
          metadata: anyNamed('metadata'),
        )).thenAnswer((_) async => {});

        // Set initial state
        arSessionCubit.emit(const ARSessionReady());

        // Act - Place an anchor (should retry and succeed)
        await arSessionCubit.placeAutoAnchor();

        // Assert - Should have successfully placed anchor after retry
        expect(arSessionCubit.state, isA<ARSessionReady>());
        expect(arSessionCubit.hasAnchor, true);
        expect(arSessionCubit.anchorId, 'retry-anchor-id');
        expect(callCount, 2); // Should have been called twice (first failed, second succeeded)
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('live_captions_xr/ar_navigation'),
        null,
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('live_captions_xr/ar_anchor_methods'),
        null,
      );
    });
  });
}