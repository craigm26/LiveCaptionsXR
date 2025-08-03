import 'package:go_router/go_router.dart';

import '../pages/home/home_page.dart';
import '../pages/features/enhanced_features_page.dart';
import '../pages/technology/technology_page.dart';
import '../pages/about/about_page.dart';
import '../pages/support/support_page.dart';
import '../pages/privacy_policy/privacy_policy_page.dart';
import '../pages/technical_docs/technical_docs_page.dart';
import '../pages/demo/spatial_captions_demo_page.dart';

final GoRouter webRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/features',
      builder: (context, state) => const EnhancedFeaturesPage(),
    ),
    GoRoute(
      path: '/technology',
      builder: (context, state) => const TechnologyPage(),
    ),
    GoRoute(
      path: '/about',
      builder: (context, state) => const AboutPage(),
    ),
    GoRoute(
      path: '/support',
      builder: (context, state) => const SupportPage(),
    ),
    GoRoute(
      path: '/privacy',
      builder: (context, state) => const PrivacyPolicyPage(),
    ),
    GoRoute(
      path: '/docs',
      builder: (context, state) => const TechnicalDocsPage(),
    ),
    GoRoute(
      path: '/spatial-captions-demo',
      builder: (context, state) => const SpatialCaptionsDemoPage(),
    ),
  ],
);