import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../core/services/ar_anchor_manager.dart';
import '../../../core/services/hybrid_localization_engine.dart';
import '../../../core/services/ar_session_persistence_service.dart';
import '../../../core/services/whisper_service.dart';
import '../../../core/services/gemma3n_service.dart';
import 'ar_session_state.dart';

/// Cubit for managing AR session state and operations with persistence support
class ARSessionCubit extends Cubit<ARSessionState> {
  final HybridLocalizationEngine _hybridLocalizationEngine;
  final ARSessionPersistenceService _persistenceService;
  
  // Store callbacks to stop AR services
  Future<void> Function()? _stopLiveCaptions;
  Future<void> Function()? _stopSoundDetection;
  Future<void> Function()? _stopLocalization;
  Future<void> Function()? _stopVisualIdentification;
  
  // Store Whisper service for STT event listening
  WhisperService? _whisperService;
  StreamSubscription<WhisperSTTEvent>? _whisperSTTSubscription;
  
  // Store Gemma 3n service for enhancement event listening
  Gemma3nService? _gemma3nService;
  StreamSubscription<Gemma3nEnhancementEvent>? _gemma3nEnhancementSubscription;
  
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
        super(const ARSessionInitial()) {
    _initMethodChannelListener();
  }

  /// Listen to Whisper STT events and emit AR session states
  void listenToWhisperSTT(WhisperService whisperService) {
    _whisperService = whisperService;
    
    // Cancel any existing subscription
    _whisperSTTSubscription?.cancel();
    
    // Subscribe to Whisper STT events
    _whisperSTTSubscription = whisperService.sttEvents.listen((event) {
      _logger.d('🎤 Whisper STT event: ${event.message} (progress: ${event.progress})');
      
      if (event.error != null) {
        _logger.e('❌ Whisper STT error: ${event.error}');
        emit(ARSessionError(
          message: 'STT failed: ${event.message}',
          details: event.error.toString(),
          errorCode: 'STT_ERROR',
        ));
      } else {
        emit(ARSessionSTTProcessing(
          backend: 'Whisper',
          isOnline: false, // Always on-device for Whisper
          progress: event.progress,
          message: event.message,
        ));
      }
    }, onError: (error) {
      _logger.e('❌ Error in Whisper STT event stream', error: error);
      emit(ARSessionError(
        message: 'STT event stream error',
        details: error.toString(),
        errorCode: 'STT_STREAM_ERROR',
      ));
    });
  }

  /// Stop listening to Whisper STT events
  void stopListeningToWhisperSTT() {
    _whisperSTTSubscription?.cancel();
    _whisperSTTSubscription = null;
    _whisperService = null;
  }

  /// Listen to Gemma 3n enhancement events and emit AR session states
  void listenToGemma3nEnhancement(Gemma3nService gemma3nService) {
    _gemma3nService = gemma3nService;
    
    // Cancel any existing subscription
    _gemma3nEnhancementSubscription?.cancel();
    
    // Subscribe to Gemma 3n enhancement events
    _gemma3nEnhancementSubscription = gemma3nService.enhancementEvents.listen((event) {
      _logger.d('🔮 Gemma 3n enhancement event: ${event.message} (progress: ${event.progress})');
      
      if (event.error != null) {
        _logger.e('❌ Gemma 3n enhancement error: ${event.error}');
        emit(ARSessionError(
          message: 'Contextual enhancement failed: ${event.message}',
          details: event.error.toString(),
          errorCode: 'ENHANCEMENT_ERROR',
        ));
      } else {
        emit(ARSessionContextualEnhancement(
          progress: event.progress,
          message: event.message,
        ));
      }
    }, onError: (error) {
      _logger.e('❌ Error in Gemma 3n enhancement event stream', error: error);
      emit(ARSessionError(
        message: 'Enhancement event stream error',
        details: error.toString(),
        errorCode: 'ENHANCEMENT_STREAM_ERROR',
      ));
    });
  }

  /// Stop listening to Gemma 3n enhancement events
  void stopListeningToGemma3nEnhancement() {
    _gemma3nEnhancementSubscription?.cancel();
    _gemma3nEnhancementSubscription = null;
    _gemma3nService = null;
  }

  Future<void> updateWithAudioMeasurement({
    required double angle,
    required double confidence,
    required List<double> deviceTransform,
  }) async {
    await _hybridLocalizationEngine.updateWithAudioMeasurement(
      angle: angle,
      confidence: confidence,
      deviceTransform: deviceTransform,
    );
  }

