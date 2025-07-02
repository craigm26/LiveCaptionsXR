# iOS Build Fixes and Feature Restoration PRD

## Document Information
- **PRD ID**: 17
- **Title**: iOS Build Fixes and Feature Restoration
- **Version**: 1.0
- **Date**: July 1, 2025
- **Status**: In Development
- **Priority**: High

## Executive Summary

This PRD documents the iOS build fixes implemented to resolve compilation errors and outlines the roadmap for restoring temporarily disabled features. The project's iOS build was successfully fixed by temporarily commenting out problematic Swift classes and updating the MediaPipe plugin implementation.

## Problem Statement

The iOS build was failing due to multiple compilation errors:
1. Outdated MediaPipe LLM Inference API usage
2. Missing Swift class references in AppDelegate
3. iOS deployment target compatibility issues
4. Pod configuration problems
5. Missing dependency references

## Solution Overview

### Phase 1: Emergency Build Fix ✅ COMPLETED
- Fixed MediaPipe plugin API compatibility
- Temporarily disabled problematic Swift features
- Updated iOS deployment target to 14.0
- Resolved dependency issues
- Successfully achieved buildable state

### Phase 2: Feature Restoration (PLANNED)
- Re-enable all commented Swift classes
- Implement proper MediaPipe integration
- Add comprehensive testing
- Performance optimization

## Technical Details

### Files Modified in Phase 1

#### 1. MediaPipe Plugin (`plugins/gemma3n_multimodal/ios/Classes/Gemma3nMultimodalPlugin.swift`)
**Status**: ✅ Fixed
**Changes**:
- Simplified plugin to basic functionality
- Removed outdated MediaPipe API calls
- Added placeholder methods for future implementation

**Temporarily Disabled**:
```swift
// Full MediaPipe LLM Inference integration
// Streaming API capabilities
// Advanced multimodal features
```

#### 2. iOS AppDelegate (`ios/Runner/AppDelegate.swift`)
**Status**: ⚠️ Temporarily Disabled
**Changes**:
- Commented out all custom Swift class references
- Disabled plugin registrations
- Maintained basic Flutter functionality

**Temporarily Disabled Classes**:
```swift
// VisualSpeakerIdentifier - Face detection and speaker identification
// ARAnchorManager - ARKit anchor management
// HybridLocalizationEngine - Audio-visual fusion localization
// StereoAudioCapturePlugin - Stereo audio capture
// SpeechLocalizerPlugin - Speech localization
```

#### 3. iOS Configuration
**Status**: ✅ Updated
**Changes**:
- iOS deployment target: 12.0 → 14.0
- Updated Podfile for MediaPipe compatibility
- Fixed static linking configuration
- Added shared_preferences dependency

## Phase 2 Implementation Plan

### 2.1 Swift Classes Restoration

#### Priority 1: Core Classes
1. **ARAnchorManager.swift**
   - Verify ARKit integration
   - Test anchor creation and management
   - Ensure SceneKit compatibility

2. **HybridLocalizationEngine.swift**
   - Test SIMD operations
   - Verify Accelerate framework usage
   - Validate fusion algorithms

#### Priority 2: Audio Processing
3. **StereoAudioCapturePlugin.swift**
   - Test audio capture functionality
   - Verify stereo processing
   - Check iOS 14+ compatibility

4. **SpeechLocalizerPlugin.swift**
   - Test speech detection
   - Verify localization algorithms
   - Ensure real-time performance

#### Priority 3: Visual Processing
5. **VisualSpeakerIdentifier.swift**
   - Test Vision framework integration
   - Verify face detection accuracy
   - Check iOS 14+ availability requirements

### 2.2 MediaPipe Integration Restoration

#### Current State
```swift
// Placeholder implementation
public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "loadModel":
        result("Model loading not implemented yet")
    // ... other placeholder methods
    }
}
```

#### Target Implementation
```swift
// Full MediaPipe LLM Inference integration
import MediaPipeTasksGenAI

// Initialize with proper options
let options = LlmInferenceOptions()
options.baseOptions.modelPath = modelPath
options.maxTokens = 1000
options.topk = 40
options.temperature = 0.8
options.randomSeed = 101

let llmInference = try LlmInference(options: options)

// Implement streaming responses
let stream = try llmInference.generateResponseAsync(inputText: prompt)
for try await partial in stream {
    eventSink(partial)
}
```

### 2.3 Testing Strategy

#### Unit Tests
- [ ] Test each Swift class in isolation
- [ ] Verify MediaPipe API integration
- [ ] Test Flutter method channel communication

