import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'webDev/app_web.dart';
import 'features/onboarding/view/onboarding_screen.dart';
import 'features/home/view/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  if (kIsWeb) {
    runApp(const LiveCaptionsXrWebApp());
  } else {
    runApp(LiveCaptionsXrApp(onboardingComplete: onboardingComplete));
  }
}

class LiveCaptionsXrApp extends StatelessWidget {
  final bool onboardingComplete;

  const LiveCaptionsXrApp({Key? key, required this.onboardingComplete}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LiveCaptionsXR',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: onboardingComplete ? '/home' : '/onboarding',
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
