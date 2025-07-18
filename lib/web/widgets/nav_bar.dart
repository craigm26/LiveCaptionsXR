import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/testflight_utils.dart';
import '../config/web_performance_config.dart';

class NavBar extends StatelessWidget implements PreferredSizeWidget {
  const NavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Material(
      elevation: 2,
      color: Colors.white,
      shadowColor: Colors.grey.withValues(alpha: 0.1),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 32,
          vertical: 0,
        ),
        height: 72,
        child: Row(
          children: [
            // Logo and Brand
            _buildLogo(context, isMobile),
            SizedBox(width: isMobile ? 16 : 32),

            // Navigation Links (hidden on mobile)
            if (!isMobile) ...[
              Expanded(
                child: _buildNavigationLinks(context, location),
              ),
            ],

            // CTA Button
            _buildCTAButton(context, isMobile),

            // Mobile Menu Button
            if (isMobile) ...[
              SizedBox(width: 16),
              _buildMobileMenuButton(context, location),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context, bool isMobile) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor.withValues(alpha: 0.1),
                Theme.of(context).primaryColor.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Image.asset(
            'assets/logos/logo.png',
            height: isMobile ? 24 : 32,
            width: isMobile ? 24 : 32,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Live Captions XR',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 18 : 22,
            color: Colors.grey[800],
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationLinks(BuildContext context, String location) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _NavLink(
          label: 'Home',
          route: '/',
          selected: location == '/',
        ),
        const SizedBox(width: 32),
        _NavLink(
          label: 'Features',
          route: '/features',
          selected: location == '/features',
        ),
        const SizedBox(width: 32),
        _NavLink(
          label: 'Technology',
          route: '/technology',
          selected: location == '/technology',
        ),
        const SizedBox(width: 32),
        _NavLink(
          label: 'About',
          route: '/about',
          selected: location == '/about',
        ),
        const SizedBox(width: 32),
        _NavLink(
          label: 'Support',
          route: '/support',
          selected: location == '/support',
        ),
      ],
    );
  }

  Widget _buildCTAButton(BuildContext context, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () async {
          try {
            await TestFlightUtils.openTestFlight();
          } catch (e) {
            debugPrint('Could not open TestFlight: $e');
          }
        },
        icon: const Icon(Icons.apple, color: Colors.white, size: 20),
        label: Text(
          'Download',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 14 : 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 20,
            vertical: isMobile ? 10 : 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileMenuButton(BuildContext context, String location) {
    return Builder(
      builder: (context) => Scaffold(
        backgroundColor: Colors.transparent,
        endDrawer: Drawer(
          child: SafeArea(
            child: Container(
              width: 280,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  // Drawer Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).primaryColor.withOpacity(0.1),
                                Theme.of(context).primaryColor.withOpacity(0.05),
                              ],
                            ),
                          ),
                          child: Image.asset(
                            'assets/logos/logo.png',
                            height: 24,
                            width: 24,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Live Captions XR',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // Navigation Items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      children: [
                        _DrawerItem(
                          icon: Icons.home_rounded,
                          title: 'Home',
                          selected: location == '/',
                          onTap: () {
                            Navigator.of(context).pop();
                            context.go('/');
                          },
                        ),
                        _DrawerItem(
                          icon: Icons.featured_play_list_rounded,
                          title: 'Features',
                          selected: location == '/features',
                          onTap: () {
                            Navigator.of(context).pop();
                            context.go('/features');
                          },
                        ),
                        _DrawerItem(
                          icon: Icons.code_rounded,
                          title: 'Technology',
                          selected: location == '/technology',
                          onTap: () {
                            Navigator.of(context).pop();
                            context.go('/technology');
                          },
                        ),
                        _DrawerItem(
                          icon: Icons.info_rounded,
                          title: 'About',
                          selected: location == '/about',
                          onTap: () {
                            Navigator.of(context).pop();
                            context.go('/about');
                          },
                        ),
                        _DrawerItem(
                          icon: Icons.support_agent_rounded,
                          title: 'Support',
                          selected: location == '/support',
                          onTap: () {
                            Navigator.of(context).pop();
                            context.go('/support');
                          },
                        ),
                        const Divider(),
                        _DrawerItem(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy Policy',
                          selected: location == '/privacy',
                          onTap: () {
                            Navigator.of(context).pop();
                            context.go('/privacy');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
            ),
          ),
          child: IconButton(
            icon: Icon(
              Icons.menu_rounded,
              size: 24,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
            tooltip: 'Open navigation menu',
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(72);
}

class _NavLink extends StatefulWidget {
  final String label;
  final String route;
  final bool selected;

  const _NavLink({
    required this.label,
    required this.route,
    required this.selected,
  });

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: WebPerformanceConfig.fastAnimationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _animationController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _animationController.reverse();
      },
      child: GestureDetector(
        onTap: () => context.go(widget.route),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.selected
                      ? Theme.of(context).primaryColor
                      : _isHovered
                          ? Theme.of(context).primaryColor.withOpacity(0.1)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.selected
                        ? Colors.white
                        : _isHovered
                            ? Theme.of(context).primaryColor
                            : Colors.grey[700],
                    fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? Theme.of(context).primaryColor : Colors.grey[600],
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: selected ? Theme.of(context).primaryColor : Colors.grey[800],
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      selected: selected,
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
