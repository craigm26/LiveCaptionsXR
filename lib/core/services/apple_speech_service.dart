import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../models/speech_config.dart';
import '../models/speech_result.dart';
import 'app_logger.dart';

/// Event class for Apple Speech STT progress and status
class AppleSpeechEvent {
  final double progress; // 0.0 to 1.0
  final String message;
  final bool isComplete;
  final Object? error;

  const AppleSpeechEvent({
    required this.progress,
    required this.message,
    this.isComplete = false,
    this.error,
  });
}

/// Service for handling Apple Speech Recognition (iOS native STT)
class AppleSpeechService {
  static final AppLogger _logger = AppLogger.instance;
  
  bool _isInitialized = false;
  bool _isListening = false;
  SpeechConfig _config = const SpeechConfig();
  
  // Track last partial result for error_no_match handling
  String _lastPartialResult = "";
  double _lastPartialConfidence = 0.0;
  
  // Block auto-restart during resource-intensive operations (like Gemma inference)
  bool _blockAutoRestart = false;
  
  // Apple Speech Recognition instance
  final SpeechToText _speechToText = SpeechToText();
  
  final StreamController<SpeechResult> _speechResultController =
      StreamController<SpeechResult>.broadcast();
  
  // STT progress event stream
  final StreamController<AppleSpeechEvent> _sttEventController =
      StreamController<AppleSpeechEvent>.broadcast();
  
  Stream<SpeechResult> get speechResults => _speechResultController.stream;
  Stream<AppleSpeechEvent> get sttEvents => _sttEventController.stream;
  
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  
  /// Block STT auto-restart during resource-intensive operations
  void blockAutoRestart() {
    _blockAutoRestart = true;
    _logger.d('🚫 [APPLE STT] Auto-restart blocked', category: LogCategory.speech);
  }
  
  /// Unblock STT auto-restart and optionally restart immediately
  void unblockAutoRestart({bool restartImmediately = false}) {
    _blockAutoRestart = false;
    _logger.d('✅ [APPLE STT] Auto-restart unblocked', category: LogCategory.speech);
    
    if (restartImmediately && _isInitialized && !_speechToText.isListening) {
      _logger.d('🔄 [APPLE STT] Restarting immediately after unblock', category: LogCategory.speech);
      Future.delayed(Duration(milliseconds: 100), () {
        startProcessing(useOfflineMode: true);
      });
    }
  }
  
