import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../shared/theme/app_theme.dart';
import 'navigation/web_navigation_cubit.dart';
import '../../core/router/app_router.dart';

class live_captions_xrWebApp extends StatelessWidget {
  const live_captions_xrWebApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WebNavigationCubit(),
      child: MaterialApp.router(
        title: 'Live Captions XR',
        theme: AppTheme.light.copyWith(
          // Web-specific theme modifications for better desktop viewing
          textTheme: AppTheme.light.textTheme.copyWith(
            headlineLarge: AppTheme.light.textTheme.headlineLarge?.copyWith(fontSize: 48),
            headlineMedium: AppTheme.light.textTheme.headlineMedium?.copyWith(fontSize: 36),
          ),
        ),
        darkTheme: AppTheme.dark.copyWith(
          textTheme: AppTheme.dark.textTheme.copyWith(
            headlineLarge: AppTheme.dark.textTheme.headlineLarge?.copyWith(fontSize: 48),
            headlineMedium: AppTheme.dark.textTheme.headlineMedium?.copyWith(fontSize: 36),
          ),
        ),
        debugShowCheckedModeBanner: false,
        routerConfig: router,
      ),
    );
  }
}