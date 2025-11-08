import 'dart:async';
import 'app_logger.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Camera service for visual processing and capture
///
/// This service handles camera initialization, frame capture, and integration
/// with visual processing services for the LiveCaptionsXR application.
class CameraService {
  static final AppLogger _logger = AppLogger.instance;

  bool _isCameraStarted = false;
  bool _isInitialized = false;
  Completer<void>? _initializeCompleter;

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  Timer? _periodicCaptureTimer;
  final StreamController<List<int>> _frameStreamController =
      StreamController<List<int>>.broadcast();
  bool _isCaptureInProgress = false;

  static const List<ResolutionPreset> _resolutionFallbacks = <ResolutionPreset>[
    ResolutionPreset.medium,
    ResolutionPreset.low,
  ];
  int _resolutionIndex = 0;

  /// Initialize the camera service for mobile platforms
  Future<void> initialize() async {
    if (_initializeCompleter != null) {
      return _initializeCompleter!.future;
    }

    if (_isInitialized) {
      return;
    }

    final completer = Completer<void>();
    _initializeCompleter = completer;
    _logger.i(
      '🏗️ Initializing CameraService...',
      category: LogCategory.camera,
    );
    try {
      _logger.d(
        'Setting up camera configuration...',
        category: LogCategory.camera,
      );
      // Initialize camera for mobile platforms (Android and iOS)
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        _logger.d(
          'Checking available cameras...',
          category: LogCategory.camera,
        );
        await _ensureCameraPermission();
        _cameras = await availableCameras();
        final frontCamera = _cameras!.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );
        await _initializeCameraController(frontCamera);
        _isInitialized = true;
        _logger.i(
          '✅ CameraService initialized successfully',
          category: LogCategory.camera,
        );
      } else {
        _logger.i(
          'ℹ️ CameraService skipped (web platform detected)',
          category: LogCategory.camera,
        );
        _isInitialized = false;
      }
      completer.complete();
    } catch (e, stackTrace) {
      _logger.e(
        '❌ Camera initialization failed',
        category: LogCategory.camera,
        error: e,
        stackTrace: stackTrace,
      );
      completer.completeError(e, stackTrace);
      rethrow;
    } finally {
      _initializeCompleter = null;
    }
  }

  /// Start camera capture
  void startCamera() {
    _logger.i('📸 Starting camera...', category: LogCategory.camera);
    _logger.d(
      'Current state - Initialized: $_isInitialized, Started: $_isCameraStarted',
      category: LogCategory.camera,
    );

    if (!_isInitialized) {
      _logger.e(
        '❌ Camera not initialized, cannot start',
        category: LogCategory.camera,
      );
      throw StateError(
        'Camera service not initialized. Call initialize() first.',
      );
    }

    if (_isCameraStarted) {
      _logger.w(
        '⚠️ Camera already started, skipping start',
        category: LogCategory.camera,
      );
      return;
    }

    _isCameraStarted = true;
    _startPeriodicCapture();
    _logger.i('✅ Camera started successfully', category: LogCategory.camera);
  }

  /// Stop camera capture
  void stopCamera() {
    _logger.i('📸 Stopping camera...', category: LogCategory.camera);
    _logger.d(
      'Current state - Started: $_isCameraStarted',
      category: LogCategory.camera,
    );

    if (!_isCameraStarted) {
      _logger.w(
        '⚠️ Camera not started, nothing to stop',
        category: LogCategory.camera,
      );
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
      _logger.w(
        '⚠️ Camera not started or controller unavailable, cannot capture frame',
        category: LogCategory.camera,
      );
      return null;
    }

    if (!_cameraController!.value.isInitialized) {
      _logger.w(
        '⚠️ Camera controller not initialized, cannot capture frame',
        category: LogCategory.camera,
      );
      return null;
    }

    if (_isCaptureInProgress) {
      _logger.w(
        '⚠️ Previous capture still in progress, skipping new capture request',
        category: LogCategory.camera,
      );
      return null;
    }

    var attempt = 0;
    while (attempt < 2) {
      attempt += 1;
      try {
        _isCaptureInProgress = true;
        _logger.d(
          'Acquiring frame from camera...',
          category: LogCategory.camera,
        );

        final XFile imageFile = await _cameraController!.takePicture();
        final imageBytes = await imageFile.readAsBytes();

        _logger.d(
          '✅ Frame captured: ${imageBytes.length} bytes',
          category: LogCategory.camera,
        );
        return imageBytes;
      } on CameraException catch (cameraError, stackTrace) {
        _logger.e(
          '❌ Failed to capture frame',
          category: LogCategory.camera,
          error: cameraError,
          stackTrace: stackTrace,
        );

        final bool canRetry =
            attempt == 1 && await _handleCameraException(cameraError);
        if (canRetry) {
          _logger.i(
            '🔁 Retrying capture after camera reconfiguration',
            category: LogCategory.camera,
          );
          continue;
        }

        return null;
      } catch (e, stackTrace) {
        _logger.e(
          '❌ Failed to capture frame',
          category: LogCategory.camera,
          error: e,
          stackTrace: stackTrace,
        );
        return null;
      } finally {
        _isCaptureInProgress = false;
      }
    }

    return null;
  }

  /// Start periodic frame capture every 5 seconds
  void _startPeriodicCapture() {
    _logger.i(
      '⏰ Starting periodic frame capture (5 seconds interval)',
      category: LogCategory.camera,
    );
    _periodicCaptureTimer = Timer.periodic(const Duration(seconds: 5), (
      timer,
    ) async {
      final frame = await captureFrame();
      if (frame != null) {
        _frameStreamController.add(frame);
        _logger.d(
          '📷 Frame added to stream: ${frame.length} bytes',
          category: LogCategory.camera,
        );
      }
    });
  }

  /// Stop periodic frame capture
  void _stopPeriodicCapture() {
    _logger.i(
      '⏰ Stopping periodic frame capture',
      category: LogCategory.camera,
    );
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
    _logger.d(
      'Current state - Initialized: $_isInitialized, Started: $_isCameraStarted',
      category: LogCategory.camera,
    );
    _stopPeriodicCapture();
    _frameStreamController.close();
    _cameraController?.dispose();
    _isInitialized = false;
    _isCameraStarted = false;
    _logger.i(
      '✅ CameraService disposed successfully',
      category: LogCategory.camera,
    );
  }

  Future<void> _ensureCameraPermission() async {
    _logger.d(
      'Requesting camera permission if needed...',
      category: LogCategory.camera,
    );
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }

    if (!status.isGranted) {
      _logger.e(
        '⚠️ Camera permission denied. Cannot initialize camera.',
        category: LogCategory.camera,
      );
      throw CameraException(
        'CameraAccessDenied',
        'Camera access permission was denied.',
      );
    }
  }

  Future<void> _initializeCameraController(
    CameraDescription cameraDescription, {
    int startIndex = 0,
  }) async {
    CameraException? lastError;
    for (var index = startIndex; index < _resolutionFallbacks.length; index++) {
      final preset = _resolutionFallbacks[index];
      _logger.d(
        'Attempting camera initialization with preset: $preset',
        category: LogCategory.camera,
      );
      final controller = CameraController(
        cameraDescription,
        preset,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      try {
        await controller.initialize();
        await _cameraController?.dispose();
        _cameraController = controller;
        _resolutionIndex = index;
        _logger.i(
          '✅ Camera initialized with preset: $preset',
          category: LogCategory.camera,
        );
        return;
      } on CameraException catch (error, stackTrace) {
        lastError = error;
        _logger.w(
          '⚠️ Failed to initialize camera with preset $preset',
          category: LogCategory.camera,
          error: error,
          stackTrace: stackTrace,
        );
        await controller.dispose();
      }
    }

    throw lastError ??
        CameraException(
          'CameraInitializationFailed',
          'Unable to initialize camera controller',
        );
  }

  Future<bool> _handleCameraException(CameraException cameraError) async {
    if (_cameraController == null) {
      return false;
    }

    final message = cameraError.description?.toLowerCase() ??
        cameraError.toString().toLowerCase();
    if (message.contains('no supported surface combination')) {
      _logger.w(
        '⚙️ Camera reported unsupported surface combination. Attempting resolution fallback.',
        category: LogCategory.camera,
        error: cameraError,
      );
      return await _attemptResolutionFallback();
    }

    return false;
  }

  Future<bool> _attemptResolutionFallback() async {
    if (_cameras == null || _cameras!.isEmpty) {
      return false;
    }

    if (_resolutionIndex >= _resolutionFallbacks.length - 1) {
      _logger.w(
        '⚠️ No further resolution fallbacks available for camera',
        category: LogCategory.camera,
      );
      return false;
    }

    final nextIndex = _resolutionIndex + 1;
    final nextPreset = _resolutionFallbacks[nextIndex];
    _logger.i(
      '🔄 Reinitializing camera with fallback preset: $nextPreset',
      category: LogCategory.camera,
    );

    try {
      final currentDescription =
          _cameraController?.description ?? _cameras!.first;
      await _initializeCameraController(
        currentDescription,
        startIndex: nextIndex,
      );
      _logger.i(
        '✅ Camera reinitialized with preset: $nextPreset',
        category: LogCategory.camera,
      );
      return true;
    } catch (e, stackTrace) {
      _logger.e(
        '❌ Failed to reinitialize camera with fallback preset: $nextPreset',
        category: LogCategory.camera,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
