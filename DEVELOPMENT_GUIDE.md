# LiveCaptionsXR Development Guide

## Table of Contents
1. [Getting Started](#getting-started)
2. [Development Setup](#development-setup)
3. [Testing](#testing)
4. [Debugging](#debugging)
5. [Contributing](#contributing)
6. [Build & Deployment](#build--deployment)
7. [Troubleshooting](#troubleshooting)

---

## Getting Started

### Prerequisites
- **Flutter SDK**: 3.16.0 or higher
- **Dart SDK**: 3.2.0 or higher
- **Android Studio** or **VS Code** with Flutter extensions
- **Xcode** (for iOS development)
- **Android SDK** (for Android development)
- **Git** for version control

### Quick Start
1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-org/LiveCaptionsXR.git
   cd LiveCaptionsXR
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

---

## Development Setup

### Environment Configuration

#### Flutter Setup
1. **Install Flutter SDK**:
   ```bash
   # Download Flutter SDK
   git clone https://github.com/flutter/flutter.git
   export PATH="$PATH:`pwd`/flutter/bin"
   ```

2. **Verify installation**:
   ```bash
   flutter doctor
   ```

3. **Install platform-specific tools**:
   ```bash
   flutter doctor --android-licenses
   ```

#### Platform-Specific Setup

##### Android Setup
1. **Install Android Studio**
2. **Configure Android SDK**:
   - API Level 21+ for ARCore support
   - Build Tools 30.0.0+
3. **Enable ARCore**:
   - Install ARCore APK on test devices
   - Configure ARCore permissions

##### iOS Setup
1. **Install Xcode** (latest version)
2. **Configure iOS Development**:
   - Valid Apple Developer account
   - iOS 11.0+ deployment target
3. **ARKit Configuration**:
   - Enable ARKit capabilities
   - Configure camera permissions

### Project Structure
```
LiveCaptionsXR/
├── lib/
│   ├── core/           # Core services and utilities
│   ├── features/       # Feature-specific modules
│   ├── shared/         # Shared widgets and utilities
│   └── main.dart       # App entry point
├── android/            # Android-specific code
├── ios/               # iOS-specific code
├── test/              # Test files
├── docs/              # Documentation
└── prd/               # Product requirements
```

### Dependencies

#### Core Dependencies
- **flutter_bloc**: State management
- **Platform-specific speech recognition**: Android (whisper_ggml), iOS (Apple Speech Recognition)
- **flutter_gemma**: Gemma 3n multimodal model
- **get_it**: Dependency injection
- **logger**: Logging framework

#### Development Dependencies
- **flutter_test**: Testing framework
- **mockito**: Mocking framework
- **integration_test**: Integration testing

---

## Testing

### Test Structure
```
test/
├── unit/              # Unit tests
├── widget/            # Widget tests
├── integration/       # Integration tests
└── core/              # Core service tests
```

### Running Tests

#### Unit Tests
```bash
# Run all unit tests
flutter test

# Run specific test file
flutter test test/core/services/whisper_service_test.dart

# Run tests with coverage
flutter test --coverage
```

#### Widget Tests
```bash
# Run widget tests
flutter test test/widget_test.dart

# Run specific widget test
flutter test test/features/home/view/home_screen_test.dart
```

#### Integration Tests
```bash
# Run integration tests
flutter test integration_test/

# Run on specific device
flutter test integration_test/ -d emulator-5554
```

### Test Categories

#### AR Session Tests
- **State Machine Tests**: Verify AR session state transitions
- **Service Integration Tests**: Test service startup and shutdown
- **Event Stream Tests**: Verify event emission and handling

#### Speech Processing Tests
- **Whisper Integration Tests**: Test speech-to-text functionality
- **Gemma Enhancement Tests**: Test contextual enhancement
- **Audio Processing Tests**: Test audio capture and processing

#### UI Tests
- **Widget Tests**: Test individual UI components
- **Navigation Tests**: Test app navigation flow
- **Accessibility Tests**: Test accessibility features

### Test Data
- **Audio Samples**: Test audio files for speech recognition
- **Model Files**: Test model files for AI processing
- **Mock Services**: Mock implementations for testing

---

## Debugging

### Debug Tools

#### Flutter Inspector
- **Widget Inspector**: Inspect widget tree and properties
- **Performance Overlay**: Monitor app performance
- **Debug Console**: View logs and errors

#### Debug Logging
```dart
// Enable debug logging
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    printTime: true,
  ),
);

// Log levels
logger.d('Debug message');
logger.i('Info message');
logger.w('Warning message');
logger.e('Error message');
```

#### Debug Overlay
Enable debug overlay in settings to see real-time logs:
```dart
// In settings
debugLoggingOverlayEnabled: true
```

### Common Debug Scenarios

#### AR Session Issues
1. **Session Not Starting**:
   - Check device AR support
   - Verify camera permissions
   - Check ARCore/ARKit installation

2. **Tracking Lost**:
   - Check lighting conditions
   - Verify surface detection
   - Check device movement

3. **Anchor Placement Issues**:
   - Verify anchor creation
   - Check transform data
   - Validate anchor persistence

#### Speech Processing Issues
1. **Audio Not Captured**:
   - Check microphone permissions
   - Verify audio format
   - Check audio stream initialization

2. **Whisper Not Working**:
   - Verify model download
   - Check model file path
   - Validate audio input format

3. **Gemma Enhancement Issues**:
   - Check model availability
   - Verify input text format
   - Check enhancement cache

#### Performance Issues
1. **High Memory Usage**:
   - Check model loading
   - Verify resource cleanup
   - Monitor event subscriptions

2. **Slow Processing**:
   - Check model optimization
   - Verify threading configuration
   - Monitor CPU usage

3. **Battery Drain**:
   - Check background processing
   - Verify sensor usage
   - Monitor network requests

### Debug Commands

#### Flutter Commands
```bash
# Hot reload
r

# Hot restart
R

# Quit
q

# Show device info
flutter devices

# Check Flutter installation
flutter doctor
```

#### Platform-Specific Debugging

##### Android Debugging
```bash
# View Android logs
adb logcat

# Install APK
adb install app-debug.apk

# Check device AR support
adb shell pm list packages | grep arcore
```

##### iOS Debugging
```bash
# View iOS logs
xcrun simctl spawn booted log stream

# Check device capabilities
xcrun simctl list devices

# Install app
xcrun simctl install booted LiveCaptionsXR.app
```

---

## Contributing

### Development Workflow

#### 1. Fork and Clone
```bash
# Fork the repository on GitHub
# Clone your fork
git clone https://github.com/your-username/LiveCaptionsXR.git
cd LiveCaptionsXR

# Add upstream remote
git remote add upstream https://github.com/original-org/LiveCaptionsXR.git
```

#### 2. Create Feature Branch
```bash
# Create and checkout feature branch
git checkout -b feature/your-feature-name

# Or use conventional commits
git checkout -b feat/add-new-model-support
```

#### 3. Make Changes
- Follow the coding standards
- Write tests for new features
- Update documentation
- Test on multiple platforms

#### 4. Commit Changes
```bash
# Use conventional commit format
git commit -m "feat: add support for new Whisper model"

# Commit types: feat, fix, docs, style, refactor, test, chore
```

#### 5. Push and Create PR
```bash
# Push to your fork
git push origin feature/your-feature-name

# Create pull request on GitHub
```

### Coding Standards

#### Dart/Flutter Standards
- **Dart Style Guide**: Follow official Dart style guide
- **Flutter Widgets**: Use Flutter widget patterns
- **State Management**: Use Cubit for state management
- **Error Handling**: Proper error handling and logging

#### Code Organization
```dart
// File structure
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Service imports
import '../../../core/services/whisper_service.dart';

// Model imports
import '../../../core/models/speech_result.dart';

// Widget class
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

#### Testing Standards
- **Unit Tests**: Test business logic
- **Widget Tests**: Test UI components
- **Integration Tests**: Test full workflows
- **Test Coverage**: Maintain high test coverage

### Documentation Standards

#### Code Documentation
```dart
/// Service for handling Whisper GGML speech-to-text processing
/// 
/// This service provides on-device speech recognition using Whisper GGML
/// with real-time event emission for progress tracking.
class WhisperService {
  /// Initialize the Whisper service with configuration
  /// 
  /// [config] - Optional configuration for the service
  /// Returns true if initialization was successful
  Future<bool> initialize({SpeechConfig? config}) async {
    // Implementation
  }
}
```

#### README Updates
- Update README.md for new features
- Add setup instructions for new dependencies
- Update troubleshooting section

---

## Build & Deployment

### Build Configuration

#### Android Build
```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release

# App bundle for Play Store
flutter build appbundle --release
```

#### iOS Build
```bash
# Debug build
flutter build ios --debug

# Release build
flutter build ios --release

# Archive for App Store
flutter build ios --release --no-codesign
```

### Build Scripts

#### Android Build Script
```bash
#!/bin/bash
# scripts/build_android.sh

echo "Building Android app..."

# Clean build
flutter clean

# Get dependencies
flutter pub get

# Build APK
flutter build apk --release

echo "Android build complete!"
```

#### iOS Build Script
```bash
#!/bin/bash
# scripts/build_ios.sh

echo "Building iOS app..."

# Clean build
flutter clean

# Get dependencies
flutter pub get

# Build iOS
flutter build ios --release

echo "iOS build complete!"
```

### Deployment

#### Android Deployment
1. **Generate Keystore**:
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. **Configure Signing**:
   ```yaml
   # android/app/build.gradle
   android {
     signingConfigs {
       release {
         keyAlias keystoreProperties['keyAlias']
         keyPassword keystoreProperties['keyPassword']
         storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
         storePassword keystoreProperties['storePassword']
       }
     }
   }
   ```

3. **Upload to Play Store**:
   - Build app bundle
   - Upload to Google Play Console
   - Configure release notes

#### iOS Deployment
1. **Configure Certificates**:
   - Create App Store certificate
   - Create provisioning profile
   - Configure Xcode signing

2. **Archive App**:
   ```bash
   flutter build ios --release
   # Open Xcode and archive
   ```

3. **Upload to App Store**:
   - Upload through Xcode
   - Configure App Store metadata
   - Submit for review

### CI/CD Pipeline

#### GitHub Actions
```yaml
# .github/workflows/ci.yml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test
      - run: flutter build apk
```

#### Automated Testing
- **Unit Tests**: Run on every commit
- **Integration Tests**: Run on pull requests
- **Build Tests**: Verify builds work
- **Performance Tests**: Monitor performance regressions

---

## Troubleshooting

### Common Issues

#### Build Issues
1. **Dependency Conflicts**:
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Platform-Specific Issues**:
   ```bash
   flutter doctor
   flutter doctor --android-licenses
   ```

3. **Version Conflicts**:
   - Check Flutter version compatibility
   - Update dependencies
   - Check platform SDK versions

#### Runtime Issues
1. **AR Not Working**:
   - Check device AR support
   - Verify ARCore/ARKit installation
   - Check camera permissions

2. **Audio Not Working**:
   - Check microphone permissions
   - Verify audio format support
   - Check device audio capabilities

3. **Models Not Loading**:
   - Check model download status
   - Verify model file paths
   - Check storage permissions

### Performance Issues

#### Memory Leaks
- Check event subscription cleanup
- Verify resource disposal
- Monitor memory usage

#### Slow Performance
- Check model optimization
- Verify threading configuration
- Monitor CPU usage

#### Battery Drain
- Check background processing
- Verify sensor usage
- Monitor network requests

### Platform-Specific Issues

#### Android Issues
1. **ARCore Not Working**:
   - Install ARCore APK
   - Check device compatibility
   - Verify camera permissions

2. **Audio Issues**:
   - Check audio permissions
   - Verify audio format support
   - Check device audio capabilities

#### iOS Issues
1. **ARKit Not Working**:
   - Check device compatibility
   - Verify camera permissions
   - Check ARKit capabilities

2. **Build Issues**:
   - Check Xcode version
   - Verify certificates
   - Check provisioning profiles

### Getting Help

#### Resources
- **Flutter Documentation**: https://flutter.dev/docs
- **Dart Documentation**: https://dart.dev/guides
- **GitHub Issues**: Report bugs and feature requests
- **Discord Community**: Join the development community

#### Reporting Issues
When reporting issues, include:
- **Platform**: iOS/Android version
- **Device**: Device model and OS version
- **Steps**: Steps to reproduce the issue
- **Logs**: Relevant error logs
- **Screenshots**: If applicable

---

*This development guide consolidates all development-related information from the original scattered documentation files into a single, comprehensive reference.* 