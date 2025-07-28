import 'package:flutter/material.dart';

/// Responsive breakpoints for the web application
class ResponsiveBreakpoints {
  static const double mobile = 768;
  static const double tablet = 1024;
  static const double desktop = 1200;
  static const double largeDesktop = 1440;
}

/// Responsive screen size detection utilities
class ResponsiveUtils {
  /// Check if the current screen size is mobile
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < ResponsiveBreakpoints.mobile;
  
  /// Check if the current screen size is tablet
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= ResponsiveBreakpoints.mobile &&
      MediaQuery.of(context).size.width < ResponsiveBreakpoints.tablet;
  
  /// Check if the current screen size is desktop
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= ResponsiveBreakpoints.tablet;
  
  /// Check if the current screen size is large desktop
  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= ResponsiveBreakpoints.largeDesktop;
  
  /// Check if hamburger menu should be shown
  static bool shouldShowHamburgerMenu(BuildContext context) =>
      MediaQuery.of(context).size.width < ResponsiveBreakpoints.tablet;
  
  /// Get the current screen size category
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < ResponsiveBreakpoints.mobile) return ScreenSize.mobile;
    if (width < ResponsiveBreakpoints.tablet) return ScreenSize.tablet;
    if (width < ResponsiveBreakpoints.desktop) return ScreenSize.desktop;
    return ScreenSize.largeDesktop;
  }
  
  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
      case ScreenSize.tablet:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 24);
      case ScreenSize.desktop:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 32);
      case ScreenSize.largeDesktop:
        return const EdgeInsets.symmetric(horizontal: 48, vertical: 32);
    }
  }
  
  /// Get responsive horizontal padding
  static double getHorizontalPadding(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return 16;
      case ScreenSize.tablet:
        return 24;
      case ScreenSize.desktop:
        return 32;
      case ScreenSize.largeDesktop:
        return 48;
    }
  }
  
  /// Get responsive vertical padding
  static double getVerticalPadding(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return 16;
      case ScreenSize.tablet:
        return 24;
      case ScreenSize.desktop:
        return 32;
      case ScreenSize.largeDesktop:
        return 32;
    }
  }
  
  /// Get responsive font size based on screen size
  static double getResponsiveFontSize(BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return mobile ?? 16;
      case ScreenSize.tablet:
        return tablet ?? 18;
      case ScreenSize.desktop:
        return desktop ?? 20;
      case ScreenSize.largeDesktop:
        return largeDesktop ?? 22;
    }
  }
  
  /// Get responsive spacing between elements
  static double getResponsiveSpacing(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return 16;
      case ScreenSize.tablet:
        return 24;
      case ScreenSize.desktop:
        return 32;
      case ScreenSize.largeDesktop:
        return 40;
    }
  }
  
  /// Get responsive container width (percentage of screen width)
  static double getResponsiveWidth(BuildContext context, {
    double mobile = 0.95,
    double tablet = 0.9,
    double desktop = 0.8,
    double largeDesktop = 0.7,
  }) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return mobile;
      case ScreenSize.tablet:
        return tablet;
      case ScreenSize.desktop:
        return desktop;
      case ScreenSize.largeDesktop:
        return largeDesktop;
    }
  }
}

/// Screen size categories
enum ScreenSize {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}

/// Responsive widget that adapts its child based on screen size
class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? largeDesktop;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = ResponsiveUtils.getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.mobile:
        return mobile;
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenSize.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }
}

/// Responsive layout builder
class ResponsiveLayoutBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenSize screenSize) builder;

  const ResponsiveLayoutBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = ResponsiveUtils.getScreenSize(context);
    return builder(context, screenSize);
  }
} 