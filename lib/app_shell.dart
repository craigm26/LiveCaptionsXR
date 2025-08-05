import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'core/services/debug_logger_service.dart';
import 'core/services/app_logger.dart';

/// AppShell provides the main navigation structure for the Live Captions XR app.
/// 
/// This widget handles both mobile and web platforms:
/// - On mobile: Uses traditional drawer navigation with scaffold key
/// - On web: Uses Builder widget to ensure proper Scaffold context for drawer
/// 
/// The web-specific implementation fixes the issue where the hamburger menu
/// button doesn't open the drawer on web platforms.

class AppShell extends StatefulWidget {
  final Widget? child;

  const AppShell({super.key, this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AppLogger _logger = AppLogger.instance;

  @override
  Widget build(BuildContext context) {
    // Emulator diagnostic logging
    isAndroidEmulator().then((isEmu) {
      if (isEmu) {
        _logger.w('⚠️ Running on Android emulator: some features may be limited.', category: LogCategory.ui);
      }
    });

    // For web platform, use a different approach
    if (kIsWeb) {
      _logger.i('🌐 AppShell being used on web platform - using web-specific layout', category: LogCategory.ui);
      return _buildWebLayout(context);
    }

    _logger.i('📱 AppShell being used on native platform', category: LogCategory.ui);
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            _logger.d('🏠 AppBar title tapped, navigating to home', category: LogCategory.ui);
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
            _logger.d('🍔 Opening navigation drawer', category: LogCategory.ui);
            try {
              final scaffold = _scaffoldKey.currentState;
              if (scaffold != null) {
                scaffold.openDrawer();
                _logger.d('✅ Drawer opened successfully', category: LogCategory.ui);
              } else {
                _logger.w('⚠️ Scaffold state is null', category: LogCategory.ui);
              }
            } catch (e) {
              _logger.e('❌ Error opening drawer: $e', category: LogCategory.ui);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _logger.d('⚙️ Navigating to settings', category: LogCategory.ui);
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

  Widget _buildWebLayout(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            _logger.d('🏠 AppBar title tapped, navigating to home', category: LogCategory.ui);
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
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              _logger.d('🍔 Opening navigation drawer on web', category: LogCategory.ui);
              try {
                final scaffold = Scaffold.of(context);
                if (scaffold.hasDrawer) {
                  scaffold.openDrawer();
                  _logger.d('✅ Drawer opened successfully on web', category: LogCategory.ui);
                } else {
                  _logger.w('⚠️ Scaffold has no drawer on web', category: LogCategory.ui);
                }
              } catch (e) {
                _logger.e('❌ Error opening drawer on web: $e', category: LogCategory.ui);
                // Fallback: try using the scaffold key
                _scaffoldKey.currentState?.openDrawer();
              }
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _logger.d('⚙️ Navigating to settings', category: LogCategory.ui);
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
          _buildDrawerItem(
            context,
            icon: Icons.storage,
            title: 'Model Status',
            route: '/model-status',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.view_in_ar,
            title: 'Spatial Captions Demo',
            subtitle: 'Test AR caption placement',
            route: '/spatial-captions-demo',
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
    final currentLocation = GoRouterState.of(context).uri.toString();
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
        _logger.d('🎯 Navigating to $route', category: LogCategory.ui);
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
