import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

final Logger _shellLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 1,
    errorMethodCount: 5,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    printTime: false,
  ),
);

class AppShell extends StatefulWidget {
  final Widget? child;

  const AppShell({super.key, this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            _shellLogger.d('🏠 AppBar title tapped, navigating to home');
            context.go('/home');
          },
          child: const Text(
            'Live Captions XR',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _shellLogger.d('🍔 Opening navigation drawer');
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _shellLogger.d('⚙️ Navigating to settings');
              context.go('/settings');
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      drawer: _buildNavigationDrawer(context),
      body: widget.child ?? _getDefaultBody(context),
    );
  }

  Widget _buildNavigationDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // App logo or icon
                Image.asset(
                  'assets/logos/logo.png',
                  height: 60,
                  width: 60,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Live Captions XR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
              ],
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.home,
            title: 'Home',
            route: '/home',
          ),
          const Divider(),
          _buildDrawerItem(
            context,
            icon: Icons.settings,
            title: 'Settings',
            route: '/settings',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.info_outline,
            title: 'About',
            route: '/about',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required String route,
  }) {
    final currentLocation = GoRouterState.of(context).location;
    final isSelected = currentLocation == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).primaryColor : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : null,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).primaryColor.withAlpha((255 * 0.7).round())
                    : Colors.grey[600],
                fontSize: 12,
              ),
            )
          : null,
      selected: isSelected,
      selectedTileColor: Theme.of(context).primaryColor.withAlpha((255 * 0.1).round()),
      onTap: () {
        _shellLogger.d('🎯 Navigating to $route');
        Navigator.of(context).pop(); // Close drawer
        context.go(route);
      },
    );
  }

  Widget _getDefaultBody(BuildContext context) {
    // Default to home if no child is provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go('/home');
    });

    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