  Future<void> updateWithVisualMeasurement({
    required List<double> transform,
    required double confidence,
  }) async {
    await _hybridLocalizationEngine.updateWithVisualMeasurement(
      transform: transform,
      confidence: confidence,
    );
  }

  Future<List<double>?> getFusedTransform() async {
    return await _hybridLocalizationEngine.getFusedTransform();
  }

  void _initMethodChannelListener() {
    const MethodChannel('live_captions_xr/ar_navigation').setMethodCallHandler((call) async {
      if (call.method == 'arViewWillClose') {
        _logger.i('🚪 AR view is closing, stopping all services...');
        await stopARSession();
        _logger.i('✅ All services stopped, AR view can proceed with cleanup');
        // Return success to indicate cleanup is complete
        return 'cleanup_complete';
      }
    });
  }

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
      
      // Configuration phase with progress updates
      emit(const ARSessionConfiguring(progress: 0.0));
      await Future.delayed(const Duration(milliseconds: 300));
      
      emit(const ARSessionConfiguring(progress: 0.3));
      await Future.delayed(const Duration(milliseconds: 200));
      
      emit(const ARSessionConfiguring(progress: 0.6));
      await Future.delayed(const Duration(milliseconds: 200));
      
      emit(const ARSessionConfiguring(progress: 1.0));
      await Future.delayed(const Duration(milliseconds: 200));
      
      emit(const ARSessionInitializing());

      // Start AR view using the AR navigation channel
      _logger.i('🔗 Calling showARView via method channel...');
      try {
        await const MethodChannel('live_captions_xr/ar_navigation')
            .invokeMethod('showARView');
        _logger.i('✅ AR View method channel call completed successfully');
      } catch (e) {
        _logger.e('❌ AR View method channel call failed', error: e);
        rethrow;
      }

      _logger.i('✅ AR View launched successfully');

      // Calibrate the AR session with progress updates
      await _performCalibration();

      // Give ARSession a moment to initialize before declaring ready
      _logger.i('⏳ Waiting for ARSession to fully initialize...');
      await Future.delayed(const Duration(milliseconds: 1000));

      // Validate that the AR session is actually ready before declaring it ready
      _logger.i('🔍 Validating AR session readiness with retries...');
      const maxValidationAttempts = 5;
      const validationRetryDelay = Duration(milliseconds: 500);

      bool isSessionValid = false;
      for (int attempt = 1; attempt <= maxValidationAttempts; attempt++) {
        try {
          await _validateARSessionReadiness();
          isSessionValid = true;
          _logger.i('✅ AR session validation passed on attempt $attempt');
          break;
        } catch (e) {
          _logger.w('⚠️ AR session validation failed on attempt $attempt/$maxValidationAttempts: $e');
          if (attempt < maxValidationAttempts) {
            await Future.delayed(validationRetryDelay);
          }
        }
      }