  /// Initialize the Apple Speech service with configuration
  Future<bool> initialize({SpeechConfig? config}) async {
    _logger.i('🍎 [DEBUG] AppleSpeechService.initialize() called', category: LogCategory.speech);
    _logger.i('🍎 [DEBUG] _isInitialized: $_isInitialized', category: LogCategory.speech);
    _logger.i('🍎 [DEBUG] kIsWeb: $kIsWeb', category: LogCategory.speech);
    
    if (_isInitialized) {
      _logger.i('🍎 [DEBUG] Already initialized, returning true', category: LogCategory.speech);
      return true;
    }
    
    // Check if we're on web platform
    if (kIsWeb) {
      _logger.w('⚠️ Web platform detected - Apple Speech service not available', category: LogCategory.speech);
      return false;
    }
    
    try {
      _config = config ?? const SpeechConfig();
      _logger.i('🔧 Initializing Apple Speech service...', category: LogCategory.speech);
      
      // Emit STT event for initialization start
      _sttEventController.add(const AppleSpeechEvent(
        progress: 0.0,
        message: 'Initializing Apple Speech service...',
      ));
      
      // Initialize speech to text
      _logger.i('🍎 [DEBUG] About to call _speechToText.initialize()', category: LogCategory.speech);
      bool available = await _speechToText.initialize(
        onError: (error) {
        //  _logger.e('❌ Apple Speech error: ${error.errorMsg}', category: LogCategory.speech);
          
          // Handle error_no_match by using last partial result as final
          if (error.errorMsg == 'error_no_match' && _lastPartialResult.isNotEmpty) {
            _logger.i('🔄 [APPLE STT] error_no_match detected - using last partial result as final: "$_lastPartialResult"', category: LogCategory.speech);
            
            // Send the last partial result as final
            final finalResult = SpeechResult(
              text: _lastPartialResult,
              confidence: _lastPartialConfidence,
              isFinal: true,
              timestamp: DateTime.now(),
            );
            
            _speechResultController.add(finalResult);
            _logger.i('✅ [APPLE STT] Converted partial to final result: "${finalResult.text}"', category: LogCategory.speech);
            
            // Clear the stored partial result
            _lastPartialResult = "";
            _lastPartialConfidence = 0.0;
            
            // Emit success event instead of error
            _sttEventController.add(const AppleSpeechEvent(
              progress: 1.0,
              message: 'Speech recognition complete (recovered from error_no_match)',
              isComplete: true,
            ));
          } else {
            // Log error but DON'T restart in onError (best practice)
            //_logger.w('⚠️ [APPLE STT] Error will be handled by onStatus callback, not restarting here', category: LogCategory.speech);
            _sttEventController.add(AppleSpeechEvent(
              progress: 0.0,
              message: 'Speech recognition error',
              error: error.errorMsg,
            ));
          }
        },
        onStatus: (status) {
          //_logger.d('📋 Apple Speech status: $status', category: LogCategory.speech);
          if (status == SpeechToText.listeningStatus) {
            _isListening = true;
          } else if (status == SpeechToText.doneStatus) {
            _isListening = false;
            // Auto-restart on "done" status (but only if not blocked)
            if (!_blockAutoRestart) {
              //_logger.i('🔄 [APPLE STT] Status "done" detected - auto-restarting listening...', category: LogCategory.speech);
              Future.delayed(Duration(milliseconds: 200), () {
                if (_isInitialized && !_speechToText.isListening && !_blockAutoRestart) {
                  startProcessing(useOfflineMode: true);
                }
              });
            } else {
              _logger.d('⏸️ [APPLE STT] Auto-restart blocked during resource-intensive operation', category: LogCategory.speech);
            }
          } else {
            _isListening = false;
          }
        },
      );
      //_logger.i('🍎 [DEBUG] _speechToText.initialize() returned: $available', category: LogCategory.speech);
      
      if (!available) {
        //_logger.e('❌ Apple Speech not available on this device', category: LogCategory.speech);
        _sttEventController.add(const AppleSpeechEvent(
          progress: 0.0,
          message: 'Speech recognition not available',
          error: 'Service not available on device',
        ));
        return false;
      }
      
      _isInitialized = true;
      //_logger.i('✅ Apple Speech service initialized successfully', category: LogCategory.speech);
      
      // Emit STT event for initialization complete
      _sttEventController.add(const AppleSpeechEvent(
        progress: 1.0,
        message: 'Apple Speech service ready',
        isComplete: true,
      ));
      
      return true;
    } catch (e, stackTrace) {
      //_logger.e('❌ Failed to initialize Apple Speech service', category: LogCategory.speech, error: e, stackTrace: stackTrace);
      
      // Emit STT event for initialization failure
      _sttEventController.add(AppleSpeechEvent(
        progress: 0.0,
        message: 'Failed to initialize Apple Speech service',
        error: e,
      ));
      
      return false;
    }
  }
  
