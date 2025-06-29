import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
            color: Colors.black.withOpacity(0.1),
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
                        'live_captions_xr',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                        // TODO: Implement demo mode toggle
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
    final isActive = GoRouter.of(context).location == route;
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
                ? Theme.of(context).primaryColor.withOpacity(0.1)
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