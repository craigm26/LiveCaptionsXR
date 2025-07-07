import 'package:go_router/go_router.dart';

import 'home_page.dart';
import 'features_page.dart';
import 'technology_page.dart';
import 'about_page.dart';
import 'support_page.dart';
import 'privacy_policy_page.dart';
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
    GoRoute(
      path: '/about',
      builder: (context, state) => const AppShellWeb(child: AboutPage()),
    ),
    GoRoute(
      path: '/support',
      builder: (context, state) => const AppShellWeb(child: SupportPage()),
    ),
    GoRoute(
      path: '/privacy',
      builder: (context, state) => const AppShellWeb(child: PrivacyPolicyPage()),
    ),
  ],
);