#### Integration Tests
- [ ] Test ARKit + Audio fusion
- [ ] Test MediaPipe + Audio processing
- [ ] Test Visual + Audio coordination

#### Performance Tests
- [ ] Real-time audio processing
- [ ] AR rendering performance
- [ ] Memory usage optimization
- [ ] Battery impact assessment

#### Device Tests
- [ ] iPhone 12 Pro and newer (iOS 14+)
- [ ] iPad Pro with LiDAR
- [ ] Various lighting conditions
- [ ] Different audio environments

## Implementation Roadmap

### Week 1-2: Foundation
- [x] Set up proper Xcode project structure
- [x] Add Swift files to Xcode target
- [x] Resolve any remaining compilation issues
- [x] Basic functionality testing

### Week 3-4: Core Features
- [x] Restore ARAnchorManager
- [x] Restore HybridLocalizationEngine
- [ ] Basic ARKit integration testing
- [ ] Audio-visual fusion validation

### Week 5-6: Audio Processing
- [x] Restore StereoAudioCapturePlugin
- [x] Restore SpeechLocalizerPlugin
- [x] Real-time audio processing
- [ ] Performance optimization

### Week 7-8: Visual Processing
- [x] Restore VisualSpeakerIdentifier
- [x] Face detection integration
- [ ] Speaker identification accuracy
- [ ] Privacy compliance review

### Week 9-10: MediaPipe Integration
- [x] Implement proper MediaPipe API
- [x] Model loading and management
- [x] Streaming inference
- [x] Multimodal capabilities

### Week 11-12: Testing and Polish
- [ ] Comprehensive testing suite
- [ ] Performance optimization
- [ ] Documentation updates
- [ ] Release preparation

## Risk Assessment

### High Risk
- **MediaPipe API Changes**: New MediaPipe versions may have breaking changes
- **iOS Version Compatibility**: Features may not work on older devices
- **Performance Issues**: Real-time processing may impact battery/performance

### Medium Risk
- **ARKit Limitations**: Not all devices support all ARKit features
- **Audio Processing Latency**: Real-time requirements may be challenging
- **Memory Management**: Multiple heavy frameworks may cause memory pressure

### Low Risk
- **UI Integration**: Flutter-iOS communication is well established
- **Basic Functionality**: Core app features should work reliably

## Success Criteria

### Phase 2 Complete When:
- [x] All Swift classes are uncommented and functional
- [x] MediaPipe integration is fully restored
- [ ] All unit tests pass
- [ ] Integration tests pass on target devices
- [ ] Performance meets real-time requirements
- [ ] Documentation is complete

## Dependencies

### External
- MediaPipe Tasks GenAI framework
- ARKit (iOS 14+)
- Vision framework (iOS 14+)
- AVFoundation
- Accelerate framework

### Internal
- Flutter app architecture
- Dart-Swift method channels
- Audio processing pipeline
- AR rendering system

## Current Project State

### ✅ Working
- iOS project builds successfully
- Basic Flutter app functionality
- Xcode workspace opens correctly
- MediaPipe framework is integrated
- All dependencies are resolved

### ✅ Features Restored
- All custom Swift classes
- Advanced AR features
- Audio processing capabilities
- Visual speaker identification
- MediaPipe LLM inference
- Hybrid localization engine

### 📋 TODO
- ~~Restore all commented functionality~~
- Implement proper testing
- Performance optimization
- Documentation updates

## Getting Started for Developers

### 1. Current Build Process
```bash
cd /Users/user273508/Documents/LiveCaptionsXR
flutter clean && flutter pub get
cd ios && pod install
flutter build ios
open ios/Runner.xcworkspace
```

### 2. Before Uncommenting Features
1. Ensure Xcode project includes all Swift files
2. Verify iOS deployment target is 14.0+
3. Test basic Flutter functionality
4. Check MediaPipe framework integration

### 3. Gradual Restoration Process
1. Start with one Swift class at a time
2. Uncomment class declaration in AppDelegate
3. Test compilation
4. Add unit tests
5. Move to next class

### 4. Testing Each Restoration
```bash
# After uncommenting each feature
flutter clean
cd ios && pod install
flutter build ios

# Run specific tests
flutter test
```

## Contact and Support

For questions about this restoration process, refer to:
- This PRD document
- Individual Swift class documentation
- MediaPipe official documentation
- ARKit Apple documentation

---

**Note**: This document should be updated as features are restored and new issues are discovered during the restoration process.
