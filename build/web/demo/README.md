# live_captions_xr Web Demo - Flutter Implementation

This directory contains the Flutter web demo implementation that serves as an interactive demonstration of the live_captions_xr XR captioning capabilities.

## Structure

```
web/demo/
├── lib/                          # Flutter web demo source code
│   ├── demo/
│   │   └── web_demo_screen.dart  # Main demo interface
│   ├── navigation/
│   │   └── web_navigation_cubit.dart # Navigation state management
│   ├── widgets/                  # Demo sections and components
│   │   ├── hero_section.dart
│   │   ├── features_section.dart
│   │   ├── technology_section.dart
│   │   ├── demo_section.dart
│   │   ├── about_section.dart
│   │   └── web_navigation_bar.dart
│   └── web_app.dart             # Web app entry point
└── README.md                    # This file
```

## Purpose

This web demo serves as a standalone sub-platform that:

- **Demonstrates** the mobile app's multimodal AI capabilities
- **Showcases** Flutter web technology integration
- **Provides** an interactive experience for testing and evaluation
- **Serves** as a deployment-ready web demonstration

## Integration

The web demo is integrated into the main Flutter project through:

- **Entry Point**: `lib/main.dart` detects web platform and routes to `live_captions_xrWebApp`
- **Theme Integration**: Uses shared theme from `lib/shared/theme/app_theme.dart`
- **Assets**: Shares assets from the main Flutter project

## Deployment

This demo is built and deployed as part of the Flutter web build process:

```bash
# Build the web demo
flutter build web --release

# The output will be in build/web/ and includes this demo
```

For more deployment details, see the main [WEB_DEPLOYMENT.md](../../WEB_DEPLOYMENT.md) guide.