import 'debug_capturing_logger.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Camera service for visual processing and capture
/// 
/// This service handles camera initialization, frame capture, and integration
/// with visual processing services for the LiveCaptionsXR application.
class CameraService {
  static final DebugCapturingLogger _logger = DebugCapturingLogger();
  
  bool _isCameraStarted = false;
  bool _isInitialized = false;

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  
  /// Initialize the camera service (for emulator fallback only)
  Future<void> initialize() async {
    _logger.i('🏗️ Initializing CameraService...');
    try {
      _logger.d('Setting up camera configuration...');
      // Only initialize camera for Android emulator fallback
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        _logger.d('Checking available cameras...');
        _cameras = await availableCameras();
        final frontCamera = _cameras!.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );
        _cameraController = CameraController(frontCamera, ResolutionPreset.medium);
        await _cameraController!.initialize();
        _isInitialized = true;
        _logger.i('✅ CameraService initialized successfully');
      } else {
        _logger.i('ℹ️ CameraService skipped (not Android emulator)');
        _isInitialized = false;
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Camera initialization failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Start camera capture (for emulator fallback only)
  void startCamera() {
    _logger.i('📸 Starting camera...');
    _logger.d('Current state - Initialized: $_isInitialized, Started: $_isCameraStarted');
    
    if (!_isInitialized) {
      _logger.e('❌ Camera not initialized, cannot start');
      throw StateError('Camera service not initialized. Call initialize() first.');
    }
    
    if (_isCameraStarted) {
      _logger.w('⚠️ Camera already started, skipping start');
      return;
    }
    
    _isCameraStarted = true;
    _logger.i('✅ Camera started successfully');
  }
  
  /// Stop camera capture
  void stopCamera() {
    _logger.i('📸 Stopping camera...');
    _logger.d('Current state - Started: $_isCameraStarted');
    
    if (!_isCameraStarted) {
      _logger.w('⚠️ Camera not started, nothing to stop');
      return;
    }
    
    _isCameraStarted = false;
    _logger.i('✅ Camera stopped successfully');
  }

  /// Get the camera preview widget (for emulator fallback only)
  Widget? getCameraPreviewWidget() {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      return CameraPreview(_cameraController!);
    }
    return null;
  }
  
  /// Capture a single frame from the camera
  Future<List<int>?> captureFrame() async {
    _logger.d('📷 Capturing camera frame...');
    
    if (!_isCameraStarted) {
      _logger.w('⚠️ Camera not started, cannot capture frame');
      return null;
    }
    
    try {
      _logger.d('Acquiring frame from camera...');
      // TODO: Add actual frame capture logic
      
      // Placeholder - return empty frame
      final frame = <int>[];
      _logger.d('✅ Frame captured: ${frame.length} bytes');
      return frame;
      
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to capture frame', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Check if camera is available and ready
  bool get isReady => _isInitialized && _isCameraStarted;
  
  /// Dispose of camera resources
  void dispose() {
    _logger.i('🧹 Disposing CameraService...');
    _logger.d('Current state - Initialized: $_isInitialized, Started: $_isCameraStarted');
    _cameraController?.dispose();
    _isInitialized = false;
    _isCameraStarted = false;
    _logger.i('✅ CameraService disposed successfully');
  }
} 