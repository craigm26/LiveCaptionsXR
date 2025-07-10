#!/usr/bin/env dart

/// Test script to understand and debug the speech processing flow
/// This script helps identify where the audio capture stops working

import 'dart:async';
import 'dart:typed_data';
import 'dart:math' show sqrt;

import 'lib/core/services/speech_processor.dart';
import 'lib/core/services/stereo_audio_capture.dart';
import 'lib/core/models/speech_config.dart';

void main() async {
  print('🧪 Starting speech processing flow test...');
  
  // Test 1: Initialize Speech Processor
  print('\n1. Testing SpeechProcessor initialization...');
  final speechProcessor = SpeechProcessor();
  
  print('   - Creating speech processor...');
  final initSuccess = await speechProcessor.initialize();
  print('   - Initialization result: $initSuccess');
  
  if (!initSuccess) {
    print('❌ Speech processor initialization failed - stopping test');
    return;
  }
  
  // Test 2: Start Speech Processing
  print('\n2. Testing speech processing start...');
  final startSuccess = await speechProcessor.startProcessing();
  print('   - Start processing result: $startSuccess');
  
  if (!startSuccess) {
    print('❌ Speech processing start failed - stopping test');
    return;
  }
  
  // Test 3: Listen for speech results
  print('\n3. Setting up speech result listener...');
  int resultCount = 0;
  final subscription = speechProcessor.speechResults.listen((result) {
    resultCount++;
    print('   📤 Speech result #$resultCount: "${result.text}" (confidence: ${result.confidence}, final: ${result.isFinal})');
  });
  
  // Test 4: Create stereo audio capture
  print('\n4. Testing stereo audio capture...');
  final audioCapture = StereoAudioCapture();
  
  print('   - Starting audio capture...');
  try {
    await audioCapture.startRecording();
    print('   ✅ Audio capture started successfully');
  } catch (e) {
    print('   ❌ Audio capture failed: $e');
    return;
  }
  
  // Test 5: Process audio frames
  print('\n5. Processing audio frames and sending to speech processor...');
  int frameCount = 0;
  final audioSubscription = audioCapture.frames.listen((frame) async {
    frameCount++;
    final monoFrame = frame.toMono();
    final frameSize = monoFrame.length;
    
    // Calculate RMS level
    double rmsLevel = 0.0;
    for (int i = 0; i < frameSize; i++) {
      rmsLevel += monoFrame[i] * monoFrame[i];
    }
    rmsLevel = frameSize > 0 ? sqrt(rmsLevel / frameSize) : 0.0;
    
    print('   📊 Frame #$frameCount: ${frameSize} samples, RMS: ${rmsLevel.toStringAsFixed(4)}');
    
    // Send to speech processor
    if (frameCount % 10 == 0) { // Only log every 10th frame to avoid spam
      print('   🎤 Sending audio chunk to speech processor...');
    }
    
    try {
      await speechProcessor.processAudioChunk(monoFrame);
      if (frameCount % 10 == 0) {
        print('   ✅ Audio chunk sent successfully');
      }
    } catch (e) {
      print('   ❌ Failed to send audio chunk: $e');
    }
  });
  
  // Test 6: Run for a limited time
  print('\n6. Running test for 10 seconds...');
  await Future.delayed(Duration(seconds: 10));
  
  // Cleanup
  print('\n7. Cleaning up...');
  await audioSubscription.cancel();
  await audioCapture.stopRecording();
  await subscription.cancel();
  await speechProcessor.stopProcessing();
  await speechProcessor.dispose();
  
  print('\n✅ Test completed!');
  print('📊 Results summary:');
  print('   - Audio frames processed: $frameCount');
  print('   - Speech results received: $resultCount');
  
  if (resultCount == 0) {
    print('⚠️  No speech results received - this indicates an issue with the speech processing pipeline');
  } else {
    print('✅ Speech processing pipeline is working correctly');
  }
}