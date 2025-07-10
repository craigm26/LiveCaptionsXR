import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:live_captions_xr/features/home/view/home_screen.dart';
import 'package:live_captions_xr/features/live_captions/cubit/live_captions_cubit.dart';
import 'package:live_captions_xr/features/sound_detection/cubit/sound_detection_cubit.dart';
import 'package:live_captions_xr/features/localization/cubit/localization_cubit.dart';
import 'package:live_captions_xr/features/visual_identification/cubit/visual_identification_cubit.dart';
import 'package:live_captions_xr/features/settings/cubit/settings_cubit.dart';
import 'package:live_captions_xr/features/home/cubit/home_cubit.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'ar_mode_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<LiveCaptionsCubit>(),
  MockSpec<SoundDetectionCubit>(),
  MockSpec<LocalizationCubit>(),
  MockSpec<VisualIdentificationCubit>(),
  MockSpec<SettingsCubit>(),
  MockSpec<HomeCubit>(),
])
void main() {
  group('AR Mode Integration Test', () {
    late MockLiveCaptionsCubit mockLiveCaptionsCubit;
    late MockSoundDetectionCubit mockSoundDetectionCubit;
    late MockLocalizationCubit mockLocalizationCubit;
    late MockVisualIdentificationCubit mockVisualIdentificationCubit;
    late MockSettingsCubit mockSettingsCubit;
    late MockHomeCubit mockHomeCubit;

    setUp(() {
      mockLiveCaptionsCubit = MockLiveCaptionsCubit();
      mockSoundDetectionCubit = MockSoundDetectionCubit();
      mockLocalizationCubit = MockLocalizationCubit();
      mockVisualIdentificationCubit = MockVisualIdentificationCubit();
      mockSettingsCubit = MockSettingsCubit();
      mockHomeCubit = MockHomeCubit();

      const MethodChannel('live_captions_xr/ar_navigation')
          .setMockMethodCallHandler((MethodCall methodCall) async {
        if (methodCall.method == 'showARView') {
          return;
        }
      });

      // TODO: Replace gemma3n_multimodal references with flutter_gemma when available
      const MethodChannel('gemma3n_multimodal')
          .setMockMethodCallHandler((MethodCall methodCall) async {
        if (methodCall.method == 'loadModel') {
          return true;
        }
        if (methodCall.method == 'startStream') {
          return Stream.value('');
        }
      });
    });

    tearDown(() {
      const MethodChannel('live_captions_xr/ar_navigation')
          .setMockMethodCallHandler(null);
      const MethodChannel('gemma3n_multimodal')
          .setMockMethodCallHandler(null);
    });

    testWidgets('Entering AR Mode logs all actions and simulates service calls',
        (WidgetTester tester) async {
      // Arrange
      when(mockLiveCaptionsCubit.isActive).thenReturn(false);
      when(mockSoundDetectionCubit.isActive).thenReturn(false);
      when(mockLocalizationCubit.isActive).thenReturn(false);
      when(mockVisualIdentificationCubit.isActive).thenReturn(false);
      when(mockSettingsCubit.state)
          .thenReturn(SettingsState(debugLoggingEnabled: true));
      when(mockHomeCubit.getFusedTransform())
          .thenAnswer((_) async => [
                1.0, 0.0, 0.0, 0.0,
                0.0, 1.0, 0.0, 0.0,
                0.0, 0.0, 1.0, 0.0,
                0.0, 0.0, 0.0, 1.0,
              ]);
      when(mockLiveCaptionsCubit.startCaptions()).thenAnswer((_) async => {});
      when(mockSoundDetectionCubit.start()).thenAnswer((_) async => {});
      when(mockLocalizationCubit.start()).thenAnswer((_) async => {});
      when(mockVisualIdentificationCubit.start()).thenAnswer((_) async => {});

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<LiveCaptionsCubit>(
                create: (_) => mockLiveCaptionsCubit),
            BlocProvider<SoundDetectionCubit>(
                create: (_) => mockSoundDetectionCubit),
            BlocProvider<LocalizationCubit>(
                create: (_) => mockLocalizationCubit),
            BlocProvider<VisualIdentificationCubit>(
                create: (_) => mockVisualIdentificationCubit),
            BlocProvider<SettingsCubit>(create: (_) => mockSettingsCubit),
            BlocProvider<HomeCubit>(create: (_) => mockHomeCubit),
          ],
          child: MaterialApp(
            home: Scaffold(body: HomeScreen()),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      // Assert
      verify(mockLiveCaptionsCubit.startCaptions()).called(2);
      verify(mockSoundDetectionCubit.start()).called(1);
      verify(mockLocalizationCubit.start()).called(1);
      verify(mockVisualIdentificationCubit.start()).called(1);
      verify(mockHomeCubit.getFusedTransform()).called(1);
    });
  });
}

