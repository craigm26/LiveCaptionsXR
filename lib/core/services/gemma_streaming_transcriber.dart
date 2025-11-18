import 'dart:async';
import 'dart:typed_data';

import '../models/speech_result.dart';
import 'app_logger.dart';
import 'gemma_3n_service.dart';
import 'spatial_caption_integration_service.dart';

/// Lightweight coordinator that feeds buffered PCM audio into Gemma 3n
/// and emits [SpeechResult] instances that can be consumed by the
/// [EnhancedSpeechProcessor] pipeline.
class GemmaStreamingTranscriber {
  GemmaStreamingTranscriber({
    required Gemma3nService gemmaService,
    required void Function(SpeechResult result) onTranscription,
    SpatialCaptionIntegrationService? spatialService,
    Duration chunkCooldown = const Duration(milliseconds: 350),
    AppLogger? logger,
    int minChunkBytes = 4096,
  })  : _gemmaService = gemmaService,
        _onTranscription = onTranscription,
        _spatialService = spatialService,
        _chunkCooldown = chunkCooldown,
        _minChunkBytes = minChunkBytes,
        _logger = logger ?? AppLogger.instance;

  final Gemma3nService _gemmaService;
  final void Function(SpeechResult result) _onTranscription;
  final SpatialCaptionIntegrationService? _spatialService;
  final Duration _chunkCooldown;
  final int _minChunkBytes;
  final AppLogger _logger;

  StreamSubscription<Uint8List>? _audioSubscription;
  Future<void> _pendingWork = Future.value();
  bool _isRunning = false;
  int _chunkCounter = 0;
  DateTime? _lastChunkAt;

  bool get isRunning => _isRunning;

  /// Start listening to the mono audio stream emitted by [AudioCaptureService].
  Future<void> start(Stream<Uint8List> audioStream) async {
    if (_isRunning) {
      _logger.w(
        '⚠️ [GEMMA-STT] Streaming transcriber already running, ignoring start()',
        category: LogCategory.gemma,
      );
      return;
    }

    _logger.i(
      '▶️ [GEMMA-STT] Listening for PCM chunks to feed into Gemma 3n...',
      category: LogCategory.gemma,
    );

    _audioSubscription = audioStream.listen(
      (chunk) {
        if (chunk.isEmpty) {
          return;
        }
        final now = DateTime.now();
        if (_lastChunkAt != null &&
            now.difference(_lastChunkAt!) < _chunkCooldown) {
          _logger.d(
            '⏳ [GEMMA-STT] Throttling PCM chunk to avoid flooding Gemma (size: ${chunk.length})',
            category: LogCategory.gemma,
          );
          return;
        }
        _lastChunkAt = now;
        _pendingWork = _pendingWork.then((_) => _transcribeChunk(chunk));
      },
      onError: (error, stackTrace) {
        _logger.e(
          '❌ [GEMMA-STT] Audio subscription error',
          category: LogCategory.gemma,
          error: error,
          stackTrace: stackTrace,
        );
      },
    );

    _isRunning = true;
  }

  /// Stop streaming and wait for any in-flight transcription jobs.
  Future<void> stop() async {
    if (!_isRunning) {
      return;
    }
    _logger.i(
      '⏹️ [GEMMA-STT] Stopping Gemma streaming transcriber...',
      category: LogCategory.gemma,
    );
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    await _pendingWork;
    _pendingWork = Future.value();
    _isRunning = false;
    _lastChunkAt = null;
    _logger.i(
      '✅ [GEMMA-STT] Streaming transcriber stopped',
      category: LogCategory.gemma,
    );
  }

  Future<void> _transcribeChunk(Uint8List chunk) async {
    if (chunk.length < _minChunkBytes) {
      _logger.d(
        '🎚️ [GEMMA-STT] Ignoring tiny chunk (${chunk.length} bytes)',
        category: LogCategory.gemma,
      );
      return;
    }
    if (!_gemmaService.isReady) {
      _logger.w(
        '⚠️ [GEMMA-STT] Gemma service not ready while chunk (${chunk.length} bytes) arrived',
        category: LogCategory.gemma,
      );
      return;
    }

    _chunkCounter += 1;
    final stopwatch = Stopwatch()..start();
    _logger.d(
      '🎧 [GEMMA-STT] Processing chunk #$_chunkCounter (${chunk.length} bytes)...',
      category: LogCategory.gemma,
    );

    try {
      final transcript = await _gemmaService.transcribeAudioChunk(
        pcmBytes: chunk,
        sampleRate: 16000,
      );
      stopwatch.stop();

      if (transcript == null || transcript.trim().isEmpty) {
        _logger.w(
          '⚠️ [GEMMA-STT] Chunk #$_chunkCounter produced no transcript',
          category: LogCategory.gemma,
        );
        return;
      }

      final cleaned = transcript.trim();
      final direction = _spatialService?.currentDirection;
      final metadata = <String, dynamic>{
        'source': 'gemma-stt',
        'chunkBytes': chunk.length,
        'latencyMs': stopwatch.elapsedMilliseconds,
      };
      if (direction != null) {
        metadata['direction'] = direction;
      }

      final result = SpeechResult(
        text: cleaned,
        confidence: 0.65,
        isFinal: true,
        timestamp: DateTime.now(),
        speakerDirection: direction,
        metadata: metadata,
      );

      _logger.i(
        '📝 [GEMMA-STT] Chunk #$_chunkCounter => "${cleaned.replaceAll('\n', ' ')}"',
        category: LogCategory.gemma,
      );
      _onTranscription(result);
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logger.e(
        '❌ [GEMMA-STT] Failed to transcribe chunk #$_chunkCounter',
        category: LogCategory.gemma,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