  /// Start processing audio data using continuous listening
  Future<bool> startProcessing({bool useOfflineMode = true}) async {
    //_logger.i('🍎 [DEBUG] AppleSpeechService.startProcessing() called with useOfflineMode: $useOfflineMode', category: LogCategory.speech);
    //_logger.i('🍎 [DEBUG] _isInitialized: $_isInitialized', category: LogCategory.speech);
    //_logger.i('🍎 [DEBUG] _isListening: $_isListening', category: LogCategory.speech);
    
    if (!_isInitialized) {
      _logger.w('⚠️ Apple Speech service not initialized', category: LogCategory.speech);
      return false;
    }
    
    if (_isListening) {
     // _logger.i('🔄 Apple Speech already listening', category: LogCategory.speech);
      return true;
    }
    
    try {
      //_logger.i('🎤 Starting Apple Speech listening (offline: $useOfflineMode)', category: LogCategory.speech);
      
      // Emit STT event for processing start
      _sttEventController.add(const AppleSpeechEvent(
        progress: 0.0,
        message: 'Starting speech recognition...',
      ));
      
      //_logger.i('🍎 [DEBUG] About to call _speechToText.listen()', category: LogCategory.speech);
      await _speechToText.listen(
        onResult: (result) {
          //_logger.i('🎤📝 [APPLE STT] Raw result: "${result.recognizedWords}" (confidence: ${result.confidence}, final: ${result.finalResult}, hasConfidenceRating: ${result.hasConfidenceRating})', category: LogCategory.speech);
          
          // Track partial results for error_no_match handling
          if (!result.finalResult && result.recognizedWords.isNotEmpty) {
            _lastPartialResult = result.recognizedWords;
            _lastPartialConfidence = result.confidence;
            _logger.d('📝 [APPLE STT] Stored partial result: "$_lastPartialResult"', category: LogCategory.speech);
          }
          
          final speechResult = SpeechResult(
            text: result.recognizedWords,
            confidence: result.confidence,
            isFinal: result.finalResult,
            timestamp: DateTime.now(),
          );
          
         // _logger.i('🎤➡️ [APPLE STT] Emitting SpeechResult: text="${speechResult.text}", confidence=${speechResult.confidence}, isFinal=${speechResult.isFinal}', category: LogCategory.speech);
          
          // Emit the result
          _speechResultController.add(speechResult);
          
          if (result.finalResult) {
            _logger.i('✅ [APPLE STT] Final result processed and emitted', category: LogCategory.speech);
            
            // Clear stored partial result since we got a successful final result
            _lastPartialResult = "";
            _lastPartialConfidence = 0.0;
            
            // Emit STT event for processing complete
            _sttEventController.add(const AppleSpeechEvent(
              progress: 1.0,
              message: 'Speech recognition complete',
              isComplete: true,
            ));
            
            // DON'T restart here - let onStatus handle it (best practice)
            _logger.d('🔄 [APPLE STT] Final result processed, restart will be handled by onStatus', category: LogCategory.speech);
          } else {
            _logger.d('⏳ [APPLE STT] Partial result processed and emitted', category: LogCategory.speech);
            // Emit progress event
            _sttEventController.add(const AppleSpeechEvent(
              progress: 0.5,
              message: 'Processing speech...',
            ));
          }
        },
        listenOptions: SpeechListenOptions(
          onDevice: useOfflineMode,        // Key parameter for offline mode
          partialResults: true,            // Enable partial results
          cancelOnError: true,             // Cancel on error
          autoPunctuation: true,           // Auto punctuation
          enableHapticFeedback: false,     // Disable haptic feedback
          listenMode: ListenMode.dictation,      // Dictation mode for better final results
        ),
        localeId: _config.language,
        pauseFor: Duration(seconds: 3),    // Wait 3 seconds of silence before finalizing (best practice)
        listenFor: Duration(seconds: 30),  // Maximum listen duration
      );
      //_logger.i('🍎 [DEBUG] _speechToText.listen() call completed', category: LogCategory.speech);
      
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to start Apple Speech processing', category: LogCategory.speech, error: e, stackTrace: stackTrace);
      
      // Emit STT event for processing start failure
      _sttEventController.add(AppleSpeechEvent(
        progress: 0.0,
        message: 'Failed to start speech recognition',
        error: e,
      ));
      
      return false;
    }
  }
  
  /// Stop processing
  Future<void> stopProcessing() async {
    if (!_isListening) return;
    
    try {
      await _speechToText.stop();
      _isListening = false;
      //_logger.i('🛑 Stopped Apple Speech processing', category: LogCategory.speech);
      
      // Emit STT event for processing stop
      _sttEventController.add(const AppleSpeechEvent(
        progress: 0.0,
        message: 'Speech recognition stopped',
      ));
    } catch (e, stackTrace) {
      _logger.e('❌ Error stopping Apple Speech processing', category: LogCategory.speech, error: e, stackTrace: stackTrace);
    }
  }
  
  /// Update configuration
  Future<void> updateConfig(SpeechConfig config) async {
    _config = config;
    _logger.i('⚙️ Updated Apple Speech configuration', category: LogCategory.speech);
    
    // Reinitialize if already initialized
    if (_isInitialized) {
      await dispose();
      await initialize(config: config);
    }
  }
  
  /// Check if speech recognition is available for a specific locale
  Future<bool> isLocaleAvailable(String localeId) async {
    if (!_isInitialized) return false;
    
    final locales = await _speechToText.locales();
    return locales.any((locale) => locale.localeId == localeId);
  }
  
  /// Get available locales
  Future<List<LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) return [];
    return await _speechToText.locales();
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    try {
      await stopProcessing();
      await _speechResultController.close();
      await _sttEventController.close();
      _isInitialized = false;
      _logger.i('🗑️ Apple Speech service disposed', category: LogCategory.speech);
    } catch (e, stackTrace) {
      _logger.e('❌ Error disposing Apple Speech service', category: LogCategory.speech, error: e, stackTrace: stackTrace);
    }
  }
}