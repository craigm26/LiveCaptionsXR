import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/testflight_utils.dart';
import '../config/web_performance_config.dart';
import '../utils/responsive_utils.dart';

class NavBar extends StatefulWidget implements PreferredSizeWidget {
  const NavBar({super.key});

  @override
  State<NavBar> createState() => _NavBarState();

  @override
  Size get preferredSize => const Size.fromHeight(72);
}

class _NavBarState extends State<NavBar> with TickerProviderStateMixin {
  late AnimationController _menuAnimationController;
  late Animation<double> _menuAnimation;

  @override
  void initState() {
    super.initState();
    _menuAnimationController = AnimationController(
      duration: WebPerformanceConfig.fastAnimationDuration,
      vsync: this,
    );
    _menuAnimation = CurvedAnimation(
      parent: _menuAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _menuAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final shouldShowHamburger = ResponsiveUtils.shouldShowHamburgerMenu(context);

    return Material(
      elevation: 2,
      color: Colors.white,
      shadowColor: Colors.grey.withValues(alpha: 0.1),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : isTablet ? 24 : 32,
          vertical: 0,
        ),
        height: 72,
        child: Row(
          children: [
            // Logo and Brand
            _buildLogo(context, isMobile, isTablet),
            SizedBox(width: isMobile ? 16 : isTablet ? 24 : 32),

            // Navigation Links (hidden on mobile/tablet)
            if (!shouldShowHamburger) ...[
              Expanded(
                child: _buildNavigationLinks(context, location, isTablet),
              ),
            ],

            // CTA Button
            _buildCTAButton(context, isMobile, isTablet),

            // Mobile/Tablet Menu Button
            if (shouldShowHamburger) ...[
              SizedBox(width: isMobile ? 16 : 24),
              _buildMobileMenuButton(context, location, isMobile, isTablet),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context, bool isMobile, bool isTablet) {
    final logoSize = isMobile ? 24.0 : isTablet ? 28.0 : 32.0;
    final fontSize = isMobile ? 18.0 : isTablet ? 20.0 : 22.0;

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
            height: logoSize,
            width: logoSize,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Live Captions XR',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
            color: Colors.grey[800],
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationLinks(BuildContext context, String location, bool isTablet) {
    final spacing = isTablet ? 24.0 : 32.0;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _NavLink(
          label: 'Home',
          route: '/',
          selected: location == '/',
        ),
        SizedBox(width: spacing),
        _NavLink(
          label: 'Features',
          route: '/features',
          selected: location == '/features',
        ),
        SizedBox(width: spacing),
        _NavLink(
          label: 'Technology',
          route: '/technology',
          selected: location == '/technology',
        ),
        SizedBox(width: spacing),
        _NavLink(
          label: 'About',
          route: '/about',
          selected: location == '/about',
        ),
        SizedBox(width: spacing),
        _NavLink(
          label: 'Support',
          route: '/support',
          selected: location == '/support',
        ),
      ],
    );
  }

  Widget _buildCTAButton(BuildContext context, bool isMobile, bool isTablet) {
    final horizontalPadding = isMobile ? 16.0 : isTablet ? 18.0 : 20.0;
    final verticalPadding = isMobile ? 10.0 : isTablet ? 11.0 : 12.0;
    final fontSize = isMobile ? 14.0 : isTablet ? 15.0 : 16.0;

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
            fontSize: fontSize,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileMenuButton(BuildContext context, String location, bool isMobile, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
        ),
      ),
      child: IconButton(
        icon: AnimatedBuilder(
          animation: _menuAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _menuAnimation.value * 0.5,
              child: Icon(
                Icons.menu_rounded,
                size: isMobile ? 24 : 26,
                color: Theme.of(context).primaryColor,
              ),
            );
          },
        ),
        onPressed: () {
          _menuAnimationController.forward().then((_) {
            _menuAnimationController.reverse();
          });
          // Use a simpler approach to show the menu
          _showMobileMenu(context, location, isMobile, isTablet);
        },
        tooltip: 'Open navigation menu',
      ),
    );
  }

  void _showMobileMenu(BuildContext context, String location, bool isMobile, bool isTablet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Container(
            width: isMobile ? 280 : 320,
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
                      Expanded(
                        child: Text(
                          'Live Captions XR',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
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
                // Download button in drawer for mobile
                if (isMobile) ...[
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await TestFlightUtils.openTestFlight();
                          } catch (e) {
                            debugPrint('Could not open TestFlight: $e');
                          }
                        },
                        icon: const Icon(Icons.apple, color: Colors.white, size: 20),
                        label: const Text(
                          'Download',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
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
