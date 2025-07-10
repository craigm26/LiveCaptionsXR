#!/bin/bash

# iOS Build Size Optimization Script
# This script builds the iOS app with maximum size optimization

set -e

echo "🔧 Starting iOS build with size optimizations..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf ios/build
rm -rf build

# Ensure dependencies are up to date
echo "📦 Getting dependencies..."
flutter pub get

# Clean and install pods with size optimizations
echo "🎯 Installing pods..."
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..

# Build with size optimization flags
echo "🚀 Building iOS app with size optimizations..."
flutter build ios --release \
  --no-codesign \
  --build-name=1.0.0 \
  --build-number=1 \
  --dart-define=FLUTTER_WEB_USE_SKIA=false \
  --dart-define=IS_TESTFLIGHT=true \
  --tree-shake-icons \
  --split-debug-info=build/ios-debug-info \
  --obfuscate

echo "✅ iOS build completed with size optimizations!"
echo "📱 To create archive:"
echo "   1. Open ios/Runner.xcworkspace in Xcode"
echo "   2. Select 'Any iOS Device' as target"
echo "   3. Product -> Archive"
echo "   4. Use the ExportOptions.plist for app store distribution"
echo ""
echo "ℹ️  This build includes IS_TESTFLIGHT=true flag to enable debug logging in TestFlight builds"

# Display approximate build size
if [ -d "build/ios/iphoneos/Runner.app" ]; then
    BUILD_SIZE=$(du -sh build/ios/iphoneos/Runner.app | cut -f1)
    echo "📊 Approximate build size: $BUILD_SIZE"
fi