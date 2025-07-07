import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../core/services/ar_anchor_manager.dart';
import '../../../core/services/hybrid_localization_engine.dart';
import 'ar_session_state.dart';

/// Cubit for managing AR session state and operations
class ARSessionCubit extends Cubit<ARSessionState> {
  final HybridLocalizationEngine _hybridLocalizationEngine;
  
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  ARSessionCubit({
    required HybridLocalizationEngine hybridLocalizationEngine,
  })  : _hybridLocalizationEngine = hybridLocalizationEngine,
        super(const ARSessionInitial());

  /// Initialize AR session and start AR view
  Future<void> initializeARSession() async {
    if (state is ARSessionInitializing || state is ARSessionReady) {
      _logger.w('⚠️ AR session already initializing or ready');
      return;
    }

    try {
      _logger.i('🥽 Initializing AR session...');
      emit(const ARSessionInitializing());

      // Start AR view using the AR navigation channel
      await const MethodChannel('live_captions_xr/ar_navigation')
          .invokeMethod('showARView');

      _logger.i('✅ AR View launched successfully');

      // Give ARSession a moment to initialize before declaring ready
      _logger.i('⏳ Waiting for ARSession to fully initialize...');
      await Future.delayed(const Duration(milliseconds: 1000));

      emit(const ARSessionReady());
      _logger.i('🎉 AR session initialized and ready');
    } on PlatformException catch (e) {
      _logger.e('❌ AR View platform exception', error: e);

      String errorMessage;
      String? errorCode = e.code;
      
      switch (e.code) {
        case 'UNAVAILABLE':
          errorMessage = 'AR not supported on this device';
          break;
        case 'NOT_AUTHORIZED':
          errorMessage = 'Camera permission required for AR';
          break;
        case 'AR_NOT_SUPPORTED':
          errorMessage = 'ARKit not supported (try on a physical device)';
          break;
        default:
          errorMessage = 'AR View not available: ${e.message}';
      }

      emit(ARSessionError(
        message: errorMessage,
        details: e.toString(),
        errorCode: errorCode,
      ));
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to initialize AR session',
          error: e, stackTrace: stackTrace);

      String errorMessage;
      if (e.toString().contains('MissingPluginException')) {
        errorMessage = 'AR functionality not implemented in current build';
      } else {
        errorMessage = 'Failed to initialize AR session: $e';
      }

      emit(ARSessionError(
        message: errorMessage,
        details: stackTrace.toString(),
      ));
    }
  }

  /// Place an AR anchor automatically using the fused transform
  Future<void> placeAutoAnchor() async {
    final currentState = state;
    if (currentState is! ARSessionReady) {
      _logger.w('⚠️ Cannot place anchor - AR session not ready');
      return;
    }

    if (currentState.anchorPlaced) {
      _logger.i('🎯 AR anchor already placed');
      return;
    }

    const maxRetries = 3;
    const retryDelay = Duration(milliseconds: 500);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        _logger.i('🎯 Auto-placing AR anchor... (attempt $attempt/$maxRetries)');

        final arAnchorManager = ARAnchorManager();

        _logger.i('🔄 Getting fused transform for automatic anchor placement...');
        final fusedTransform = await _hybridLocalizationEngine.getFusedTransform();

        _logger.i('🌍 Creating AR anchor automatically with fused transform...');
        final anchorId = await arAnchorManager
            .createAnchorAtWorldTransform(fusedTransform);

        emit(currentState.copyWith(
          anchorPlaced: true,
          anchorId: anchorId,
        ));

        _logger.i('🎉 AR anchor auto-placed successfully: $anchorId');
        return; // Success, exit retry loop
      } catch (e, stackTrace) {
        _logger.e('❌ Failed to auto-place AR Anchor (attempt $attempt/$maxRetries)',
            error: e, stackTrace: stackTrace);

        if (attempt < maxRetries) {
          _logger.i('⏳ Waiting ${retryDelay.inMilliseconds}ms before retry...');
          await Future.delayed(retryDelay);
        } else {
          _logger.e('❌ All anchor placement attempts failed. AR mode will continue without auto-anchor.');
          // Don't emit error state since AR session can still work without anchor
          // The main AR mode functionality should still work
        }
      }
    }
  }

  /// Start all AR-related services
  Future<void> startAllARServices({
    required Future<void> Function() startLiveCaptions,
    required Future<void> Function() startSoundDetection,
    required Future<void> Function() startLocalization,
    required Future<void> Function() startVisualIdentification,
  }) async {
    final currentState = state;
    if (currentState is! ARSessionReady) {
      _logger.w('⚠️ Cannot start AR services - AR session not ready');
      return;
    }

    try {
      _logger.i('🚀 Starting all services for AR mode...');

      // Start all services in parallel for better performance
      await Future.wait([
        startLiveCaptions(),
        startSoundDetection(),
        startLocalization(),
        startVisualIdentification(),
      ]);

      // Place anchor after services are started
      await placeAutoAnchor();

      _logger.i('🎉 All AR mode services started successfully');
    } catch (e, stackTrace) {
      _logger.e('❌ Error starting AR mode services',
          error: e, stackTrace: stackTrace);
      
      emit(ARSessionError(
        message: 'Failed to start AR services',
        details: e.toString(),
      ));
    }
  }

  /// Stop AR session and clean up
  Future<void> stopARSession() async {
    try {
      _logger.i('🛑 Stopping AR session...');
      emit(const ARSessionStopping());

      // TODO: Add AR session cleanup logic here
      // This would typically involve stopping the AR view and cleaning up resources

      emit(const ARSessionInitial());
      _logger.i('✅ AR session stopped');
    } catch (e, stackTrace) {
      _logger.e('❌ Error stopping AR session',
          error: e, stackTrace: stackTrace);
      
      emit(ARSessionError(
        message: 'Failed to stop AR session',
        details: e.toString(),
      ));
    }
  }

  /// Check if AR session is ready
  bool get isReady => state is ARSessionReady;

  /// Check if AR session has an anchor placed
  bool get hasAnchor {
    final currentState = state;
    return currentState is ARSessionReady && currentState.anchorPlaced;
  }

  /// Get the current anchor ID if available
  String? get anchorId {
    final currentState = state;
    return currentState is ARSessionReady ? currentState.anchorId : null;
  }
}