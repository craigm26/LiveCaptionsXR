# LiveCaptionsXR Testing Guide

This guide provides comprehensive testing strategies and procedures for LiveCaptionsXR, ensuring quality and reliability across all features.

## Testing Overview

LiveCaptionsXR requires testing across multiple dimensions due to its complex architecture involving:
- **On-device AI** (Whisper and Gemma 3n)
- **AR functionality** (ARKit/ARCore)
- **Audio processing** (real-time capture and analysis)
- **Accessibility features** (spatial captioning)
- **Cross-platform compatibility** (iOS and Android)

## Testing Categories

### 1. Unit Tests

Unit tests verify individual components and services in isolation.

#### Core Services Testing

```bash
# Run all unit tests
flutter test

# Run specific service tests
flutter test test/core/services/
```

**Key Test Areas:**
- `WhisperService` - Speech recognition functionality
- `Gemma3nService` - Text enhancement
- `AudioCaptureService` - Audio processing
- `ARSessionService` - AR session management
- `HybridLocalizationEngine` - Spatial positioning

#### Example Unit Test Structure

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:livecaptionsxr/core/services/whisper_service.dart';

void main() {
  group('WhisperService', () {
    late WhisperService whisperService;

    setUp(() {
      whisperService = WhisperService();
    });

    test('should initialize successfully', () async {
      await whisperService.initialize();
      expect(whisperService.isInitialized, isTrue);
    });

    test('should process audio and return transcription', () async {
      // Test implementation
    });
  });
}
```

### 2. Integration Tests

Integration tests verify that multiple components work together correctly.

#### AR Mode Integration Testing

See [TESTING_AR_MODE_AND_AUDIO.md](TESTING_AR_MODE_AND_AUDIO.md) for detailed procedures.

**Key Test Scenarios:**
- AR session initialization
- Audio capture during AR mode
- Caption rendering in 3D space
- Spatial positioning accuracy
- Performance under load

#### Speech Processing Integration

See [SPEECH_TO_TEXT_GEMMA_IMPLEMENTATION.md](SPEECH_TO_TEXT_GEMMA_IMPLEMENTATION.md) for implementation details.

**Test Workflow:**
1. Audio capture → Whisper processing → Gemma enhancement → Spatial rendering
2. Verify end-to-end latency
3. Test accuracy of transcriptions
4. Validate spatial positioning

### 3. Accessibility Testing

Accessibility testing ensures the app is usable by people with disabilities.

See [ACCESSIBILITY_TESTING.md](ACCESSIBILITY_TESTING.md) for comprehensive guidelines.

#### Key Accessibility Test Areas

**Visual Accessibility:**
- High contrast themes
- Scalable text
- Clear spatial indicators
- Color-blind friendly design

**Auditory Accessibility:**
- Haptic feedback for directional information
- Visual indicators for audio events
- Caption positioning accuracy

**Motor Accessibility:**
- Touch target sizes
- Gesture alternatives
- Voice control compatibility

### 4. Performance Testing

Performance testing ensures the app runs smoothly on target devices.

#### Memory Usage Testing

```bash
# Monitor memory usage during AR sessions
flutter run --profile
```

**Key Metrics:**
- Memory usage during AR sessions
- CPU utilization during speech processing
- Battery consumption
- Frame rate in AR mode

#### Load Testing

- Test with continuous audio input
- Verify performance with multiple speakers
- Test AR session duration limits
- Monitor thermal throttling effects

### 5. Platform-Specific Testing

#### iOS Testing

**Required Setup:**
- Physical iOS device with ARKit support
- Xcode for debugging
- iOS Simulator for basic functionality

**Key Test Areas:**
- ARKit integration
- iOS permissions handling
- Background audio processing
- iOS-specific UI elements

#### Android Testing

**Required Setup:**
- Physical Android device with ARCore support
- Android Studio for debugging
- Android emulator for basic functionality

**Key Test Areas:**
- ARCore integration
- Android permissions handling
- Background processing
- Android-specific UI elements

## Manual Testing Procedures

### AR Mode Testing

1. **Prerequisites:**
   - Physical device with AR capabilities
   - Well-lit environment
   - Multiple speakers for testing

2. **Test Procedure:**
   ```bash
   # Start AR mode
   flutter run --debug
   ```

3. **Test Scenarios:**
   - Single speaker in front
   - Multiple speakers in different positions
   - Moving speakers
   - Background noise handling
   - Caption positioning accuracy

### Audio Processing Testing

1. **Audio Quality Tests:**
   - Clear speech recognition
   - Background noise filtering
   - Multiple language support
   - Accent recognition

2. **Performance Tests:**
   - Real-time processing latency
   - Memory usage during audio capture
   - Battery consumption

### Accessibility Testing

1. **Screen Reader Testing:**
   - VoiceOver (iOS)
   - TalkBack (Android)
   - Navigation flow
   - Content descriptions

2. **Visual Accessibility:**
   - High contrast mode
   - Text scaling
   - Color contrast ratios
   - Spatial indicators

## Automated Testing

### Continuous Integration

The project uses GitHub Actions for automated testing:

```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter test
      - run: flutter analyze
