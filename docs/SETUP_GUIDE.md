# LiveCaptionsXR Development Setup Guide

This guide will help you set up the development environment for LiveCaptionsXR, an AR-powered accessibility application that provides real-time, spatially-aware closed captioning.

## Prerequisites

### Required Software

1. **Flutter SDK** (3.0 or higher)
   - Download from [flutter.dev](https://flutter.dev/docs/get-started/install)
   - Ensure Flutter is in your PATH
   - Run `flutter doctor` to verify installation

2. **Android Studio** (for Android development)
   - Download from [developer.android.com](https://developer.android.com/studio)
   - Install Android SDK and build tools
   - Configure Android emulator or connect physical device

3. **Xcode** (for iOS development - macOS only)
   - Install from Mac App Store
   - Install iOS Simulator and development tools
   - Accept Xcode license agreement

4. **Git**
   - Download from [git-scm.com](https://git-scm.com/)
   - Configure your Git identity

### Hardware Requirements

- **For iOS Development**: Mac computer with Xcode
- **For Android Development**: Any computer with Android Studio
- **For Testing**: Physical device with AR capabilities (ARKit/ARCore)

## Repository Setup

### 1. Fork and Clone

```bash
# Fork the repository on GitHub first, then:
git clone https://github.com/YOUR_USERNAME/livecaptionsxr.git
cd livecaptionsxr

# Add upstream remote
git remote add upstream https://github.com/craigm26/livecaptionsxr.git
```

### 2. Install Dependencies

```bash
# Install Flutter dependencies
flutter pub get

# Install iOS dependencies (macOS only)
cd ios
pod install
cd ..
```

### 3. Configure Environment

#### Android Configuration

1. **Enable Developer Options** on your Android device
2. **Enable USB Debugging**
3. **Connect device** or start Android emulator
4. **Verify connection**: `flutter devices`

#### iOS Configuration (macOS only)

1. **Open Xcode** and sign in with your Apple ID
2. **Open the iOS project**: `open ios/Runner.xcworkspace`
3. **Select your team** in the signing configuration
4. **Update Bundle Identifier** if needed

## Project Structure

```
LiveCaptionsXR/
├── lib/                    # Main Flutter application code
│   ├── core/              # Core services and utilities
│   ├── features/          # Feature-specific code
│   └── shared/            # Shared components
├── android/               # Android-specific code
├── ios/                   # iOS-specific code
├── docs/                  # Documentation
├── prd/                   # Product Requirements Documents
└── test/                  # Test files
```

## Key Dependencies

### Core Dependencies

- **whisper_ggml**: On-device speech recognition
- **flutter_gemma**: Gemma 3n integration for text enhancement
- **flutter_sound**: Audio capture and processing
- **camera**: Camera access for AR features
- **permission_handler**: Device permissions management

### Development Dependencies

- **flutter_bloc**: State management
- **get_it**: Dependency injection
- **go_router**: Navigation
- **url_launcher**: External URL handling

## Running the Application

### Development Mode

```bash
# Run on connected device
flutter run

# Run with specific device
flutter run -d <device-id>

# Run in debug mode with verbose logging
flutter run --debug --verbose
```

### Release Mode

```bash
# Build for Android
flutter build apk --release

# Build for iOS (macOS only)
flutter build ios --release
```

## Testing

### Unit Tests

```bash
# Run all unit tests
flutter test

# Run specific test file
flutter test test/core/services/whisper_service_test.dart
```

### Integration Tests

```bash
# Run integration tests
flutter test integration_test/
```

### Manual Testing

1. **AR Mode Testing**: See [TESTING_AR_MODE_AND_AUDIO.md](TESTING_AR_MODE_AND_AUDIO.md)
2. **Accessibility Testing**: See [ACCESSIBILITY_TESTING.md](ACCESSIBILITY_TESTING.md)
3. **Speech Processing**: See [SPEECH_TO_TEXT_GEMMA_IMPLEMENTATION.md](SPEECH_TO_TEXT_GEMMA_IMPLEMENTATION.md)

## Development Workflow

### 1. Create Feature Branch

```bash
git checkout -b feature/your-feature-name
```

### 2. Make Changes

- Follow the existing code style
- Add tests for new functionality
- Update documentation as needed

### 3. Test Your Changes

```bash
# Run tests
flutter test

# Check code formatting
dart format .

# Analyze code
flutter analyze
```

### 4. Commit and Push

```bash
git add .
git commit -m "feat: add your feature description"
git push origin feature/your-feature-name
```

### 5. Create Pull Request

- Go to GitHub and create a pull request
- Include a detailed description of your changes
- Reference any related issues

## Troubleshooting

### Common Issues

#### Flutter Issues

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

#### iOS Issues

```bash
# Clean iOS build
cd ios
rm -rf build/
pod deintegrate
pod install
cd ..
flutter run
```

#### Android Issues

```bash
# Clean Android build
cd android
./gradlew clean
cd ..
flutter run
```

#### Whisper Model Issues

- Ensure Whisper models are downloaded
- Check model paths in configuration
- See [WHISPER_SETUP.md](WHISPER_SETUP.md) for detailed setup

### Getting Help

1. **Check existing documentation** in the `docs/` folder
2. **Search existing issues** on GitHub
3. **Create a new issue** with detailed information
4. **Join the community** discussions

## Architecture Overview

For detailed architecture information, see:
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture
- [TECHNICAL_WRITEUP.md](TECHNICAL_WRITEUP.md) - Technical implementation details
- [TECHNICAL_DOCUMENTATION.md](TECHNICAL_DOCUMENTATION.md) - Comprehensive technical docs

## Contributing Guidelines

1. **Read the contributing guidelines** in [CONTRIBUTING.md](../CONTRIBUTING.md)
2. **Follow the code style** and conventions
3. **Write tests** for new functionality
4. **Update documentation** when adding features
5. **Test on both platforms** (iOS and Android)

## Next Steps

After setting up your development environment:

1. **Explore the codebase** to understand the architecture
2. **Run the application** on a physical device
3. **Try the AR features** to understand the user experience
4. **Pick an issue** from the GitHub issues list
5. **Start contributing** to the project!

## Support

If you encounter issues during setup:

- **Check the troubleshooting section** above
- **Review the documentation** in the `docs/` folder
- **Search existing issues** on GitHub
- **Create a new issue** with detailed information about your problem

Welcome to the LiveCaptionsXR development team! 🎉 