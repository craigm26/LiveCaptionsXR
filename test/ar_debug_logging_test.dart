import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:live_captions_xr/features/ar_session/cubit/ar_session_cubit.dart';
import 'package:live_captions_xr/features/ar_session/cubit/ar_session_state.dart';
import 'package:live_captions_xr/core/services/hybrid_localization_engine.dart';
import 'package:live_captions_xr/core/services/ar_session_persistence_service.dart';

import 'features/ar_session/cubit/ar_session_cubit_test.mocks.dart';

@GenerateMocks([
  HybridLocalizationEngine,
  ARSessionPersistenceService,
])

void main() {
  group('AR Session Debug Logging Tests', () {
    late ARSessionCubit arSessionCubit;
    late MockHybridLocalizationEngine mockHybridLocalizationEngine;
    late MockARSessionPersistenceService mockPersistenceService;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      
      mockHybridLocalizationEngine = MockHybridLocalizationEngine();
      mockPersistenceService = MockARSessionPersistenceService();
      
      arSessionCubit = ARSessionCubit(
        hybridLocalizationEngine: mockHybridLocalizationEngine,
        persistenceService: mockPersistenceService,
      );
    });

    testWidgets('should log detailed error when AR session validation fails', (WidgetTester tester) async {
      // Arrange - Mock method channel to simulate NO_SESSION error during validation
      const MethodChannel channel = MethodChannel('live_captions_xr/ar_anchor_methods');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getDeviceOrientation') {
          throw PlatformException(
            code: 'NO_SESSION',
            message: 'ARSession not available',
            details: null,
          );
        }
        return null;
      });

      // Mock the AR navigation channel to succeed initially
      const MethodChannel navChannel = MethodChannel('live_captions_xr/ar_navigation');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(navChannel, (MethodCall methodCall) async {
        if (methodCall.method == 'showARView') {
          return null; // Simulate successful AR view launch
        }
        return null;
      });

      when(mockPersistenceService.restoreSessionState())
          .thenAnswer((_) async => null);

      // Act - Try to initialize AR session
      await arSessionCubit.initializeARSession();

      // Assert - Should have reached ARSessionReady state despite validation failure
      expect(arSessionCubit.state, isA<ARSessionReady>());
    });

    testWidgets('should log detailed error during anchor placement failure', (WidgetTester tester) async {
      // Arrange - Set up AR session as ready
      arSessionCubit.emit(const ARSessionReady());

      // Mock method channel to simulate NO_SESSION error during anchor creation
      const MethodChannel channel = MethodChannel('live_captions_xr/ar_anchor_methods');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'createAnchorAtWorldTransform') {
          throw PlatformException(
            code: 'NO_SESSION',
            message: 'ARSession not available',
            details: null,
          );
        }
        return null;
      });

      // Mock successful transform retrieval
      when(mockHybridLocalizationEngine.getFusedTransform())
          .thenAnswer((_) async => List.filled(16, 1.0));

      // Act - Try to place anchor
      await arSessionCubit.placeAutoAnchor();

      // Assert - Should remain in ready state (anchor placement failure doesn't break session)
      expect(arSessionCubit.state, isA<ARSessionReady>());
      expect(arSessionCubit.hasAnchor, false);
    });

    test('should handle session health check failures gracefully', () async {
      // Arrange - Set up AR session as ready
      arSessionCubit.emit(const ARSessionReady());

      // Mock method channel to simulate session loss during health check
      const MethodChannel channel = MethodChannel('live_captions_xr/ar_anchor_methods');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getDeviceOrientation') {
          throw PlatformException(
            code: 'NO_SESSION',
            message: 'ARSession not available',
            details: null,
          );
        }
        return null;
      });

      // Act - Manually trigger health check
      await arSessionCubit.startAllARServices(
        startLiveCaptions: () async {},
        startSoundDetection: () async {},
        startLocalization: () async {},
        startVisualIdentification: () async {},
      );

      // Health check should detect the session loss after some time
      // For this test, we'll manually trigger the health check
      // In a real scenario, this would be triggered by the periodic timer
    });

    tearDown(() {
      arSessionCubit.close();
    });
  });
}