```

### Test Coverage

```bash
# Generate test coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

**Target Coverage:**
- Core services: >90%
- UI components: >80%
- Integration tests: >70%

## Debugging and Troubleshooting

### Common Issues

#### AR Session Crashes

1. **Check device compatibility**
2. **Verify ARKit/ARCore installation**
3. **Check camera permissions**
4. **Monitor memory usage**

#### Audio Processing Issues

1. **Verify microphone permissions**
2. **Check audio input levels**
3. **Test with different audio sources**
4. **Monitor Whisper model loading**

#### Performance Issues

1. **Profile memory usage**
2. **Check CPU utilization**
3. **Monitor thermal throttling**
4. **Test on different device tiers**

### Debug Tools

#### Flutter Inspector

```bash
flutter run --debug
# Open Flutter Inspector in IDE
```

#### Performance Profiling

```bash
flutter run --profile
# Use Flutter DevTools for profiling
```

#### Logging

```dart
// Enable debug logging
import 'package:logging/logging.dart';

final logger = Logger('LiveCaptionsXR');
logger.info('Debug information');
```

## Test Data and Resources

### Audio Test Files

- Clear speech samples
- Background noise samples
- Multiple language samples
- Accent variations

### AR Test Environments

- Indoor environments with good lighting
- Multiple speaker scenarios
- Moving target scenarios
- Complex spatial arrangements

## Reporting and Documentation

### Bug Reports

When reporting bugs, include:

1. **Device information** (model, OS version)
2. **Reproduction steps**
3. **Expected vs actual behavior**
4. **Logs and error messages**
5. **Screenshots or videos**

### Test Results

Document test results including:

1. **Test environment** (device, OS, conditions)
2. **Test scenarios** covered
3. **Performance metrics**
4. **Issues found and resolutions**
5. **Recommendations for improvement**

## Quality Assurance Checklist

### Pre-Release Testing

- [ ] All unit tests pass
- [ ] Integration tests pass
- [ ] Performance benchmarks met
- [ ] Accessibility requirements satisfied
- [ ] Cross-platform compatibility verified
- [ ] Security review completed
- [ ] Documentation updated

### Release Testing

- [ ] App store submission testing
- [ ] Beta testing with real users
- [ ] Accessibility audit completed
- [ ] Performance monitoring enabled
- [ ] Crash reporting configured

## Continuous Improvement

### Test Strategy Evolution

1. **Regular test plan reviews**
2. **User feedback integration**
3. **Performance benchmark updates**
4. **New test scenario identification**
5. **Automation opportunities**

### Metrics and KPIs

- **Test coverage percentage**
- **Bug detection rate**
- **Performance regression detection**
- **User-reported issues**
- **Accessibility compliance**

## Resources

- [Flutter Testing Documentation](https://flutter.dev/docs/testing)
- [iOS Testing Guide](https://developer.apple.com/testing/)
- [Android Testing Guide](https://developer.android.com/testing)
- [Accessibility Testing Tools](https://www.w3.org/WAI/ER/tools/)
- [Performance Testing Best Practices](https://flutter.dev/docs/perf/best-practices)

---

This testing guide should be updated regularly as new features are added and testing requirements evolve. For specific implementation details, refer to the individual testing documentation files in the `docs/` folder. 