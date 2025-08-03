import 'dart:async';
import 'app_logger.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Camera service for visual processing and capture
/// 
/// This service handles camera initialization, frame capture, and integration
/// with visual processing services for the LiveCaptionsXR application.
class CameraService {
  static final AppLogger _logger = AppLogger.instance;
  
  bool _isCameraStarted = false;
  bool _isInitialized = false;

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  
  Timer? _periodicCaptureTimer;
  final StreamController<List<int>> _frameStreamController = StreamController<List<int>>.broadcast();
  
  /// Initialize the camera service for mobile platforms
  Future<void> initialize() async {
    _logger.i('🏗️ Initializing CameraService...', category: LogCategory.camera);
    try {
      _logger.d('Setting up camera configuration...', category: LogCategory.camera);
      // Initialize camera for mobile platforms (Android and iOS)
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
        _logger.d('Checking available cameras...', category: LogCategory.camera);
        _cameras = await availableCameras();
        final frontCamera = _cameras!.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );
        _cameraController = CameraController(frontCamera, ResolutionPreset.medium);
        await _cameraController!.initialize();
        _isInitialized = true;
        _logger.i('✅ CameraService initialized successfully', category: LogCategory.camera);
      } else {
        _logger.i('ℹ️ CameraService skipped (web platform detected)', category: LogCategory.camera);
        _isInitialized = false;
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Camera initialization failed', category: LogCategory.camera, error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Start camera capture
  void startCamera() {
    _logger.i('📸 Starting camera...', category: LogCategory.camera);
    _logger.d('Current state - Initialized: $_isInitialized, Started: $_isCameraStarted', category: LogCategory.camera);
    
    if (!_isInitialized) {
      _logger.e('❌ Camera not initialized, cannot start', category: LogCategory.camera);
      throw StateError('Camera service not initialized. Call initialize() first.');
    }
    
    if (_isCameraStarted) {
      _logger.w('⚠️ Camera already started, skipping start', category: LogCategory.camera);
      return;
    }
    
    _isCameraStarted = true;
    _startPeriodicCapture();
    _logger.i('✅ Camera started successfully', category: LogCategory.camera);
  }
  
  /// Stop camera capture
  void stopCamera() {
    _logger.i('📸 Stopping camera...', category: LogCategory.camera);
    _logger.d('Current state - Started: $_isCameraStarted', category: LogCategory.camera);
    
    if (!_isCameraStarted) {
      _logger.w('⚠️ Camera not started, nothing to stop', category: LogCategory.camera);
      return;
    }
    
    _stopPeriodicCapture();
    _isCameraStarted = false;
    _logger.i('✅ Camera stopped successfully', category: LogCategory.camera);
  }

  /// Get the camera preview widget
  Widget? getCameraPreviewWidget() {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      return CameraPreview(_cameraController!);
    }
    return null;
  }
  
  /// Capture a single frame from the camera
  Future<List<int>?> captureFrame() async {
    _logger.d('📷 Capturing camera frame...', category: LogCategory.camera);
    
    if (!_isCameraStarted || _cameraController == null) {
      _logger.w('⚠️ Camera not started or controller unavailable, cannot capture frame', category: LogCategory.camera);
      return null;
    }
    
    if (!_cameraController!.value.isInitialized) {
      _logger.w('⚠️ Camera controller not initialized, cannot capture frame', category: LogCategory.camera);
      return null;
    }
    
    try {
      _logger.d('Acquiring frame from camera...', category: LogCategory.camera);
      
      final XFile imageFile = await _cameraController!.takePicture();
      final imageBytes = await imageFile.readAsBytes();
      
      _logger.d('✅ Frame captured: ${imageBytes.length} bytes', category: LogCategory.camera);
      return imageBytes;
      
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to capture frame', category: LogCategory.camera, error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Start periodic frame capture every 5 seconds
  void _startPeriodicCapture() {
    _logger.i('⏰ Starting periodic frame capture (5 seconds interval)', category: LogCategory.camera);
    _periodicCaptureTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final frame = await captureFrame();
      if (frame != null) {
        _frameStreamController.add(frame);
        _logger.d('📷 Frame added to stream: ${frame.length} bytes', category: LogCategory.camera);
      }
    });
  }
  
  /// Stop periodic frame capture
  void _stopPeriodicCapture() {
    _logger.i('⏰ Stopping periodic frame capture', category: LogCategory.camera);
    _periodicCaptureTimer?.cancel();
    _periodicCaptureTimer = null;
  }
  
  /// Stream of captured frames
  Stream<List<int>> get frameStream => _frameStreamController.stream;
  
  /// Check if camera is available and ready
  bool get isReady => _isInitialized && _isCameraStarted;
  
  /// Dispose of camera resources
  void dispose() {
    _logger.i('🧹 Disposing CameraService...', category: LogCategory.camera);
    _logger.d('Current state - Initialized: $_isInitialized, Started: $_isCameraStarted', category: LogCategory.camera);
    _stopPeriodicCapture();
    _frameStreamController.close();
    _cameraController?.dispose();
    _isInitialized = false;
    _isCameraStarted = false;
    _logger.i('✅ CameraService disposed successfully', category: LogCategory.camera);
  }
} 