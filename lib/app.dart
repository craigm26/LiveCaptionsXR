import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:live_captions_xr/core/services/contextual_enhancer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

import 'core/router/app_router.dart';
import 'core/services/speech_processor.dart';
import 'core/services/debug_logger_service.dart';
import 'core/di/service_locator.dart';
import 'shared/theme/app_theme.dart';
import 'features/settings/cubit/settings_cubit.dart';
import 'features/home/cubit/home_cubit.dart';
import 'features/sound_detection/cubit/sound_detection_cubit.dart';
import 'features/localization/cubit/localization_cubit.dart';
import 'features/visual_identification/cubit/visual_identification_cubit.dart';
import 'features/live_captions/cubit/live_captions_cubit.dart';
import 'features/ar_session/cubit/ar_session_cubit.dart';
import 'features/onboarding/view/onboarding_screen.dart';
import 'app_shell.dart';

final Logger _appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    printTime: true,
  ),
);

class LiveCaptionsXrApp extends StatelessWidget {
  const LiveCaptionsXrApp({super.key});

  @override
  Widget build(BuildContext context) {
    _appLogger.d('🏗️ Building LiveCaptionsXrApp MaterialApp');

    // Initialize debug logger service
    DebugLoggerService().initialize();

    // Set up dependency injection
    setupServiceLocator();

    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsCubit>(
          create: (context) => SettingsCubit(),
        ),
        BlocProvider<HomeCubit>(
          create: (context) => HomeCubit(
            hybridLocalizationEngine: sl(),
          ),
        ),
        BlocProvider<SoundDetectionCubit>(
          create: (context) => sl<SoundDetectionCubit>(),
        ),
        BlocProvider<LocalizationCubit>(
          create: (context) => LocalizationCubit(),
        ),
        BlocProvider<VisualIdentificationCubit>(
          create: (context) => sl<VisualIdentificationCubit>(),
        ),
        BlocProvider<LiveCaptionsCubit>(
          create: (context) => LiveCaptionsCubit(
            speechProcessor: sl<SpeechProcessor>(),
            hybridLocalizationEngine: sl(),
            contextualEnhancer: sl<ContextualEnhancer>(),
          ),
        ),
        BlocProvider<ARSessionCubit>(
          create: (context) => ARSessionCubit(
            hybridLocalizationEngine: sl(),
            persistenceService: sl(),
          ),
        ),
      ],
      child: MaterialApp.router(
        title: 'Live Captions XR',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  bool _isLoading = true;
  bool _onboardingComplete = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      _appLogger.d('🔍 Checking onboarding completion status...');
      final prefs = await SharedPreferences.getInstance();
      final isComplete = prefs.getBool('onboarding_complete') ?? false;
      _appLogger.d('📊 Onboarding status check result: $isComplete');

      setState(() {
        _onboardingComplete = isComplete;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      _appLogger.e('❌ Error checking onboarding status',
          error: e, stackTrace: stackTrace);
      setState(() {
        _onboardingComplete = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      _appLogger.d('⏳ Waiting for onboarding status check...');
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_onboardingComplete) {
      _appLogger.i('🎯 Navigating to OnboardingScreen');
      return const OnboardingScreen();
    }

    _appLogger.i('🏠 Navigating to AppShell');
    return const AppShell();
  }
}
