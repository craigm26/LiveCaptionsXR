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
        title: const Text(
          'LiveCaptionsXR',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.spatial_audio_off,
                  size: 48,
                  color: Colors.white,
                ),
                SizedBox(height: 8),
                Text(
                  'LiveCaptionsXR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Integrated AR Live Captions',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.home,
            title: 'Live Captions XR',
            subtitle: 'Integrated AR experience',
            route: '/home',
          ),
          const Divider(),
          _buildInfoSection(context),
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
                    ? Theme.of(context).primaryColor.withOpacity(0.7) 
                    : Colors.grey[600],
                fontSize: 12,
              ),
            )
          : null,
      selected: isSelected,
      selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
      onTap: () {
        _shellLogger.d('🎯 Navigating to $route');
        Navigator.of(context).pop(); // Close drawer
        context.go(route);
      },
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Integrated Features',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.hearing, size: 16, color: Colors.blue),
              SizedBox(width: 8),
              Text('Live Sound Detection', style: TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.orange),
              SizedBox(width: 8),
              Text('Spatial Localization', style: TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Icon(Icons.visibility, size: 16, color: Colors.green),
              SizedBox(width: 8),
              Text('Visual Identification', style: TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Icon(Icons.closed_caption, size: 16, color: Colors.purple),
              SizedBox(width: 8),
              Text('Real-time Captions', style: TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'All features work together on the main screen',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
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
