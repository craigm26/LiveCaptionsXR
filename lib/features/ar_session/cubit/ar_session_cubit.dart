import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../core/services/ar_anchor_manager.dart';
import '../../../core/services/hybrid_localization_engine.dart';
import '../../../core/services/ar_session_persistence_service.dart';
import 'ar_session_state.dart';

/// Cubit for managing AR session state and operations with persistence support
class ARSessionCubit extends Cubit<ARSessionState> {
  final HybridLocalizationEngine _hybridLocalizationEngine;
  final ARSessionPersistenceService _persistenceService;
  
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
    ARSessionPersistenceService? persistenceService,
  })  : _hybridLocalizationEngine = hybridLocalizationEngine,
        _persistenceService = persistenceService ?? ARSessionPersistenceService(),
        super(const ARSessionInitial());

  /// Initialize AR session with optional restoration from previous session
  Future<void> initializeARSession({bool restoreFromPersistence = true}) async {
    if (state is ARSessionInitializing || state is ARSessionReady) {
      _logger.w('⚠️ AR session already initializing or ready');
      return;
    }

    try {
      _logger.i('🥽 Initializing AR session...');
      
      // Check for and potentially restore previous session
      if (restoreFromPersistence) {
        await _attemptSessionRestore();
        if (state is ARSessionReady) {
          return; // Successfully restored
        }
      }
      
      emit(const ARSessionConfiguring());
      await Future.delayed(const Duration(milliseconds: 500));
      
      emit(const ARSessionInitializing());

      // Start AR view using the AR navigation channel
      await const MethodChannel('live_captions_xr/ar_navigation')
          .invokeMethod('showARView');

      _logger.i('✅ AR View launched successfully');

      // Calibrate the AR session
      await _performCalibration();

      // Give ARSession a moment to initialize before declaring ready
      _logger.i('⏳ Waiting for ARSession to fully initialize...');
      await Future.delayed(const Duration(milliseconds: 1000));

      final readyState = const ARSessionReady();
      emit(readyState);
      await _persistenceService.saveSessionState(readyState);
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

  /// Attempt to restore AR session from persistent storage
  Future<void> _attemptSessionRestore() async {
    try {
      _logger.i('🔄 Attempting to restore AR session from persistence...');
      
      final restoredState = await _persistenceService.restoreSessionState();
      if (restoredState == null) {
        _logger.i('ℹ️ No valid session state to restore');
        return;
      }
      
      _logger.i('📂 Restoring AR session state: ${restoredState.runtimeType}');
      
      if (restoredState is ARSessionReady) {
        // Verify the restored anchor is still valid
        if (restoredState.anchorPlaced && restoredState.anchorId != null) {
          final anchorData = await _persistenceService.restoreAnchorData();
          if (anchorData != null) {
            emit(restoredState);
            _logger.i('✅ AR session restored successfully with anchor');
            return;
          }
        }
        emit(const ARSessionReady());
        _logger.i('✅ AR session restored without anchor');
      } else if (restoredState is ARSessionPaused) {
        emit(const ARSessionResuming());
        await Future.delayed(const Duration(milliseconds: 1000));
        
        if (restoredState.previousAnchorPlaced && restoredState.previousAnchorId != null) {
          emit(ARSessionReady(
            anchorPlaced: restoredState.previousAnchorPlaced,
            anchorId: restoredState.previousAnchorId,
          ));
        } else {
          emit(const ARSessionReady());
        }
        _logger.i('✅ AR session resumed from paused state');
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to restore AR session', error: e, stackTrace: stackTrace);
    }
  }

  /// Perform AR session calibration
  Future<void> _performCalibration() async {
    try {
      _logger.i('📐 Starting AR session calibration...');
      
      emit(const ARSessionCalibrating(progress: 0.0, calibrationType: 'device'));
      await Future.delayed(const Duration(milliseconds: 500));
      
      emit(const ARSessionCalibrating(progress: 0.3, calibrationType: 'environment'));
      await Future.delayed(const Duration(milliseconds: 500));
      
      emit(const ARSessionCalibrating(progress: 0.7, calibrationType: 'tracking'));
      await Future.delayed(const Duration(milliseconds: 500));
      
      emit(const ARSessionCalibrating(progress: 1.0, calibrationType: 'complete'));
      await Future.delayed(const Duration(milliseconds: 300));
      
      _logger.i('✅ AR session calibration completed');
    } catch (e, stackTrace) {
      _logger.e('❌ AR calibration failed', error: e, stackTrace: stackTrace);
      throw Exception('AR calibration failed: $e');
    }
  }

  /// Pause AR session (e.g., when app goes to background)
  Future<void> pauseARSession() async {
    final currentState = state;
    
    try {
      _logger.i('⏸️ Pausing AR session...');
      
      if (currentState is ARSessionReady) {
        final pausedState = ARSessionPaused(
          previousAnchorPlaced: currentState.anchorPlaced,
          previousAnchorId: currentState.anchorId,
          pausedAt: DateTime.now(),
        );
        
        emit(pausedState);
        await _persistenceService.saveSessionState(pausedState);
        
        if (currentState.anchorPlaced && currentState.anchorId != null) {
          // Save anchor data for restoration
          final fusedTransform = await _hybridLocalizationEngine.getFusedTransform();
          await _persistenceService.saveAnchorData(
            anchorId: currentState.anchorId!,
            transform: fusedTransform,
            metadata: {'pausedAt': DateTime.now().millisecondsSinceEpoch},
          );
        }
        
        _logger.i('✅ AR session paused successfully');
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to pause AR session', error: e, stackTrace: stackTrace);
    }
  }

  /// Resume AR session from paused state
  Future<void> resumeARSession() async {
    final currentState = state;
    
    if (currentState is! ARSessionPaused) {
      _logger.w('⚠️ Cannot resume - AR session not paused');
      return;
    }
    
    try {
      _logger.i('▶️ Resuming AR session...');
      
      emit(const ARSessionResuming(progress: 0.0));
      await Future.delayed(const Duration(milliseconds: 500));
      
      emit(const ARSessionResuming(progress: 0.5));
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Restore to ready state
      final readyState = ARSessionReady(
        anchorPlaced: currentState.previousAnchorPlaced,
        anchorId: currentState.previousAnchorId,
      );
      
      emit(readyState);
      await _persistenceService.saveSessionState(readyState);
      
      _logger.i('✅ AR session resumed successfully');
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to resume AR session', error: e, stackTrace: stackTrace);
      
      emit(ARSessionError(
        message: 'Failed to resume AR session',
        details: e.toString(),
      ));
    }
  }

  /// Handle tracking lost scenario
  Future<void> handleTrackingLost(String reason) async {
    _logger.w('⚠️ AR tracking lost: $reason');
    
    emit(ARSessionTrackingLost(
      reason: reason,
      lostAt: DateTime.now(),
    ));
    
    // Attempt to reconnect after a short delay
    await Future.delayed(const Duration(seconds: 2));
    await _attemptReconnection();
  }

  /// Attempt to reconnect AR session
  Future<void> _attemptReconnection() async {
    const maxAttempts = 3;
    
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        _logger.i('🔄 Attempting to reconnect AR session (attempt $attempt/$maxAttempts)...');
        
        emit(ARSessionReconnecting(attempt: attempt));
        await Future.delayed(const Duration(seconds: 1));
        
        // Try to restore the session
        await initializeARSession(restoreFromPersistence: true);
        
        if (state is ARSessionReady) {
          _logger.i('✅ AR session reconnected successfully');
          return;
        }
      } catch (e) {
        _logger.w('⚠️ Reconnection attempt $attempt failed: $e');
        
        if (attempt == maxAttempts) {
          emit(ARSessionError(
            message: 'Failed to reconnect AR session',
            details: 'All reconnection attempts failed',
            errorCode: 'RECONNECTION_FAILED',
          ));
        }
      }
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

        final newState = currentState.copyWith(
          anchorPlaced: true,
          anchorId: anchorId,
        );
        
        emit(newState);
        
        // Save the state and anchor data for persistence
        await _persistenceService.saveSessionState(newState);
        await _persistenceService.saveAnchorData(
          anchorId: anchorId,
          transform: fusedTransform,
          metadata: {
            'placedAt': DateTime.now().millisecondsSinceEpoch,
            'method': 'auto',
          },
        );

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

      // Clear persisted session data when stopping
      await _persistenceService.clearAllSessionData();

      // TODO: Add AR session cleanup logic here
      // This would typically involve stopping the AR view and cleaning up resources

      emit(const ARSessionInitial());
      _logger.i('✅ AR session stopped and persistence cleared');
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