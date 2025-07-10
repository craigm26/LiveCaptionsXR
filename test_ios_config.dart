// Test script to verify iOS configuration for TestFlight builds
import 'dart:io';

void main() {
  print('🔍 Testing iOS Configuration for TestFlight Build Issues');

  // Check iOS deployment target consistency
  print('\n📱 Checking iOS deployment target consistency:');

  // Check AppFrameworkInfo.plist
  final appFrameworkInfo = File('ios/Flutter/AppFrameworkInfo.plist');
  if (appFrameworkInfo.existsSync()) {
    final content = appFrameworkInfo.readAsStringSync();
    if (content.contains('<string>14.0</string>')) {
      print('✅ AppFrameworkInfo.plist: iOS 14.0 ✓');
    } else {
      print('❌ AppFrameworkInfo.plist: iOS version mismatch');
    }
  } else {
    print('❌ AppFrameworkInfo.plist: File not found');
  }

  // Check Podfile
  final podfile = File('ios/Podfile');
  if (podfile.existsSync()) {
    final content = podfile.readAsStringSync();
    if (content.contains("platform :ios, '14.0'")) {
      print('✅ Podfile: iOS 14.0 ✓');
    } else {
      print('❌ Podfile: iOS version mismatch');
    }
  } else {
    print('❌ Podfile: File not found');
  }

  // Check Package.swift
  final packageSwift = File('ios/Package.swift');
  if (packageSwift.existsSync()) {
    final content = packageSwift.readAsStringSync();
    if (content.contains('.iOS(.v14)')) {
      print('✅ Package.swift: iOS 14.0 ✓');
    } else {
      print('❌ Package.swift: iOS version mismatch');
    }
  } else {
    print('❌ Package.swift: File not found');
  }

  // Check Info.plist for required capabilities
  print('\n🔐 Checking Info.plist requirements:');
  final infoPlist = File('ios/Runner/Info.plist');
  if (infoPlist.existsSync()) {
    final content = infoPlist.readAsStringSync();

    // Check ARKit capability (should be removed for visionOS support)
    if (content.contains('<string>arkit</string>')) {
      print(
          '⚠️ Info.plist: ARKit capability present (may prevent visionOS support)');
    } else {
      print(
          '✅ Info.plist: ARKit capability properly removed for visionOS support ✓');
    }

    // Check permissions
    final permissions = [
      'NSCameraUsageDescription',
      'NSMicrophoneUsageDescription',
      'NSSpeechRecognitionUsageDescription'
    ];

    for (final permission in permissions) {
      if (content.contains(permission)) {
        print('✅ Info.plist: $permission ✓');
      } else {
        print('❌ Info.plist: $permission missing');
      }
    }
  } else {
    print('❌ Info.plist: File not found');
  }

  // Check assets
  print('\n📁 Checking assets:');
  final assetsDir = Directory('assets');
  if (assetsDir.existsSync()) {
    final modelsDir = Directory('assets/models');
    if (modelsDir.existsSync()) {
      print('✅ Assets: models directory exists ✓');
    } else {
      print('⚠️  Assets: models directory created');
    }

    final logosDir = Directory('assets/logos');
    if (logosDir.existsSync()) {
      print('✅ Assets: logos directory exists ✓');
    } else {
      print('❌ Assets: logos directory missing');
    }
  } else {
    print('❌ Assets: Directory not found');
  }

  print('\n🎯 Configuration check complete!');
  print(
      'If all items show ✅, the configuration should work for TestFlight builds.');
}
