# iOS App Size Optimization Guide

## Problem
The iOS app bundle was 4 GB after compilation, exceeding Apple's TestFlight size limits.

## Root Cause
- MediaPipeTasksGenAI framework is inherently large (~1-2GB)
- Missing iOS build optimizations for size reduction
- Debug symbols and unstripped binaries included in release builds

## Solutions Implemented

### 1. iOS Build Settings Optimizations
Added the following build settings to Release and Profile configurations:

```
DEAD_CODE_STRIPPING = YES
DEPLOYMENT_POSTPROCESSING = YES  
STRIP_INSTALLED_PRODUCT = YES
STRIP_STYLE = all
GCC_OPTIMIZATION_LEVEL = s  // Optimize for size
```

### 2. Podfile Optimizations
Enhanced the Podfile with size-specific optimizations:
- Added size optimization flags for Release/Profile builds
- Ensured proper stripping of symbols
- Optimized MediaPipe framework linking

### 3. Build Script
Created `scripts/build_ios_optimized.sh` with:
- Tree shaking for icons
- Code obfuscation
- Split debug info (not included in final build)
- Size-optimized build flags

## Expected Size Reduction
These optimizations should reduce the app size from ~4GB to approximately:
- **Without MediaPipe models**: ~500MB - 1GB
- **With on-demand model loading**: Target size under 4GB

## Build Instructions

### Option 1: Using the Optimized Build Script
```bash
./scripts/build_ios_optimized.sh
```

### Option 2: Manual Build with Optimizations
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter build ios --release \
  --tree-shake-icons \
  --split-debug-info=build/ios-debug-info \
  --obfuscate
```

### Option 3: Xcode Archive
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select "Any iOS Device" as target
3. Product → Archive
4. Use Xcode's standard export options for distribution

## Additional Recommendations

### 1. Model Loading Strategy
- **Current**: Models should be loaded on-demand, not bundled
- **Verify**: No `.task` files are included in the app bundle
- **Use**: Download models from server or package separately

### 2. MediaPipe Framework Usage
- **Keep**: Only `MediaPipeTasksGenAI` (essential)
- **Remove**: `MediaPipeTasksGenAIC` and `MediaPipeTasksVision` if added
- **Verify**: Only necessary MediaPipe components are linked

### 3. Asset Optimization
- Ensure large assets are loaded on-demand
- Use asset catalogs for automatic app thinning
- Compress images and audio files

### 4. Monitoring Build Size
```bash
# Check app bundle size
du -sh build/ios/iphoneos/Runner.app

# Check individual framework sizes
find build/ios/iphoneos/Runner.app/Frameworks -name "*.framework" -exec du -sh {} \;
```

## Troubleshooting

### If Size is Still Too Large
1. Check for bundled model files: `find . -name "*.task" -o -name "*.tflite"`
2. Verify MediaPipe dependencies: Only GenAI should be included
3. Check for duplicate frameworks in build
4. Ensure all optimizations are applied in Xcode project

### Build Failures
1. Clean all builds: `flutter clean && rm -rf ios/Pods`
2. Reinstall dependencies: `flutter pub get && cd ios && pod install`
3. Check iOS deployment target is 14.0+
4. Verify Xcode and Flutter versions are compatible

## Impact
These optimizations should bring the iOS app size well under the 4GB TestFlight limit while maintaining all functionality.