import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/di/service_locator.dart';
import 'core/router/app_router.dart';
import 'core/services/app_logger.dart';
import 'features/ar_session/cubit/ar_session_cubit.dart';
import 'features/home/cubit/home_cubit.dart';
import 'features/live_captions/cubit/live_captions_cubit.dart';
import 'features/localization/cubit/localization_cubit.dart';
import 'features/settings/cubit/settings_cubit.dart';
import 'features/sound_detection/cubit/sound_detection_cubit.dart';
import 'features/visual_identification/cubit/visual_identification_cubit.dart';
import 'shared/theme/app_theme.dart';
import 'core/services/google_auth_service.dart';

final AppLogger _appLogger = AppLogger.instance;

class LiveCaptionsXrApp extends StatelessWidget {
  const LiveCaptionsXrApp({super.key});

  @override
  Widget build(BuildContext context) {
    _appLogger.d('🏗️ Building LiveCaptionsXrApp MaterialApp', category: LogCategory.ui);

    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsCubit>(create: (context) => sl<SettingsCubit>()),
        BlocProvider<HomeCubit>(create: (context) => HomeCubit()),
        BlocProvider<SoundDetectionCubit>(create: (context) => sl<SoundDetectionCubit>()),
        BlocProvider<LocalizationCubit>(create: (context) => LocalizationCubit()),
        BlocProvider<VisualIdentificationCubit>(create: (context) => sl<VisualIdentificationCubit>()),
        BlocProvider<LiveCaptionsCubit>(create: (context) => sl<LiveCaptionsCubit>()),
        BlocProvider<ARSessionCubit>(create: (context) => ARSessionCubit(hybridLocalizationEngine: sl(), persistenceService: sl())),
      ],
      child: MaterialApp.router(
        title: 'Live Captions XR',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        builder: (context, child) => AppBootstrap(child: child),
      ),
    );
  }
}

class AppBootstrap extends StatefulWidget {
  final Widget? child;
  const AppBootstrap({Key? key, this.child}) : super(key: key);

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

      if (mounted) {
        setState(() {
          _onboardingComplete = isComplete;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      _appLogger.e('❌ Error checking onboarding status',
          error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _onboardingComplete = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      _appLogger.d('⏳ Waiting for onboarding status check...');
      print('DEBUG: AppBootstrap is loading (onboarding check)');
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // The router now handles whether to show the onboarding screen or the main app
    print('DEBUG: AppBootstrap finished loading, showing app content');
    return widget.child ?? const Center(child: Text('App loaded!'));
  }
}
