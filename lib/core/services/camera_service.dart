import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'app_logger.dart';

class CameraService {
  static final AppLogger _logger = AppLogger.instance;

  bool _isCameraStarted = false;
  bool _isInitialized = false;
  Completer<void>? _initializeCompleter;

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  bool _isProcessingFrame = false;
  final List<Future<void> Function(CameraImage)> _onFrameListeners = [];

  static const List<ResolutionPreset> _resolutionFallbacks = <ResolutionPreset>[
    ResolutionPreset.medium,
    ResolutionPreset.low,
  ];
  int _resolutionIndex = 0;

  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_initializeCompleter != null) return _initializeCompleter!.future;

    _initializeCompleter = Completer<void>();
    _logger.i('🏗️ Initializing CameraService...',
        category: LogCategory.camera);

    try {
      final usable = await _canUsePhysicalCamera();
      if (!usable) {
        _logger.i('ℹ️ CameraService skipped on this platform/emulator',
            category: LogCategory.camera);
        _isInitialized = false;
        _initializeCompleter!.complete();
        return;
      }

      await _ensureCameraPermission();
      _cameras = await availableCameras();
      final frontCamera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );
      await _initializeCameraController(frontCamera);
      _isInitialized = true;
      _logger.i('✅ CameraService initialized successfully',
          category: LogCategory.camera);
      _initializeCompleter!.complete();
    } catch (e, stackTrace) {
      _logger.e('❌ Camera initialization failed',
          category: LogCategory.camera, error: e, stackTrace: stackTrace);
      _initializeCompleter!.completeError(e, stackTrace);
      rethrow;
    } finally {
      _initializeCompleter = null;
    }
  }

  void startCamera() {
    _logger.i('📸 Starting camera...', category: LogCategory.camera);
    if (!_isInitialized) {
      throw StateError(
          'Camera service not initialized. Call initialize() first.');
    }
    if (_isCameraStarted) {
      _logger.w('⚠️ Camera already started, skipping start',
          category: LogCategory.camera);
      return;
    }

    try {
      _cameraController?.startImageStream(_onFrameReceived);
      _isCameraStarted = true;
      _logger.i('✅ Camera started successfully', category: LogCategory.camera);
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to start camera stream',
          category: LogCategory.camera, error: e, stackTrace: stackTrace);
    }
  }

  void stopCamera() {
    _logger.i('📸 Stopping camera...', category: LogCategory.camera);
    if (!_isCameraStarted) {
      _logger.w('⚠️ Camera not started, nothing to stop',
          category: LogCategory.camera);
      return;
    }

    try {
      _cameraController?.stopImageStream();
      _isCameraStarted = false;
      _logger.i('✅ Camera stopped successfully', category: LogCategory.camera);
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to stop camera stream',
          category: LogCategory.camera, error: e, stackTrace: stackTrace);
    }
  }

  void addOnFrameListener(Future<void> Function(CameraImage) listener) {
    _onFrameListeners.add(listener);
  }

  void removeOnFrameListener(Future<void> Function(CameraImage) listener) {
    _onFrameListeners.remove(listener);
  }

  Future<void> _onFrameReceived(CameraImage image) async {
    if (_isProcessingFrame) return;

    _isProcessingFrame = true;
    try {
      final listeners = List.of(_onFrameListeners);
      for (final listener in listeners) {
        try {
          await listener(image);
        } catch (e, stackTrace) {
          _logger.e('❌ Error in onFrame listener',
              category: LogCategory.camera, error: e, stackTrace: stackTrace);
        }
      }
    } finally {
      _isProcessingFrame = false;
    }
  }

  Widget? getCameraPreviewWidget() {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      return CameraPreview(_cameraController!);
    }
    return null;
  }

  void dispose() {
    _logger.i('🧹 Disposing CameraService...', category: LogCategory.camera);
    stopCamera();
    _cameraController?.dispose();
    _onFrameListeners.clear();
    _isInitialized = false;
    _logger.i('✅ CameraService disposed successfully',
        category: LogCategory.camera);
  }

  Future<bool> _canUsePhysicalCamera() async {
    if (kIsWeb) return false;
    if (!(defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS)) {
      return false;
    }
    if (await _isEmulator()) {
      _logger.w(
        '⚠️ Emulator detected; skipping physical camera initialization.',
        category: LogCategory.camera,
      );
      return false;
    }
    return true;
  }

  Future<bool> _isEmulator() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        final fingerprint = info.fingerprint?.toLowerCase() ?? '';
        final brand = info.brand?.toLowerCase() ?? '';
        final model = info.model?.toLowerCase() ?? '';
        final product = info.product?.toLowerCase() ?? '';
        final isGeneric =
            fingerprint.contains('generic') || product.contains('sdk');
        final isEmuBrand =
            brand.contains('generic') || model.contains('emulator');
        return !(info.isPhysicalDevice ?? true) || isGeneric || isEmuBrand;
      } else {
        final info = await deviceInfo.iosInfo;
        return !(info.isPhysicalDevice ?? true);
      }
    } catch (e) {
      _logger.w(
        '⚠️ Failed to determine emulator status, assuming physical device.',
        category: LogCategory.system,
        error: e,
      );
      return false;
    }
  }

  Future<void> _ensureCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    if (!status.isGranted) {
      _logger.e('⚠️ Camera permission denied.', category: LogCategory.camera);
      throw CameraException('CameraAccessDenied', 'Camera access was denied.');
    }
  }

  Future<void> _initializeCameraController(
    CameraDescription cameraDescription, {
    int startIndex = 0,
  }) async {
    CameraException? lastError;
    for (var i = startIndex; i < _resolutionFallbacks.length; i++) {
      final preset = _resolutionFallbacks[i];
      _logger.d('Attempting to initialize camera with $preset',
          category: LogCategory.camera);
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
        _resolutionIndex = i;
        _logger.i('✅ Camera initialized with preset: $preset',
            category: LogCategory.camera);
        return;
      } on CameraException catch (e) {
        lastError = e;
        _logger.w('⚠️ Failed to initialize with $preset: ${e.description}',
            category: LogCategory.camera);
        await controller.dispose();
      }
    }
    throw lastError ??
        CameraException(
            'CameraInitializationFailed', 'Could not initialize camera.');
  }
}
