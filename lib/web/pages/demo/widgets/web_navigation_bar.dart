import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:live_captions_xr/web/pages/demo/cubit/web_navigation_cubit.dart';

class WebNavigationBar extends StatelessWidget {
  const WebNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.1).round()),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo and Title
            InkWell(
              onTap: () => context.go('/'),
              child: Row(
                children: [
                  Icon(
                    Icons.hearing,
                    size: 32,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Captions XR',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                      ),
                      Text(
                        'Real-Time Closed Captioning for Accessibility',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Navigation Items
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _NavItem(
                      title: 'Home',
                      route: '/home',
                    ),
                    _NavItem(
                      title: 'Sound',
                      route: '/sound',
                    ),
                    _NavItem(
                      title: 'Localization',
                      route: '/localization',
                    ),
                    _NavItem(
                      title: 'Visual',
                      route: '/visual',
                    ),
                    _NavItem(
                      title: 'Settings',
                      route: '/settings',
                    ),
                    const SizedBox(width: 24),
                    // Demo Toggle Button
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<WebNavigationCubit>().startDemo();
                      },
                      icon: const Icon(
                        Icons.play_arrow,
                        size: 18,
                      ),
                      label: const Text('Start Demo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String title;
  final String route;

  const _NavItem({
    required this.title,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final isActive =
        GoRouter.of(context).routeInformationProvider.value.uri.toString() ==
            route;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isActive
                ? Theme.of(context).primaryColor.withAlpha((255 * 0.1).round())
                : null,
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).textTheme.bodyLarge?.color,
                ),
          ),
        ),
      ),
    );
  }
}
