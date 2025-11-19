import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:live_captions_xr/app_shell.dart';
import 'package:live_captions_xr/features/home/view/home_screen.dart';
import 'package:live_captions_xr/features/settings/view/settings_screen.dart';
import 'package:live_captions_xr/app.dart';
import 'package:live_captions_xr/features/model_status/view/model_status_page.dart';
import 'package:live_captions_xr/features/spatial_captions_demo/view/spatial_captions_demo_page.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_logger.dart';

final AppLogger _routerLogger = AppLogger.instance;

final GoRouter router = GoRouter(
  initialLocation: '/home',
  debugLogDiagnostics: true,
  redirect: (context, state) {
    _routerLogger.d('🔄 Router redirect called for: ${state.uri}', category: LogCategory.system);
    _routerLogger.d('🗺️ Available routes: /home, /settings, /about, /model-status, /spatial-captions-demo', category: LogCategory.system);
    return null;
  },
  errorBuilder: (context, state) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found: ${state.uri}',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  },
  routes: <RouteBase>[
    // Shell routes with navigation
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return AppShell(child: child);
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/home',
          builder: (BuildContext context, GoRouterState state) {
            return const HomeScreen();
          },
        ),
        GoRoute(
          path: '/settings',
          builder: (BuildContext context, GoRouterState state) {
            return const SettingsScreen();
          },
        ),
        GoRoute(
          path: '/about',
          builder: (BuildContext context, GoRouterState state) {
            return const AboutScreen();
          },
        ),
        GoRoute(
          path: '/model-status',
          builder: (BuildContext context, GoRouterState state) {
            return const ModelStatusPage();
          },
        ),
        GoRoute(
          path: '/spatial-captions-demo',
          builder: (BuildContext context, GoRouterState state) {
            _routerLogger.d('🗺️ Building SpatialCaptionsDemoPage route', category: LogCategory.system);
            return const SpatialCaptionsDemoPage();
          },
        ),
      ],
    ),
  ],
);

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isCompact = media.size.width < 640;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 16 : 32,
                vertical: isCompact ? 24 : 40,
              ),
              children: [
                _HeroCard(isCompact: isCompact),
                const SizedBox(height: 24),
                _SectionHeader(
                  title: 'Integrated Features',
                  subtitle:
                      'Four synchronized pipelines power a seamless AR captioning experience.',
                ),
                _FeatureWrap(
                  isCompact: isCompact,
                  data: _featureCards,
                ),
                const SizedBox(height: 32),
                _SectionHeader(
                  title: 'How It Works',
                  subtitle:
                      'Audio, vision, and ARKit/ARCore data stay on-device and fuse into a single spatial caption.',
                ),
                const _HowItWorksCard(),
                const SizedBox(height: 32),
                _SectionHeader(
                  title: 'Privacy & Performance',
                  subtitle:
                      'Every frame runs locally with Whisper GGML, Apple Speech, Gemma 3n, and hybrid localization.',
                ),
                _FeatureWrap(
                  isCompact: isCompact,
                  data: _privacyCards,
                ),
                const SizedBox(height: 32),
                const _CtaCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 20 : 36,
          vertical: isCompact ? 28 : 40,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Text(
                  'Captions XR',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logos/LiveCaptionsXRLogo.png',
                  width: isCompact ? 72 : 84,
                  height: isCompact ? 72 : 84,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LiveCaptionsXR',
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Integrated AR live captions for enhanced accessibility.',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimary.withOpacity(0.85),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Version 1.0.0 · Whisper GGML · Apple Speech · Gemma 3n · ARKit / ARCore',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimary.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[700],
              ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _FeatureWrap extends StatelessWidget {
  const _FeatureWrap({required this.isCompact, required this.data});

  final bool isCompact;
  final List<_FeatureCardData> data;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width;
    final double targetWidth = isCompact ? maxWidth : 360;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: data
          .map(
            (card) => SizedBox(
              width: isCompact ? double.infinity : targetWidth,
              child: _FeatureCard(data: card),
            ),
          )
          .toList(),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.data});

  final _FeatureCardData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: data.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                data.icon,
                color: data.accent,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              data.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              data.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
            ),
            if (data.badge != null) ...[
              const SizedBox(height: 12),
              Chip(
                label: Text(data.badge!),
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            for (int i = 0; i < _howItWorksSteps.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(0.85),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _howItWorksSteps[i],
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.5,
                          ),
                    ),
                  ),
                ],
              ),
              if (i != _howItWorksSteps.length - 1)
                Divider(
                  height: 28,
                  color: Colors.grey[300],
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CtaCard extends StatelessWidget {
  const _CtaCard();

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 640;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 20 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Build with Us',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'LiveCaptionsXR is MIT-licensed and community-driven. '
              'Contribute code, triage issues, or help us test spatial accessibility features.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () async {
                    final uri =
                        Uri.parse('https://github.com/craigm26/livecaptionsxr');
                    await launchUrl(uri);
                  },
                  icon: const Icon(Icons.code),
                  label: const Text('GitHub'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(
                      'https://docs.google.com/document/d/1M-ao2l9tKRq3ayXh86CLLZeYd0-5MMvHd',
                    );
                    await launchUrl(uri);
                  },
                  icon: const Icon(Icons.article_outlined),
                  label: const Text('Product Brief'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCardData {
  const _FeatureCardData({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final String? badge;
}

const _featureCards = [
  _FeatureCardData(
    icon: Icons.hearing,
    title: 'Real-time Sound Detection',
    description:
        'Stereo analysis pinpoints direction while detecting priority alerts and speech.',
    accent: Color(0xFF3B82F6),
  ),
  _FeatureCardData(
    icon: Icons.threed_rotation,
    title: 'Spatial Localization',
    description:
        'Hybrid Kalman fusion of IMU, audio, and vision keeps captions anchored to each person.',
    accent: Color(0xFFF97316),
  ),
  _FeatureCardData(
    icon: Icons.visibility,
    title: 'Visual Identification',
    description:
        'On-device vision tracks faces and optimizes caption placement without sending frames to cloud.',
    accent: Color(0xFF22C55E),
  ),
  _FeatureCardData(
    icon: Icons.subtitles,
    title: 'Live Captions',
    description:
        'Whisper GGML (Android) or Apple Speech (iOS) feed Gemma 3n for context-aware transcripts.',
    accent: Color(0xFFE879F9),
  ),
];

const _privacyCards = [
  _FeatureCardData(
    icon: Icons.privacy_tip,
    title: 'Privacy First',
    description:
        'All inference runs locally using MediaPipe, Whisper GGML, Apple Speech, and Gemma 3n.',
    accent: Color(0xFF10B981),
    badge: 'On-device',
  ),
  _FeatureCardData(
    icon: Icons.flash_on,
    title: 'Performance Tuned',
    description:
        'Pipelines are tuned for AR frame rates so captions keep up with real conversations.',
    accent: Color(0xFF6366F1),
    badge: '60 FPS AR',
  ),
  _FeatureCardData(
    icon: Icons.engineering,
    title: 'Production Ready',
    description:
        'Flutter 3.x, get_it DI, and modular services keep the stack stable across iOS, Android, and Web.',
    accent: Color(0xFFFB7185),
    badge: 'MIT Licensed',
  ),
];

const _howItWorksSteps = [
  'Audio capture detects and localizes speakers in real time.',
  'Vision tracking identifies faces and feeds hybrid localization.',
  'ASR runs Whisper GGML (Android) or Apple Speech (iOS) on-device.',
  'Gemma 3n enhances context, tone, and spatial cues.',
  'ARKit/ARCore renders anchored captions for enhanced accessibility.',
];
