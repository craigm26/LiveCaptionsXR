import 'package:go_router/go_router.dart';

import 'home_page.dart';
import 'features_page.dart';
import 'demo_page.dart';
import 'technology_page.dart';
import 'app_shell_web.dart';

final GoRouter webRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AppShellWeb(child: HomePage()),
    ),
    GoRoute(
      path: '/features',
      builder: (context, state) => const AppShellWeb(child: FeaturesPage()),
    ),
    GoRoute(
      path: '/technology',
      builder: (context, state) => const AppShellWeb(child: TechnologyPage()),
    ),
  ],
);
