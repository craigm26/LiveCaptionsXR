import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:live_captions_xr/features/home/view/home_screen.dart';
import 'package:live_captions_xr/features/ar_session/cubit/ar_session_cubit.dart';
import 'package:live_captions_xr/features/sound_detection/cubit/sound_detection_cubit.dart';
import 'package:live_captions_xr/features/localization/cubit/localization_cubit.dart';
import 'package:live_captions_xr/features/visual_identification/cubit/visual_identification_cubit.dart';
import 'package:live_captions_xr/features/live_captions/cubit/live_captions_cubit.dart';
import 'package:live_captions_xr/features/settings/cubit/settings_cubit.dart';
import 'package:live_captions_xr/features/home/cubit/home_cubit.dart';
import 'package:live_captions_xr/core/services/ar_session_persistence_service.dart';
import 'package:live_captions_xr/core/services/hybrid_localization_engine.dart';

import 'ar_mode_test.mocks.dart';
import 'features/ar_session/cubit/ar_session_cubit_test.mocks.dart';

// Generate mocks for testing  
@GenerateMocks([
  ARSessionPersistenceService,
  HybridLocalizationEngine,
  SoundDetectionCubit,
  LocalizationCubit, 
  VisualIdentificationCubit,
  LiveCaptionsCubit,
  SettingsCubit,
  HomeCubit,
])

