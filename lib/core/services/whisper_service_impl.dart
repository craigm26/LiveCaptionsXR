import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional imports to avoid dart:ffi on web
import 'whisper_service_impl.dart' if (dart.library.html) 'whisper_service_web.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:whisper_ggml/whisper_ggml.dart';
import '../models/speech_config.dart';
import '../models/speech_result.dart';
import 'debug_capturing_logger.dart';

/// Service for handling Whisper GGML speech-to-text processing
class WhisperService {
  static final DebugCapturingLogger _logger = DebugCapturingLogger();
  
  bool _isInitialized = false;
  bool _isProcessing = false;
  SpeechConfig _config = const SpeechConfig();
  
  // Whisper GGML instance
  Whisper? _whisper;
  
  final StreamController<SpeechResult> _speechResultController =
      StreamController<SpeechResult>.broadcast();
  
  Stream<SpeechResult> get speechResults => _speechResultController.stream;
  
  bool get isInitialized => _isInitialized;
  bool get isProcessing => _isProcessing;
  
  /// Initialize the Whisper service with configuration
  Future<bool> initialize({SpeechConfig? config}) async {
    if (_isInitialized) return true;
    
    try {
      _config = config ?? const SpeechConfig();
      _logger.i('🔧 Initializing Whisper service with model: ${_config.whisperModel}');
      
      // Get the documents directory for model storage
      final documentsDir = await getApplicationDocumentsDirectory();
      final modelDir = '${documentsDir.path}/whisper_models';
      
      // Create model directory if it doesn't exist
      final modelDirFile = Directory(modelDir);
      if (!await modelDirFile.exists()) {
        await modelDirFile.create(recursive: true);
      }
      
      // Copy model from assets to documents directory if it doesn't exist
      final modelFileName = 'whisper_${_config.whisperModel}.bin';
      final modelFile = File('$modelDir/$modelFileName');
      
      if (!await modelFile.exists()) {
        _logger.i('📁 Copying model from assets: $modelFileName');
        try {
          // Copy from assets to documents directory
          final assetPath = 'assets/models/$modelFileName';
          final assetFile = File(assetPath);
          
          if (await assetFile.exists()) {
            await assetFile.copy(modelFile.path);
            _logger.i('✅ Model copied from assets to: ${modelFile.path}');
          } else {
            _logger.w('⚠️ Model not found in assets: $assetPath');
            _logger.i('📥 Will attempt to download model automatically');
          }
        } catch (e) {
          _logger.w('⚠️ Could not copy from assets: $e');
          _logger.i('📥 Will attempt to download model automatically');
        }
      }
      
      // Initialize Whisper with the specified model
      _whisper = Whisper(
        model: WhisperModel.values.firstWhere(
          (model) => model.name == _config.whisperModel,
          orElse: () => WhisperModel.base,
        ),
        modelDir: modelDir,
      );
      
      // Test the connection by getting version
      final version = await _whisper!.getVersion();
      _logger.i('📋 Whisper version: $version');
      
      _isInitialized = true;
      _logger.i('✅ Whisper service initialized successfully');
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to initialize Whisper service', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Start processing audio data
  Future<bool> startProcessing() async {
    if (!_isInitialized) {
      _logger.w('⚠️ Whisper service not initialized');
      return false;
    }
    
    if (_isProcessing) {
      _logger.i('🔄 Whisper already processing');
      return true;
    }
    
    try {
      _isProcessing = true;
      _logger.i('🎤 Starting Whisper processing');
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to start Whisper processing', error: e, stackTrace: stackTrace);
      _isProcessing = false;
      return false;
    }
  }
  
  /// Process audio buffer and return transcription
  Future<SpeechResult> processAudioBuffer(Uint8List audioData) async {
    if (!_isInitialized || _whisper == null) {
      _logger.w('⚠️ Whisper not initialized, returning fallback result');
      return SpeechResult(
        text: "Whisper not initialized",
        confidence: 0.0,
        isFinal: true,
        timestamp: DateTime.now(),
      );
    }
    
    try {
      _logger.d('🎵 Processing audio buffer (${audioData.length} bytes)');
      
      // Save audio data to a temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/whisper_audio_${DateTime.now().millisecondsSinceEpoch}.wav');
      await tempFile.writeAsBytes(audioData);
      
      // Create transcription request
      final transcribeRequest = TranscribeRequest(
        audio: tempFile.path,
        language: _config.language,
        isTranslate: _config.whisperTranslateToEnglish,
        isSpecialTokens: _config.whisperSuppressNonSpeechTokens,
        threads: 4, // Use 4 threads for processing
        isVerbose: false,
        isNoTimestamps: true, // We don't need timestamps for real-time
        isRealtime: true, // Enable real-time processing
      );
      
      // Process audio with Whisper GGML
      final response = await _whisper!.transcribe(
        transcribeRequest: transcribeRequest,
        modelPath: tempFile.path, // Use the temp file path
      );
      
      // Clean up temp file
      await tempFile.delete();
      
      final speechResult = SpeechResult(
        text: response.text,
        confidence: 0.8, // Whisper doesn't provide confidence, use default
        isFinal: true,
        timestamp: DateTime.now(),
      );
      
      _logger.d('📝 Whisper result: "${speechResult.text}" (confidence: ${speechResult.confidence})');
      
      // Emit the result
      _speechResultController.add(speechResult);
      
      return speechResult;
    } catch (e, stackTrace) {
      _logger.e('❌ Error processing audio with Whisper', error: e, stackTrace: stackTrace);
      
      final fallbackResult = SpeechResult(
        text: "Error processing audio",
        confidence: 0.0,
        isFinal: true,
        timestamp: DateTime.now(),
      );
      
      _speechResultController.add(fallbackResult);
      return fallbackResult;
    }
  }
  
  /// Update configuration
  Future<void> updateConfig(SpeechConfig config) async {
    _config = config;
    _logger.i('⚙️ Updated Whisper configuration');
    
    // Reinitialize if already initialized
    if (_isInitialized) {
      await dispose();
      await initialize(config: config);
    }
  }
  
  /// Stop processing
  Future<void> stopProcessing() async {
    if (!_isProcessing) return;
    
    try {
      _isProcessing = false;
      _logger.i('🛑 Stopped Whisper processing');
    } catch (e, stackTrace) {
      _logger.e('❌ Error stopping Whisper processing', error: e, stackTrace: stackTrace);
    }
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    try {
      await stopProcessing();
      _whisper = null;
      await _speechResultController.close();
      _isInitialized = false;
      _logger.i('🗑️ Whisper service disposed');
    } catch (e, stackTrace) {
      _logger.e('❌ Error disposing Whisper service', error: e, stackTrace: stackTrace);
    }
  }
} 