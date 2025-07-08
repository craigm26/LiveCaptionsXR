import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:live_captions_xr/features/ar_session/cubit/ar_session_cubit.dart';
import 'package:live_captions_xr/core/services/ar_session_persistence_service.dart';
import 'package:live_captions_xr/core/services/hybrid_localization_engine.dart';

// Generate mocks for testing
@GenerateMocks([
  ARSessionPersistenceService,
  HybridLocalizationEngine,
])
import 'ar_mode_navigation_test.mocks.dart';

void main() {
  group('AR Mode Navigation Tests', () {
    late MockARSessionPersistenceService mockPersistenceService;
    late MockHybridLocalizationEngine mockHybridLocalizationEngine;
    late ARSessionCubit arSessionCubit;

    setUp(() {
      mockPersistenceService = MockARSessionPersistenceService();
      mockHybridLocalizationEngine = MockHybridLocalizationEngine();
      
      // Setup method channel for testing
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('live_captions_xr/ar_navigation'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'showARView':
              // Simulate successful AR view presentation
              return null;
            default:
              throw MissingPluginException();
          }
        },
      );

      // Setup anchor methods channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('live_captions_xr/ar_anchor_methods'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'getDeviceOrientation':
              // Simulate successful AR session validation
              return [1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0];
            default:
              throw MissingPluginException();
          }
        },
      );

      arSessionCubit = ARSessionCubit(
        persistenceService: mockPersistenceService,
        hybridLocalizationEngine: mockHybridLocalizationEngine,
      );
    });

    tearDown(() {
      arSessionCubit.close();
      // Clean up method channel handlers
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

    testWidgets('AR session initialization should complete successfully', (tester) async {
      // Setup mocks
      when(mockPersistenceService.restoreSessionState())
          .thenAnswer((_) async => null);
      when(mockPersistenceService.saveSessionState(any))
          .thenAnswer((_) async {});

      // Initialize AR session
      await arSessionCubit.initializeARSession();

      // Verify the session is ready
      expect(arSessionCubit.isReady, isTrue);
      expect(arSessionCubit.state.runtimeType.toString(), contains('ARSessionReady'));
    });

    testWidgets('AR session should handle showARView errors gracefully', (tester) async {
      // Setup method channel to return an error
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('live_captions_xr/ar_navigation'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'showARView') {
            throw PlatformException(
              code: 'AR_NOT_SUPPORTED',
              message: 'ARKit not supported on this device',
            );
          }
          return null;
        },
      );

      // Setup mocks
      when(mockPersistenceService.restoreSessionState())
          .thenAnswer((_) async => null);

      // Try to initialize AR session - should handle error gracefully
      await arSessionCubit.initializeARSession();

      // Verify error state
      expect(arSessionCubit.isReady, isFalse);
      expect(arSessionCubit.state.runtimeType.toString(), contains('ARSessionError'));
    });

    testWidgets('startAllARServices should handle timing correctly', (tester) async {
      // Setup mocks
      when(mockPersistenceService.restoreSessionState())
          .thenAnswer((_) async => null);
      when(mockPersistenceService.saveSessionState(any))
          .thenAnswer((_) async {});
      when(mockPersistenceService.saveAnchorData(
        anchorId: anyNamed('anchorId'),
        transform: anyNamed('transform'),
        metadata: anyNamed('metadata'),
      )).thenAnswer((_) async {});
      when(mockHybridLocalizationEngine.getFusedTransform())
          .thenAnswer((_) async => List.filled(16, 1.0));

      // Setup anchor creation to succeed
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('live_captions_xr/ar_anchor_methods'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'getDeviceOrientation':
              return [1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0];
            case 'createAnchorAtWorldTransform':
              return 'test-anchor-id';
            default:
              throw MissingPluginException();
          }
        },
      );

      // Initialize AR session first
      await arSessionCubit.initializeARSession();
      expect(arSessionCubit.isReady, isTrue);

      // Track timing of service startup
      final stopwatch = Stopwatch()..start();

      // Start all AR services
      await arSessionCubit.startAllARServices(
        startLiveCaptions: () async => Future.delayed(Duration(milliseconds: 10)),
        startSoundDetection: () async => Future.delayed(Duration(milliseconds: 10)),
        startLocalization: () async => Future.delayed(Duration(milliseconds: 10)),
        startVisualIdentification: () async => Future.delayed(Duration(milliseconds: 10)),
      );

      stopwatch.stop();

      // Verify timing - should include the 1000ms delay for anchor placement
      expect(stopwatch.elapsedMilliseconds, greaterThan(1000));
      
      // Verify anchor was placed
      expect(arSessionCubit.hasAnchor, isTrue);
      expect(arSessionCubit.anchorId, equals('test-anchor-id'));
    });
  });
}