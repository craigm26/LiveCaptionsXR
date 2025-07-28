# Responsive Navigation System

## Overview

The Live Captions XR web application features a fully responsive navigation system that automatically adapts to different screen sizes. The navigation collapses to a hamburger menu on smaller screens and displays full navigation links on larger screens.

## Breakpoints

The responsive system uses the following breakpoints:

- **Mobile**: < 768px
- **Tablet**: 768px - 1023px  
- **Desktop**: 1024px - 1199px
- **Large Desktop**: ≥ 1200px

## Features

### Desktop Navigation
- Full horizontal navigation menu
- All navigation links visible
- Download button prominently displayed
- Smooth hover animations

### Mobile/Tablet Navigation
- Hamburger menu button
- Slide-out drawer navigation
- Touch-friendly navigation items
- Download button in drawer (mobile only)
- Animated menu button

## Implementation

### Responsive Utilities

The `ResponsiveUtils` class provides consistent breakpoint detection across the application:

```dart
// Check screen size
bool isMobile = ResponsiveUtils.isMobile(context);
bool isTablet = ResponsiveUtils.isTablet(context);
bool isDesktop = ResponsiveUtils.isDesktop(context);

// Get responsive values
double padding = ResponsiveUtils.getHorizontalPadding(context);
double fontSize = ResponsiveUtils.getResponsiveFontSize(context);
```

### Navigation Bar

The `NavBar` widget automatically adapts based on screen size:

```dart
Scaffold(
  appBar: const NavBar(),
  body: // Your content
)
```

### Responsive Widgets

Use the `ResponsiveWidget` for different layouts per screen size:

```dart
ResponsiveWidget(
  mobile: MobileLayout(),
  tablet: TabletLayout(),
  desktop: DesktopLayout(),
)
```

## Usage Examples

### Basic Responsive Detection

```dart
@override
Widget build(BuildContext context) {
  final isMobile = ResponsiveUtils.isMobile(context);
  final isTablet = ResponsiveUtils.isTablet(context);
  
  return Container(
    padding: EdgeInsets.all(isMobile ? 16 : 32),
    child: // Your content
  );
}
```

### Responsive Padding

```dart
Container(
  padding: ResponsiveUtils.getResponsivePadding(context),
  child: // Your content
)
```

### Responsive Font Sizes

```dart
Text(
  'Hello World',
  style: TextStyle(
    fontSize: ResponsiveUtils.getResponsiveFontSize(
      context,
      mobile: 16,
      tablet: 18,
      desktop: 20,
      largeDesktop: 22,
    ),
  ),
)
```

### Responsive Layout Builder

```dart
ResponsiveLayoutBuilder(
  builder: (context, screenSize) {
    switch (screenSize) {
      case ScreenSize.mobile:
        return MobileLayout();
      case ScreenSize.tablet:
        return TabletLayout();
      case ScreenSize.desktop:
        return DesktopLayout();
      case ScreenSize.largeDesktop:
        return LargeDesktopLayout();
    }
  },
)
```

## Testing

The responsive navigation system includes comprehensive tests:

```bash
flutter test test/web/responsive_navigation_test.dart
```

Tests cover:
- Mobile hamburger menu display
- Desktop navigation links
- Tablet responsive behavior
- Drawer functionality
- Breakpoint detection

## Best Practices

1. **Use ResponsiveUtils**: Always use the centralized responsive utilities instead of hardcoding breakpoints
2. **Test on Multiple Devices**: Test the navigation on various screen sizes
3. **Progressive Enhancement**: Start with mobile layout and enhance for larger screens
4. **Consistent Spacing**: Use the responsive spacing utilities for consistent layouts
5. **Touch-Friendly**: Ensure mobile navigation items are large enough for touch interaction

## Customization

### Adding New Breakpoints

To add new breakpoints, update the `ResponsiveBreakpoints` class:

```dart
class ResponsiveBreakpoints {
  static const double mobile = 768;
  static const double tablet = 1024;
  static const double desktop = 1200;
  static const double largeDesktop = 1440;
  static const double extraLarge = 1920; // New breakpoint
}
```

### Custom Responsive Values

Add new responsive utility methods to `ResponsiveUtils`:

```dart
static double getCustomValue(BuildContext context) {
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
```

## Performance Considerations

- The responsive system uses efficient MediaQuery lookups
- Animations are optimized for web performance
- Responsive values are calculated once per build
- No unnecessary rebuilds on screen size changes

## Browser Compatibility

The responsive navigation system works across all modern browsers:
- Chrome/Chromium
- Firefox
- Safari
- Edge

## Accessibility

The navigation system includes accessibility features:
- Proper ARIA labels
- Keyboard navigation support
- Screen reader compatibility
- High contrast support
- Touch target sizing compliance 