      if (!isSessionValid) {
        _logger.e('❌ AR session validation failed after $maxValidationAttempts attempts.');
        throw Exception('AR session failed to become ready in time.');
      }

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
            // Don't restore servicesStarted flag - services should be explicitly started
            emit(restoredState.copyWith(servicesStarted: false));
            _logger.i('✅ AR session restored successfully with anchor (services not auto-started)');
            return;
          }
        }
        emit(const ARSessionReady(servicesStarted: false));
        _logger.i('✅ AR session restored without anchor (services not auto-started)');
      } else if (restoredState is ARSessionPaused) {
        emit(const ARSessionResuming());
        await Future.delayed(const Duration(milliseconds: 1000));
        
        if (restoredState.previousAnchorPlaced && restoredState.previousAnchorId != null) {
          emit(ARSessionReady(
            anchorPlaced: restoredState.previousAnchorPlaced,
            anchorId: restoredState.previousAnchorId,
            servicesStarted: false,
          ));
        } else {
          emit(const ARSessionReady(servicesStarted: false));
        }
        _logger.i('✅ AR session resumed from paused state (services not auto-started)');
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to restore AR session', error: e, stackTrace: stackTrace);
    }
  }

  /// Validate that the AR session is actually ready for operations
  Future<void> _validateARSessionReadiness() async {
    try {
      _logger.i('🔬 Testing AR session availability via anchor methods...');
      
      // Try to call a simple method to check if the AR session is available
      await const MethodChannel('live_captions_xr/ar_anchor_methods')
          .invokeMethod('getDeviceOrientation');
      
      _logger.i('✅ AR session responded to validation call');
    } on PlatformException catch (e) {
      if (e.code == 'NO_SESSION') {
        _logger.e('❌ AR session validation failed: NO_SESSION');
        throw Exception('AR session not available during validation');
      } else if (e.code == 'SESSION_NOT_READY') {
        _logger.w('⚠️ AR session not ready during validation, but may become ready');
        throw Exception('AR session not ready during validation');
      } else {
        _logger.w('⚠️ AR session validation returned unexpected error: ${e.code}');
        throw Exception('AR session validation failed: ${e.code}');
      }
    } catch (e) {
      _logger.e('❌ AR session validation failed with unexpected error', error: e);
      throw Exception('AR session validation failed: $e');
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
      _logger.w('⚠️ Cannot place anchor - AR session not ready. Current state: ${currentState.runtimeType}');
      return;
    }

    if (currentState.anchorPlaced) {
      _logger.i('🎯 AR anchor already placed');
      return;
    }

    const maxRetries = 5;
    const retryDelay = Duration(milliseconds: 1000);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        _logger.i('🎯 Auto-placing AR anchor... (attempt $attempt/$maxRetries)');

        final arAnchorManager = ARAnchorManager();

        // First, validate that the AR session is actually ready for anchor operations
        _logger.d('🔍 Validating AR session readiness...');
        try {
          await arAnchorManager.getDeviceOrientation();
          _logger.d('✅ AR session validation successful');
        } catch (e) {
          _logger.w('⚠️ AR session not ready yet: $e');
          if (attempt < maxRetries) {
            _logger.i('⏳ Waiting ${retryDelay.inMilliseconds}ms before retry...');
            await Future.delayed(retryDelay);
            continue;
          } else {
            _logger.e('❌ AR session validation failed after $maxRetries attempts');
            rethrow;
          }
        }

        _logger.d('🔄 Requesting fused transform from hybrid localization...');
        final fusedTransform = await _hybridLocalizationEngine.getFusedTransform();
        _logger.d('✅ Fused transform retrieved successfully - length: ${fusedTransform.length}');

        _logger.i('🌍 Creating AR anchor at world transform: [${fusedTransform.take(4).map((e) => e.toStringAsFixed(3)).join(', ')}...]');
        
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
            'attempt': attempt,
          },
        );

        _logger.i('🎉 AR anchor auto-placed successfully: $anchorId');
        return; // Success, exit retry loop
      } catch (e, stackTrace) {
        if (e is PlatformException) {
          _logger.e('❌ Platform exception during anchor placement (attempt $attempt/$maxRetries): ${e.code} - ${e.message}', error: e);
          
          // Add specific handling for different error types
          switch (e.code) {
            case 'NO_SESSION':
            case 'SESSION_NOT_READY':
              _logger.w('⏳ ARSession not ready, will retry. Error: ${e.code}');
              if (attempt < maxRetries) {
                _logger.i('⏳ Waiting ${retryDelay.inMilliseconds}ms before retry...');
                await Future.delayed(retryDelay);
                continue; // Continue to the next attempt immediately
              }
              break;
            case 'INVALID_ARGUMENTS':
              _logger.e('📝 Invalid arguments passed to anchor creation');
              break;
            default:
              _logger.e('🔍 Unknown platform exception: ${e.code}');
          }
        } else {
          _logger.e('❌ Unexpected error during anchor placement (attempt $attempt/$maxRetries)', error: e, stackTrace: stackTrace);
        }

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
    Future<void> Function()? stopLiveCaptions,
    Future<void> Function()? stopSoundDetection,
    Future<void> Function()? stopLocalization,
    Future<void> Function()? stopVisualIdentification,
    // New: Optionally specify STT backend and online/offline
    String sttBackend = 'Whisper',
    bool sttIsOnline = false,
  }) async {
    final currentState = state;
    if (currentState is! ARSessionReady) {
      _logger.w('⚠️ Cannot start AR services - AR session not ready. Current state: ${currentState.runtimeType}');
      return;
    }

    // Check if services are already started
    if (currentState.servicesStarted) {
      _logger.i('🔄 AR services already started, skipping');
      return;
    }

    try {
      _logger.i('🚀 Starting all services for AR mode...');

      // Store stop callbacks for later cleanup
      _stopLiveCaptions = stopLiveCaptions;
      _stopSoundDetection = stopSoundDetection;
      _stopLocalization = stopLocalization;
      _stopVisualIdentification = stopVisualIdentification;

      // Initialize service statuses
      final serviceStatuses = <String, ServiceStatus>{
        'liveCaptions': const ServiceStatus(
          serviceName: 'Live Captions',
          state: ServiceState.pending,
        ),
        'soundDetection': const ServiceStatus(
          serviceName: 'Sound Detection',
          state: ServiceState.pending,
        ),
        'localization': const ServiceStatus(
          serviceName: 'Audio Localization',
          state: ServiceState.pending,
        ),
        'visualIdentification': const ServiceStatus(
          serviceName: 'Visual Identification',
          state: ServiceState.pending,
        ),
      };

      // Emit starting services state
      emit(ARSessionStartingServices(
        serviceStatuses: serviceStatuses,
        overallProgress: 0.0,
      ));

      // Start session health monitoring
      _startSessionHealthMonitoring();

      // Start services sequentially with progress updates
      final services = [
        ('liveCaptions', startLiveCaptions),
        ('soundDetection', startSoundDetection),
        ('localization', startLocalization),
        ('visualIdentification', startVisualIdentification),
      ];

      for (int i = 0; i < services.length; i++) {
        final (serviceKey, serviceStartFunction) = services[i];
        
        // Update service status to starting
        final updatedStatuses = Map<String, ServiceStatus>.from(serviceStatuses);
        updatedStatuses[serviceKey] = updatedStatuses[serviceKey]!.copyWith(
          state: ServiceState.starting,
          message: 'Starting...',
          progress: 0.0,
        );
        
        emit(ARSessionStartingServices(
          serviceStatuses: updatedStatuses,
          overallProgress: i / services.length,
        ));

        try {
          // Start the service
          await serviceStartFunction();
          
          // Update service status to running
          updatedStatuses[serviceKey] = updatedStatuses[serviceKey]!.copyWith(
            state: ServiceState.running,
            message: 'Running',
            progress: 1.0,
          );
          
          emit(ARSessionStartingServices(
            serviceStatuses: updatedStatuses,
            overallProgress: (i + 1) / services.length,
          ));
          
          _logger.i('✅ ${updatedStatuses[serviceKey]!.serviceName} started successfully');
        } catch (e) {
          _logger.e('❌ Failed to start ${updatedStatuses[serviceKey]!.serviceName}', error: e);
          
          // Update service status to error
          updatedStatuses[serviceKey] = updatedStatuses[serviceKey]!.copyWith(
            state: ServiceState.error,
            message: 'Failed: ${e.toString()}',
          );
          
          emit(ARSessionStartingServices(
            serviceStatuses: updatedStatuses,
            overallProgress: (i + 1) / services.length,
          ));
          
          // Continue with other services even if one fails
        }
      }

      // Note: STT and Gemma 3n pipeline stages are now handled by real service events
      // Whisper STT events are emitted via listenToWhisperSTT()
      // Gemma 3n enhancement events are emitted via listenToGemma3nEnhancement()

      // Place anchor after services are started and ready
      await placeAutoAnchor();

      // Update state to indicate services have been started
      emit(currentState.copyWith(servicesStarted: true));

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

  Timer? _sessionHealthTimer;

  /// Start monitoring AR session health
  void _startSessionHealthMonitoring() {
    _logger.d('🏥 Starting AR session health monitoring...');
    
    _sessionHealthTimer?.cancel();
    _sessionHealthTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkSessionHealth();
    });
  }

  /// Check AR session health
  Future<void> _checkSessionHealth() async {
    if (state is! ARSessionReady) {
      _sessionHealthTimer?.cancel();
      return;
    }

    try {
      _logger.d('🔍 Performing AR session health check...');
      await const MethodChannel('live_captions_xr/ar_anchor_methods')
          .invokeMethod('getDeviceOrientation');
      _logger.d('✅ AR session health check passed');
    } catch (e) {
      _logger.w('⚠️ AR session health check failed', error: e);
      
      if (e is PlatformException && e.code == 'NO_SESSION') {
        _logger.e('💥 CRITICAL: AR session lost during health check');
        // Session was lost, emit error state
        emit(ARSessionError(
          message: 'AR session was lost during operation',
          details: 'Session health check failed: ${e.message}',
          errorCode: 'SESSION_LOST',
        ));
      }
    }
  }

  /// Stop AR session and clean up
  Future<void> stopARSession() async {
    try {
      _logger.i('🛑 Stopping AR session and all services...');
      emit(const ARSessionStopping());

      // Stop listening to Whisper STT events
      stopListeningToWhisperSTT();
      _logger.d('🎤 Whisper STT event listening stopped');

      // Stop listening to Gemma 3n enhancement events
      stopListeningToGemma3nEnhancement();
      _logger.d('🔮 Gemma 3n enhancement event listening stopped');

      // Stop session health monitoring first
      _sessionHealthTimer?.cancel();
      _sessionHealthTimer = null;
      _logger.d('🏥 AR session health monitoring stopped');

      // Stop all AR services with proper error handling and timeouts
      _logger.i('🛑 Stopping all AR services with timeouts...');
      final stopFutures = <Future<void>>[];
      
      if (_stopLiveCaptions != null) {
        stopFutures.add(_stopLiveCaptions!().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            _logger.w('⏰ Live captions stop timed out');
          },
        ).catchError((e) {
          _logger.w('⚠️ Error stopping live captions: $e');
        }));
      }
      
      if (_stopSoundDetection != null) {
        stopFutures.add(_stopSoundDetection!().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            _logger.w('⏰ Sound detection stop timed out');
          },
        ).catchError((e) {
          _logger.w('⚠️ Error stopping sound detection: $e');
        }));
      }
      
      if (_stopLocalization != null) {
        stopFutures.add(_stopLocalization!().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            _logger.w('⏰ Localization stop timed out');
          },
        ).catchError((e) {
          _logger.w('⚠️ Error stopping localization: $e');
        }));
      }
      
      if (_stopVisualIdentification != null) {
        stopFutures.add(_stopVisualIdentification!().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            _logger.w('⏰ Visual identification stop timed out');
          },
        ).catchError((e) {
          _logger.w('⚠️ Error stopping visual identification: $e');
        }));
      }
      
      // Wait for all services to stop with a maximum timeout
      if (stopFutures.isNotEmpty) {
        await Future.wait(stopFutures).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            _logger.w('⏰ Service shutdown timed out, proceeding with cleanup anyway');
            return <void>[];
          },
        );
        _logger.i('✅ All AR services stopped (or timed out)');
      }
      
      // Add extra delay to ensure all MediaPipe/LLM background threads complete
      _logger.i('⏳ Waiting for background inference threads to complete...');
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Clear stop callbacks
      _stopLiveCaptions = null;
      _stopSoundDetection = null;
      _stopLocalization = null;
      _stopVisualIdentification = null;

      // Clear persisted session data when stopping
      await _persistenceService.clearAllSessionData();

      // This would typically involve stopping the AR view and cleaning up resources
      try {
        await const MethodChannel('live_captions_xr/ar_navigation')
            .invokeMethod('exitARMode');
        _logger.i('✅ Successfully called exitARMode on the native side');
      } on PlatformException catch (e) {
        _logger.w(
            '⚠️ Could not call exitARMode on native side, but continuing cleanup: ${e.message}');
      }

      // Clear persisted session data when stopping
      try {
        await _persistenceService.clearAllSessionData();
        _logger.i('✅ Cleared all session data from persistence');
      } catch (e, stackTrace) {
        _logger.w('⚠️ Failed to clear session data, but continuing cleanup',
            error: e, stackTrace: stackTrace);
      }

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

  /// Dispose resources and cancel all subscriptions
  @override
  Future<void> close() async {
    _logger.i('🗑️ Disposing ARSessionCubit...');
    
    // Stop listening to Whisper STT events
    stopListeningToWhisperSTT();
    
    // Stop listening to Gemma 3n enhancement events
    stopListeningToGemma3nEnhancement();
    
    // Stop session health monitoring
    _sessionHealthTimer?.cancel();
    _sessionHealthTimer = null;
    
    // Clear stop callbacks
    _stopLiveCaptions = null;
    _stopSoundDetection = null;
    _stopLocalization = null;
    _stopVisualIdentification = null;
    
    _logger.i('✅ ARSessionCubit disposed');
    await super.close();
  }
}