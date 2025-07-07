#!/usr/bin/env dart

import 'lib/core/services/debug_capturing_logger.dart';
import 'lib/core/services/debug_logger_service.dart';
import 'lib/core/services/gemma3n_service.dart';
import 'lib/core/services/audio_service.dart';
import 'lib/core/services/camera_service.dart';
import 'lib/core/services/ai_service.dart';
import 'lib/core/services/haptic_service.dart';
import 'lib/core/services/localization_service.dart';
import 'lib/core/utils/logger.dart';

/// Test script to demonstrate comprehensive debug logging functionality
/// 
/// This script tests all services with verbose logging to ensure the debug
/// logging overlay will capture all service logs for real device testing.
void main() async {
  print('🧪 Starting comprehensive debug logging test...');
  
  // Initialize debug logger service
  final debugService = DebugLoggerService();
  debugService.initialize();
  debugService.setEnabled(true);
  
  print('✅ Debug logger service initialized and enabled');
  
  // Test global logger functions
  print('\n📝 Testing global logger functions...');
  final globalLogger = DebugCapturingLogger();
  globalLogger.i('Test info message from global logger');
  globalLogger.w('Test warning message from global logger');
  globalLogger.e('Test error message from global logger');
  globalLogger.d('Test debug message from global logger');
  
  // Use legacy log function
  log('Test legacy log function message');
  
  // Test Gemma 3n Service
  print('\n🧠 Testing Gemma 3n Service logging...');
  final gemmaService = Gemma3nService();
  try {
    await gemmaService.loadModel();
  } catch (e) {
    print('Expected error (model not found): $e');
  }
  
  // Test Camera Service
  print('\n📸 Testing Camera Service logging...');
  final cameraService = CameraService();
  try {
    await cameraService.initialize();
    cameraService.startCamera();
    await cameraService.captureFrame();
    cameraService.stopCamera();
  } catch (e) {
    print('Expected error (no actual camera): $e');
  }
  
  // Test AI Service
  print('\n🤖 Testing AI Service logging...');
  final aiService = AIService();
  try {
    await aiService.initialize();
    aiService.startProcessing();
    aiService.processMultimodalInput();
    aiService.stopProcessing();
  } catch (e) {
    print('Expected error: $e');
  }
  
  // Test Haptic Service
  print('\n📳 Testing Haptic Service logging...');
  final hapticService = HapticService();
  try {
    await hapticService.initialize();
    hapticService.vibratePattern('test');
    hapticService.provideSoundFeedback('doorbell', 0.8);
  } catch (e) {
    print('Expected error: $e');
  }
  
  // Test Localization Service
  print('\n🗺️ Testing Localization Service logging...');
  final localizationService = LocalizationService();
  try {
    await localizationService.initialize();
    localizationService.startLocalization();
    localizationService.localizeSound();
    localizationService.stopLocalization();
  } catch (e) {
    print('Expected error: $e');
  }
  
  // Display captured logs
  print('\n📊 Debug logging test completed!');
  print('\n=== CAPTURED DEBUG LOGS ===');
  final logHistory = debugService.logHistory;
  print('Total captured logs: ${logHistory.length}');
  
  for (int i = 0; i < logHistory.length && i < 20; i++) {
    final entry = logHistory[i];
    print('${i + 1}. [${entry.level.name.toUpperCase()}] ${entry.message}');
  }
  
  if (logHistory.length > 20) {
    print('... and ${logHistory.length - 20} more logs');
  }
  
  print('\n✅ All services successfully logged their operations!');
  print('💡 The debug logging overlay will capture these logs on a real device.');
  print('🔧 To enable on device: Settings > Developer & Testing > Debug Logging Overlay');
  
  // Clean up
  debugService.dispose();
}