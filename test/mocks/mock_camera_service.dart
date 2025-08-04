import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:live_captions_xr/core/services/camera_service.dart';

class MockCameraService extends Mock implements CameraService {
  final StreamController<List<int>> _mockFrameStreamController = StreamController<List<int>>.broadcast();
  
  @override
  Future<void> initialize() async {
    // Mock initialization - do nothing
  }
  
  @override
  void startCamera() {
    // Mock start - do nothing
  }
  
  @override
  void stopCamera() {
    // Mock stop - do nothing
  }
  
  @override
  Future<List<int>?> captureFrame() async {
    // Return empty frame for tests
    return [];
  }
  
  @override
  Stream<List<int>> get frameStream => _mockFrameStreamController.stream;
  
  @override
  bool get isReady => true;
  
  @override
  Widget? getCameraPreviewWidget() {
    return null;
  }
  
  @override
  void dispose() {
    _mockFrameStreamController.close();
  }
}