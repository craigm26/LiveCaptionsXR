import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/core/router/app_router.dart';
import '/shared/theme/app_theme.dart';
import '/features/settings/cubit/settings_cubit.dart';

class live_captions_xrApp extends StatelessWidget {
  const live_captions_xrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsCubit(),
      child: MaterialApp.router(
        title: 'live_captions_xr',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
} 