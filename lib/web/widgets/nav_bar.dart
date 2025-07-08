import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/testflight_utils.dart';

class NavBar extends StatelessWidget implements PreferredSizeWidget {
  const NavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).location;
    final isMobile = MediaQuery.of(context).size.width < 700;

    if (isMobile) {
      return Material(
        elevation: 4,
        color: Colors.white,
        shadowColor: Colors.grey.withOpacity(0.3),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Logo
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

              // App name
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                ).createShader(bounds),
                child: const Text(
                  'LiveCaptionsXR',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: 1.1,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),

              // Mobile menu button
              Builder(
                builder: (context) => Container(
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
            ],
          ),
        ),
      );
    }

    // Desktop/tablet navigation
    return Material(
      elevation: 4,
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 0),
        height: 64,
        child: Row(
          children: [
            // Logo with animation
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 200),
              tween: Tween(begin: 1.0, end: 1.0),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor.withOpacity(0.1),
                          Theme.of(context).primaryColor.withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: Image.asset(
                      'assets/logos/logo.png',
                      height: 32,
                      width: 32,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 16),

            // App name with gradient
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              ).createShader(bounds),
              child: const Text(
                'Live Captions XR',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
            ),
            const Spacer(),

            // Navigation links
            Row(
              children: [
                _NavLink(
                  label: 'Home',
                  route: '/',
                  selected: location == '/',
                  icon: Icons.home_rounded,
                ),
                const SizedBox(width: 8),
                _NavLink(
                  label: 'Features',
                  route: '/features',
                  selected: location == '/features',
                  icon: Icons.featured_play_list_rounded,
                ),
                const SizedBox(width: 8),
                _NavLink(
                  label: 'Technology',
                  route: '/technology',
                  selected: location == '/technology',
                  icon: Icons.code_rounded,
                ),
                const SizedBox(width: 8),
                _NavLink(
                  label: 'About',
                  route: '/about',
                  selected: location == '/about',
                  icon: Icons.info_rounded,
                ),
                const SizedBox(width: 8),
                _NavLink(
                  label: 'Support',
                  route: '/support',
                  selected: location == '/support',
                  icon: Icons.support_agent_rounded,
                ),
                const SizedBox(width: 16),
                // TestFlight Button
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await TestFlightUtils.openTestFlight();
                    },
                    icon: const Icon(Icons.apple, color: Colors.white),
                    label: const Text(
                      'TestFlight',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Privacy link
                TextButton(
                  onPressed: () => context.go('/privacy'),
                  child: Text(
                    'Privacy',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}

class _NavLink extends StatefulWidget {
  final String label;
  final String route;
  final bool selected;
  final IconData? icon;

  const _NavLink({
    required this.label,
    required this.route,
    required this.selected,
    this.icon,
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
      duration: const Duration(milliseconds: 200),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.selected
                      ? Theme.of(context).primaryColor
                      : _isHovered
                          ? Theme.of(context).primaryColor.withOpacity(0.1)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: widget.selected
                      ? null
                      : Border.all(
                          color: _isHovered
                              ? Theme.of(context).primaryColor.withOpacity(0.3)
                              : Colors.transparent,
                        ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        size: 18,
                        color: widget.selected
                            ? Colors.white
                            : _isHovered
                                ? Theme.of(context).primaryColor
                                : Colors.grey[700],
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.selected
                            ? Colors.white
                            : _isHovered
                                ? Theme.of(context).primaryColor
                                : Colors.grey[700],
                        fontWeight:
                            widget.selected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class NavDrawer extends StatelessWidget {
  final String location;

  const NavDrawer({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Theme.of(context).primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 32),

            // Header with logo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/logos/logo.png',
                    height: 48,
                    width: 48,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'LiveCaptionsXR',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Navigation items
            _DrawerItem(
              icon: Icons.home_rounded,
              label: 'Home',
              route: '/',
              selected: location == '/',
            ),
            _DrawerItem(
              icon: Icons.featured_play_list_rounded,
              label: 'Features',
              route: '/features',
              selected: location == '/features',
            ),
            _DrawerItem(
              icon: Icons.code_rounded,
              label: 'Technology',
              route: '/technology',
              selected: location == '/technology',
            ),
            _DrawerItem(
              icon: Icons.info_rounded,
              label: 'About',
              route: '/about',
              selected: location == '/about',
            ),
            _DrawerItem(
              icon: Icons.support_agent_rounded,
              label: 'Support',
              route: '/support',
              selected: location == '/support',
            ),
            _DrawerItem(
              icon: Icons.privacy_tip_rounded,
              label: 'Privacy Policy',
              route: '/privacy',
              selected: location == '/privacy',
            ),
            const SizedBox(height: 24),

            // TestFlight Button
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await TestFlightUtils.openTestFlight();
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.apple, color: Colors.white),
                label: const Text(
                  'Download on TestFlight',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool selected;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: selected ? Theme.of(context).primaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: selected ? Colors.white : Theme.of(context).primaryColor,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey[800],
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        onTap: () {
          context.go(route);
          Navigator.of(context).pop();
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}