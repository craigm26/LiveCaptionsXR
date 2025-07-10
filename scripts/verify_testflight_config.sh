#!/bin/bash

# TestFlight Build Verification Script
# This script checks common issues that cause TestFlight build failures

echo "🔍 TestFlight Build Verification Script"
echo "========================================"

# Check iOS deployment target consistency
echo ""
echo "📱 Checking iOS deployment target consistency:"

# Function to check iOS version in file
check_ios_version() {
    local file=$1
    local pattern=$2
    local description=$3
    
    if [ -f "$file" ]; then
        if grep -q "$pattern" "$file"; then
            echo "✅ $description: iOS 14.0 ✓"
        else
            echo "❌ $description: iOS version mismatch"
            return 1
        fi
    else
        echo "❌ $description: File not found"
        return 1
    fi
}

# Check deployment targets
check_ios_version "ios/Flutter/AppFrameworkInfo.plist" "<string>14.0</string>" "AppFrameworkInfo.plist"
check_ios_version "ios/Podfile" "platform :ios, '14.0'" "Podfile"
check_ios_version "ios/Package.swift" ".iOS(.v14)" "Package.swift"

# Check Info.plist requirements
echo ""
echo "🔐 Checking Info.plist requirements:"

if [ -f "ios/Runner/Info.plist" ]; then
    # Check ARKit capability (should be removed for visionOS support)
    if grep -q "<string>arkit</string>" "ios/Runner/Info.plist"; then
        echo "⚠️ Info.plist: ARKit capability present (may prevent visionOS support)"
    else
        echo "✅ Info.plist: ARKit capability properly removed for visionOS support ✓"
    fi
    
    # Check required permissions
    permissions=("NSCameraUsageDescription" "NSMicrophoneUsageDescription" "NSSpeechRecognitionUsageDescription")
    for permission in "${permissions[@]}"; do
        if grep -q "$permission" "ios/Runner/Info.plist"; then
            echo "✅ Info.plist: $permission ✓"
        else
            echo "❌ Info.plist: $permission missing"
        fi
    done
else
    echo "❌ Info.plist: File not found"
fi

# Check Swift files for iOS availability
echo ""
echo "🧬 Checking Swift files for iOS availability:"

swift_files=("ios/Runner/ARAnchorManager.swift" "ios/Runner/ARViewController.swift" "ios/Runner/VisualObjectPlugin.swift")
for file in "${swift_files[@]}"; do
    if [ -f "$file" ]; then
        if grep -q "@available(iOS 14.0, \*)" "$file"; then
            echo "✅ $(basename "$file"): iOS 14.0 availability check ✓"
        else
            echo "❌ $(basename "$file"): iOS availability check missing"
        fi
    else
        echo "❌ $(basename "$file"): File not found"
    fi
done

# Check assets
echo ""
echo "📁 Checking assets:"
if [ -d "assets" ]; then
    if [ -d "assets/models" ]; then
        echo "✅ Assets: models directory exists ✓"
    else
        echo "❌ Assets: models directory missing"
    fi
    
    if [ -d "assets/logos" ]; then
        echo "✅ Assets: logos directory exists ✓"
    else
        echo "❌ Assets: logos directory missing"
    fi
else
    echo "❌ Assets: Directory not found"
fi

# Check for Generated.xcconfig
echo ""
echo "🔧 Checking Flutter generated files:"
if [ -f "ios/Flutter/Generated.xcconfig" ]; then
    echo "✅ Generated.xcconfig: File exists ✓"
else
    echo "❌ Generated.xcconfig: File missing (run 'flutter pub get')"
fi

echo ""
echo "🎯 Build verification complete!"
echo "If all items show ✅, the configuration should work for TestFlight builds."
echo ""
echo "📝 Common next steps if issues remain:"
echo "1. Clean build: flutter clean && cd ios && pod install"
echo "2. Verify Xcode project settings match deployment target"
echo "3. Check for any custom entitlements that might be needed"
echo "4. Ensure all required certificates and provisioning profiles are valid"