void main() {
  group('AR Mode Button Integration Tests', () {
    late MockARSessionPersistenceService mockPersistenceService;
    late MockHybridLocalizationEngine mockHybridLocalizationEngine;
    late MockSoundDetectionCubit mockSoundDetectionCubit;
    late MockLocalizationCubit mockLocalizationCubit;
    late MockVisualIdentificationCubit mockVisualIdentificationCubit;
    late MockLiveCaptionsCubit mockLiveCaptionsCubit;
    late MockSettingsCubit mockSettingsCubit;
    late MockHomeCubit mockHomeCubit;

    setUp(() {
      mockPersistenceService = MockARSessionPersistenceService();
      mockHybridLocalizationEngine = MockHybridLocalizationEngine();
      mockSoundDetectionCubit = MockSoundDetectionCubit();
      mockLocalizationCubit = MockLocalizationCubit();
      mockVisualIdentificationCubit = MockVisualIdentificationCubit();
      mockLiveCaptionsCubit = MockLiveCaptionsCubit();
      mockSettingsCubit = MockSettingsCubit();
      mockHomeCubit = MockHomeCubit();

      // Setup method channels for testing
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('live_captions_xr/ar_navigation'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'showARView') {
            // Simulate successful AR view presentation
            return null;
          }
          throw MissingPluginException();
        },
      );

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
    });

    tearDown(() {
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

    testWidgets('Enter AR Mode button shows loading and handles success flow', (tester) async {
      // Setup mock behaviors
      when(mockPersistenceService.restoreSessionState()).thenAnswer((_) async => null);
      when(mockPersistenceService.saveSessionState(any)).thenAnswer((_) async {});
      when(mockPersistenceService.saveAnchorData(
        anchorId: anyNamed('anchorId'),
        transform: anyNamed('transform'),
        metadata: anyNamed('metadata'),
      )).thenAnswer((_) async {});
      when(mockHybridLocalizationEngine.getFusedTransform())
          .thenAnswer((_) async => List.filled(16, 1.0));

      // Setup cubit initial states
      when(mockSettingsCubit.state).thenReturn(SettingsState());
      when(mockSoundDetectionCubit.isActive).thenReturn(false);
      when(mockLocalizationCubit.isActive).thenReturn(false);
      when(mockVisualIdentificationCubit.isActive).thenReturn(false);
      when(mockLiveCaptionsCubit.isActive).thenReturn(false);
      
      // Setup cubit streams
      when(mockSettingsCubit.stream).thenAnswer((_) => Stream.value(SettingsState()));
      when(mockSoundDetectionCubit.stream).thenAnswer((_) => Stream.empty());
      when(mockLocalizationCubit.stream).thenAnswer((_) => Stream.empty());
      when(mockVisualIdentificationCubit.stream).thenAnswer((_) => Stream.empty());
      when(mockLiveCaptionsCubit.stream).thenAnswer((_) => Stream.empty());
      when(mockHomeCubit.stream).thenAnswer((_) => Stream.empty());
      
      // Setup service start methods
      when(mockSoundDetectionCubit.start()).thenAnswer((_) async {});
      when(mockLocalizationCubit.start()).thenAnswer((_) async {});
      when(mockVisualIdentificationCubit.start()).thenAnswer((_) async {});
      when(mockLiveCaptionsCubit.startCaptions()).thenAnswer((_) async {});

      // Create AR session cubit
      final arSessionCubit = ARSessionCubit(
        persistenceService: mockPersistenceService,
        hybridLocalizationEngine: mockHybridLocalizationEngine,
      );

      // Build the widget tree
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<ARSessionCubit>.value(value: arSessionCubit),
              BlocProvider<SoundDetectionCubit>.value(value: mockSoundDetectionCubit),
              BlocProvider<LocalizationCubit>.value(value: mockLocalizationCubit),
              BlocProvider<VisualIdentificationCubit>.value(value: mockVisualIdentificationCubit),
              BlocProvider<LiveCaptionsCubit>.value(value: mockLiveCaptionsCubit),
              BlocProvider<SettingsCubit>.value(value: mockSettingsCubit),
              BlocProvider<HomeCubit>.value(value: mockHomeCubit),
            ],
            child: HomeScreen(),
          ),
        ),
      );

      // Wait for initial build
      await tester.pumpAndSettle();

      // Find the Enter AR Mode button
      final arModeButton = find.byTooltip('Enter AR Mode');
      expect(arModeButton, findsOneWidget);

      // Tap the Enter AR Mode button
      await tester.tap(arModeButton);
      await tester.pump();

      // Verify loading snackbar appears
      expect(find.text('🥽 Entering AR Mode...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for AR session initialization and service startup
      await tester.pump(Duration(milliseconds: 1500)); // Wait for AR initialization delay
      await tester.pump(Duration(milliseconds: 1000)); // Wait for service initialization delay
      await tester.pumpAndSettle();

      // Verify services were started
      verify(mockSoundDetectionCubit.start()).called(1);
      verify(mockLocalizationCubit.start()).called(1);
      verify(mockVisualIdentificationCubit.start()).called(1);
      verify(mockLiveCaptionsCubit.startCaptions()).called(1);

      // Verify AR session is ready with anchor
      expect(arSessionCubit.isReady, isTrue);
      expect(arSessionCubit.hasAnchor, isTrue);

      // Clean up
      arSessionCubit.close();
    });

    testWidgets('Enter AR Mode button handles AR initialization failure', (tester) async {
      // Setup AR navigation to fail
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
          throw MissingPluginException();
        },
      );

      // Setup mock behaviors
      when(mockPersistenceService.restoreSessionState()).thenAnswer((_) async => null);
      when(mockSettingsCubit.state).thenReturn(SettingsState());
      when(mockSettingsCubit.stream).thenAnswer((_) => Stream.value(SettingsState()));
      when(mockSoundDetectionCubit.stream).thenAnswer((_) => Stream.empty());
      when(mockLocalizationCubit.stream).thenAnswer((_) => Stream.empty());
      when(mockVisualIdentificationCubit.stream).thenAnswer((_) => Stream.empty());
      when(mockLiveCaptionsCubit.stream).thenAnswer((_) => Stream.empty());
      when(mockHomeCubit.stream).thenAnswer((_) => Stream.empty());

      // Create AR session cubit
      final arSessionCubit = ARSessionCubit(
        persistenceService: mockPersistenceService,
        hybridLocalizationEngine: mockHybridLocalizationEngine,
      );

      // Build the widget tree
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<ARSessionCubit>.value(value: arSessionCubit),
              BlocProvider<SoundDetectionCubit>.value(value: mockSoundDetectionCubit),
              BlocProvider<LocalizationCubit>.value(value: mockLocalizationCubit),
              BlocProvider<VisualIdentificationCubit>.value(value: mockVisualIdentificationCubit),
              BlocProvider<LiveCaptionsCubit>.value(value: mockLiveCaptionsCubit),
              BlocProvider<SettingsCubit>.value(value: mockSettingsCubit),
              BlocProvider<HomeCubit>.value(value: mockHomeCubit),
            ],
            child: HomeScreen(),
          ),
        ),
      );

      // Wait for initial build
      await tester.pumpAndSettle();

      // Find the Enter AR Mode button
      final arModeButton = find.byTooltip('Enter AR Mode');
      expect(arModeButton, findsOneWidget);

      // Tap the Enter AR Mode button
      await tester.tap(arModeButton);
      await tester.pump();

      // Verify loading snackbar appears
      expect(find.text('🥽 Entering AR Mode...'), findsOneWidget);

      // Wait for AR session initialization to fail
      await tester.pumpAndSettle();

      // Verify error message appears
      expect(find.textContaining('❌ Failed to enter AR mode'), findsOneWidget);
      expect(find.textContaining('ARKit not supported'), findsOneWidget);

      // Verify AR session is in error state
      expect(arSessionCubit.isReady, isFalse);

      // Clean up
      arSessionCubit.close();
    });
  });
}