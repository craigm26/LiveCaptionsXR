import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavBar extends StatelessWidget implements PreferredSizeWidget {
  const NavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).location;
    final isMobile = MediaQuery.of(context).size.width < 700;
    if (isMobile) {
      return Material(
        elevation: 2,
        color: Colors.white,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'LiveCaptionsXR',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Theme.of(context).primaryColor,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, size: 28),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                  tooltip: 'Open navigation menu',
                ),
              ),
            ],
          ),
        ),
      );
    }
    // Desktop/tablet
    return Material(
      elevation: 2,
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 0),
        height: 64,
        child: Row(
          children: [
            // Logo or App Name
            const SizedBox(width: 8),
            // Logo is in assets/logos/logo.png
            Image.asset(
              'assets/logos/logo.png',
              height: 40,
              width: 40,
              fit: BoxFit.cover,
            ),
            const SizedBox(width: 8),
            // App Name
            const Spacer(),
            Text(
              'LiveCaptionsXR',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Theme.of(context).primaryColor,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            _NavLink(
              label: 'Home',
              route: '/',
              selected: location == '/',
            ),
            _NavLink(
              label: 'Features',
              route: '/features',
              selected: location == '/features',
            ),
            _NavLink(
              label: 'Demo',
              route: '/demo',
              selected: location == '/demo',
            ),
            _NavLink(
              label: 'Technology',
              route: '/technology',
              selected: location == '/technology',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}

class _NavLink extends StatelessWidget {
  final String label;
  final String route;
  final bool selected;
  const _NavLink(
      {required this.label, required this.route, required this.selected});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (!selected) context.go(route);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: selected
            ? BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Theme.of(context).primaryColor : Colors.black87,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class NavDrawer extends StatelessWidget {
  final String location;
  const NavDrawer({required this.location, super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Text(
                'LiveCaptionsXR',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            _DrawerNavLink(
                label: 'Home', route: '/', selected: location == '/'),
            _DrawerNavLink(
                label: 'Features',
                route: '/features',
                selected: location == '/features'),
            _DrawerNavLink(
                label: 'Demo', route: '/demo', selected: location == '/demo'),
            _DrawerNavLink(
                label: 'Technology',
                route: '/technology',
                selected: location == '/technology'),
          ],
        ),
      ),
    );
  }
}

class _DrawerNavLink extends StatelessWidget {
  final String label;
  final String route;
  final bool selected;
  const _DrawerNavLink(
      {required this.label, required this.route, required this.selected});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          color: selected ? Theme.of(context).primaryColor : Colors.black87,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: selected,
      onTap: () {
        Navigator.of(context).pop();
        if (!selected) context.go(route);
      },
    );
  }
}
