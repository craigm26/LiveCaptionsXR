import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features_page.dart';
import 'demo_page.dart';
import 'technology_page.dart';
import 'home_page.dart';

void main() {
  runApp(const MyApp());
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/features',
      builder: (context, state) => const FeaturesPage(),
    ),
    GoRoute(
      path: '/demo',
      builder: (context, state) => const DemoPage(),
    ),
    GoRoute(
      path: '/technology',
      builder: (context, state) => const TechnologyPage(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: 'LiveCaptionsXR',
      theme: ThemeData(primarySwatch: Colors.blue),
    );
  }
}