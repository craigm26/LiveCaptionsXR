import 'dart:io';
import 'app_logger.dart';
import 'ar_frame_service.dart';
import 'camera_service.dart';
import '../di/service_locator.dart';

/// Unified service for capturing visual frames across platforms
/// - iOS: Uses ARFrameService for ARKit frame capture
/// - Android: Uses CameraService for camera frame capture
class FrameCaptureService {
  final AppLogger _logger = AppLogger.instance;
  
  // Platform-specific services
  ARFrameService? _arFrameService;
  CameraService? _cameraService;
  
  bool _isInitialized = false;

  /// Initialize the appropriate frame capture service based on platform
  Future<bool> initialize() async {
    if (_isInitialized) {
      _logger.w('⚠️ FrameCaptureService already initialized', category: LogCategory.camera);
      return true;
    }

    try {
      if (Platform.isIOS) {
        _logger.i('🍎 Initializing ARFrameService for iOS...', category: LogCategory.ar);
        _arFrameService = ARFrameService();
        _logger.i('✅ ARFrameService initialized successfully', category: LogCategory.ar);
      } else if (Platform.isAndroid) {
        _logger.i('🤖 Initializing CameraService for Android...', category: LogCategory.camera);
        _cameraService = sl<CameraService>();
        await _cameraService!.initialize();
        _logger.i('✅ CameraService initialized successfully', category: LogCategory.camera);
      } else {
        _logger.e('❌ Unsupported platform for frame capture', category: LogCategory.system);
        return false;
      }

      _isInitialized = true;
      _logger.i('✅ FrameCaptureService initialized for ${Platform.operatingSystem}', category: LogCategory.system);
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to initialize FrameCaptureService', 
          category: LogCategory.system, error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Start frame capture (Android only - iOS uses on-demand capture)
  Future<bool> start() async {
    if (!_isInitialized) {
      _logger.e('❌ FrameCaptureService not initialized', category: LogCategory.system);
      return false;
    }

    if (Platform.isAndroid && _cameraService != null) {
      try {
        _logger.d('📱 Starting camera for Android frame capture...', category: LogCategory.camera);
        _cameraService!.startCamera();
        _logger.i('✅ Camera started for frame capture', category: LogCategory.camera);
        return true;
      } catch (e, stackTrace) {
        _logger.e('❌ Failed to start camera for frame capture', 
            category: LogCategory.camera, error: e, stackTrace: stackTrace);
        return false;
      }
    } else if (Platform.isIOS) {
      // iOS doesn't need to "start" - ARKit frames are available on-demand
      _logger.d('🍎 iOS frame capture ready (on-demand ARKit)', category: LogCategory.ar);
      return true;
    }

    return false;
  }

  /// Capture a single frame from the appropriate source
  /// Returns image data as bytes list or null if capture fails
  Future<List<int>?> captureFrame() async {
    if (!_isInitialized) {
      _logger.e('❌ FrameCaptureService not initialized', category: LogCategory.system);
      return null;
    }

    try {
      if (Platform.isIOS && _arFrameService != null) {
        _logger.d('🍎 Capturing ARKit frame via ARFrameService...', category: LogCategory.ar);
        final frameData = await _arFrameService!.captureFrame();
        if (frameData != null) {
          _logger.d('✅ ARKit frame captured: ${frameData.lengthInBytes} bytes', category: LogCategory.ar);
          return frameData;
        } else {
          _logger.w('⚠️ ARKit frame capture returned null', category: LogCategory.ar);
          return null;
        }
      } else if (Platform.isAndroid && _cameraService != null) {
        _logger.d('🤖 Capturing camera frame via CameraService...', category: LogCategory.camera);
        final frameData = await _cameraService!.captureFrame();
        if (frameData != null) {
          _logger.d('✅ Camera frame captured: ${frameData.length} bytes', category: LogCategory.camera);
          return frameData;
        } else {
          _logger.w('⚠️ Camera frame capture returned null', category: LogCategory.camera);
          return null;
        }
      } else {
        _logger.e('❌ No frame capture service available for platform', category: LogCategory.system);
        return null;
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Error during frame capture', 
          category: LogCategory.system, error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Stop frame capture (Android only)
  Future<void> stop() async {
    if (Platform.isAndroid && _cameraService != null) {
      try {
        _logger.d('📱 Stopping camera for Android...', category: LogCategory.camera);
        _cameraService!.stopCamera();
        _logger.i('✅ Camera stopped', category: LogCategory.camera);
      } catch (e, stackTrace) {
        _logger.e('❌ Error stopping camera', 
            category: LogCategory.camera, error: e, stackTrace: stackTrace);
      }
    } else if (Platform.isIOS) {
      // iOS doesn't need explicit stop - ARKit handles lifecycle
      _logger.d('🍎 iOS frame capture stopped (ARKit lifecycle managed)', category: LogCategory.ar);
    }
  }

  /// Dispose resources
  void dispose() {
    _logger.i('🗑️ Disposing FrameCaptureService...', category: LogCategory.system);
    
    if (Platform.isIOS && _arFrameService != null) {
      _arFrameService!.dispose();
      _arFrameService = null;
    } else if (Platform.isAndroid && _cameraService != null) {
      _cameraService!.stopCamera();
      _cameraService = null;
    }

    _isInitialized = false;
    _logger.d('✅ FrameCaptureService disposed successfully', category: LogCategory.system);
  }

  /// Check if service is initialized and ready
  bool get isInitialized => _isInitialized;

  /// Get platform-specific info
  String get platformInfo {
    if (Platform.isIOS) {
      return 'iOS ARKit (on-demand)';
    } else if (Platform.isAndroid) {
      return 'Android Camera';
    } else {
      return 'Unsupported platform';
    }
  }
}