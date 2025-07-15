import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter/services.dart';
import 'package:live_captions_xr/features/ar_session/cubit/ar_session_cubit.dart';
import 'package:live_captions_xr/features/ar_session/cubit/ar_session_state.dart';
import 'package:live_captions_xr/core/services/hybrid_localization_engine.dart';
import 'package:live_captions_xr/core/services/ar_session_persistence_service.dart';

@GenerateMocks([HybridLocalizationEngine, ARSessionPersistenceService])
import 'ar_services_lifecycle_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AR Services Lifecycle', () {
    late ARSessionCubit arSessionCubit;
    late MockHybridLocalizationEngine mockHybridLocalizationEngine;
    late MockARSessionPersistenceService mockPersistenceService;
    
    // Mock service start/stop functions
    bool liveCaptionsStarted = false;
    bool soundDetectionStarted = false;
    bool localizationStarted = false;
    bool visualIdentificationStarted = false;

    Future<void> startLiveCaptions() async {
      liveCaptionsStarted = true;
    }

    Future<void> stopLiveCaptions() async {
      liveCaptionsStarted = false;
    }

    Future<void> startSoundDetection() async {
      soundDetectionStarted = true;
    }

    Future<void> stopSoundDetection() async {
      soundDetectionStarted = false;
    }

    Future<void> startLocalization() async {
      localizationStarted = true;
    }

    Future<void> stopLocalization() async {
      localizationStarted = false;
    }

    Future<void> startVisualIdentification() async {
      visualIdentificationStarted = true;
    }

    Future<void> stopVisualIdentification() async {
      visualIdentificationStarted = false;
    }

    setUp(() {
      mockHybridLocalizationEngine = MockHybridLocalizationEngine();
      mockPersistenceService = MockARSessionPersistenceService();
      
      // Reset service states
      liveCaptionsStarted = false;
      soundDetectionStarted = false;
      localizationStarted = false;
      visualIdentificationStarted = false;

      // Set up mock returns
      when(mockPersistenceService.restoreSessionState()).thenAnswer((_) async => null);
      when(mockPersistenceService.saveSessionState(any)).thenAnswer((_) async {});
      when(mockPersistenceService.clearAllSessionData()).thenAnswer((_) async {});
      when(mockHybridLocalizationEngine.getFusedTransform()).thenAnswer(
        (_) async => List.generate(16, (i) => i == 0 || i == 5 || i == 10 || i == 15 ? 1.0 : 0.0),
      );

      arSessionCubit = ARSessionCubit(
        hybridLocalizationEngine: mockHybridLocalizationEngine,
        persistenceService: mockPersistenceService,
      );

      // Set up method channel mock for AR navigation
      const MethodChannel('live_captions_xr/ar_navigation')
          .setMockMethodCallHandler((MethodCall methodCall) async {
        if (methodCall.method == 'showARView') {
          return null;
        }
        if (methodCall.method == 'exitARMode') {
          return null;
        }
        return null;
      });
    });

    tearDown(() {
      arSessionCubit.close();
    });

    test('Services should start when AR mode is entered and stop when closed', () async {
      // Start AR session
      arSessionCubit.emit(const ARSessionReady());

      // Start all services
      await arSessionCubit.startAllARServices(
        startLiveCaptions: startLiveCaptions,
        startSoundDetection: startSoundDetection,
        startLocalization: startLocalization,
        startVisualIdentification: startVisualIdentification,
        stopLiveCaptions: stopLiveCaptions,
        stopSoundDetection: stopSoundDetection,
        stopLocalization: stopLocalization,
        stopVisualIdentification: stopVisualIdentification,
      );

      // Verify all services are started
      expect(liveCaptionsStarted, true);
      expect(soundDetectionStarted, true);
      expect(localizationStarted, true);
      expect(visualIdentificationStarted, true);
      expect(arSessionCubit.state, isA<ARSessionReady>());
      expect((arSessionCubit.state as ARSessionReady).servicesStarted, true);

      // Stop AR session (simulating close button press)
      await arSessionCubit.stopARSession();

      // Verify all services are stopped
      expect(liveCaptionsStarted, false);
      expect(soundDetectionStarted, false);
      expect(localizationStarted, false);
      expect(visualIdentificationStarted, false);
      expect(arSessionCubit.state, isA<ARSessionInitial>());
    });

    test('Services should not start multiple times if already started', () async {
      int startCallCount = 0;

      Future<void> countingStartLiveCaptions() async {
        startCallCount++;
        await startLiveCaptions();
      }

      // Start AR session
      arSessionCubit.emit(const ARSessionReady());

      // Start services first time
      await arSessionCubit.startAllARServices(
        startLiveCaptions: countingStartLiveCaptions,
        startSoundDetection: startSoundDetection,
        startLocalization: startLocalization,
        startVisualIdentification: startVisualIdentification,
        stopLiveCaptions: stopLiveCaptions,
        stopSoundDetection: stopSoundDetection,
        stopLocalization: stopLocalization,
        stopVisualIdentification: stopVisualIdentification,
      );

      expect(startCallCount, 1);
      expect((arSessionCubit.state as ARSessionReady).servicesStarted, true);

      // Try to start services again - should be skipped
      await arSessionCubit.startAllARServices(
        startLiveCaptions: countingStartLiveCaptions,
        startSoundDetection: startSoundDetection,
        startLocalization: startLocalization,
        startVisualIdentification: startVisualIdentification,
        stopLiveCaptions: stopLiveCaptions,
        stopSoundDetection: stopSoundDetection,
        stopLocalization: stopLocalization,
        stopVisualIdentification: stopVisualIdentification,
      );

      // Start count should still be 1
      expect(startCallCount, 1);
    });

    test('Closing AR via method channel should stop all services', () async {
      // Start AR session and services
      arSessionCubit.emit(const ARSessionReady());
      
      await arSessionCubit.startAllARServices(
        startLiveCaptions: startLiveCaptions,
        startSoundDetection: startSoundDetection,
        startLocalization: startLocalization,
        startVisualIdentification: startVisualIdentification,
        stopLiveCaptions: stopLiveCaptions,
        stopSoundDetection: stopSoundDetection,
        stopLocalization: stopLocalization,
        stopVisualIdentification: stopVisualIdentification,
      );

      // Verify services are started
      expect(liveCaptionsStarted, true);
      expect(soundDetectionStarted, true);
      expect(localizationStarted, true);
      expect(visualIdentificationStarted, true);

      // Simulate AR view closing via method channel
      await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'live_captions_xr/ar_navigation',
        const StandardMethodCodec().encodeMethodCall(const MethodCall('arViewWillClose')),
        (ByteData? data) {},
      );

      // Give the handler time to process
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify all services are stopped
      expect(liveCaptionsStarted, false);
      expect(soundDetectionStarted, false);
      expect(localizationStarted, false);
      expect(visualIdentificationStarted, false);
      expect(arSessionCubit.state, isA<ARSessionInitial>());
    });
  });
} 