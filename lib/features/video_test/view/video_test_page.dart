import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../live_captions/cubit/live_captions_cubit.dart';
import '../../live_captions/cubit/live_captions_state.dart';
import '../../live_captions/widgets/live_captions_widget.dart';
import '../../sound_detection/cubit/sound_detection_cubit.dart';
import '../../translation/cubit/translation_cubit.dart';
import '../../translation/cubit/translation_state.dart';
import '../../../core/services/app_logger.dart';

class VideoTestPage extends StatefulWidget {
  const VideoTestPage({super.key});

  static const String defaultVideoUrl = 'https://youtu.be/5lwfZzMkkR8';

  @override
  State<VideoTestPage> createState() => _VideoTestPageState();
}

class _VideoTestPageState extends State<VideoTestPage> {
  final AppLogger _logger = AppLogger.instance;
  final TextEditingController _urlController = TextEditingController();
  YoutubePlayerController? _ytController;
  bool _isRunning = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _urlController.text = VideoTestPage.defaultVideoUrl;
    // Auto-load and start on page open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndStart();
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _ytController?.close();
    super.dispose();
  }

  /// Extract YouTube video ID from various URL formats.
  String? _extractVideoId(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;

    // Direct video ID (11 chars, alphanumeric + _ -)
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(trimmed)) {
      return trimmed;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;

    // youtube.com/watch?v=VIDEO_ID
    if ((uri.host.contains('youtube.com') ||
            uri.host.contains('youtube-nocookie.com')) &&
        uri.queryParameters.containsKey('v')) {
      return uri.queryParameters['v'];
    }

    // youtu.be/VIDEO_ID
    if (uri.host == 'youtu.be' && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.first;
    }

    // youtube.com/embed/VIDEO_ID or youtube.com/shorts/VIDEO_ID
    if (uri.host.contains('youtube.com') && uri.pathSegments.length >= 2) {
      final type = uri.pathSegments[0];
      if (type == 'embed' || type == 'shorts' || type == 'v') {
        return uri.pathSegments[1];
      }
    }

    return null;
  }

  void _loadAndStart() {
    final videoId = _extractVideoId(_urlController.text);
    if (videoId == null) {
      setState(() {
        _errorMessage =
            'Invalid YouTube URL. Try a link like youtube.com/watch?v=...';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    _logger.i('Loading YouTube video: $videoId', category: LogCategory.ui);

    // Close previous controller if any
    _ytController?.close();

    // On mobile, use a desktop user agent so YouTube serves the full embed player
    // instead of a restricted WebView page that often fails to load.
    final controller = YoutubePlayerController(
      params: YoutubePlayerParams(
        showFullscreenButton: false,
        mute: false,
        showControls: true,
        enableCaption: false,
        origin: 'https://www.youtube-nocookie.com',
      ),
      onWebResourceError: (error) {
        _logger.e('WebView error: ${error.errorType} — ${error.description}',
            category: LogCategory.ui);
        if (mounted) {
          setState(() {
            _errorMessage = 'WebView error: ${error.description}';
          });
        }
      },
    );
    // Listen to player state: clear error when playback succeeds
    controller.listen((YoutubePlayerValue value) {
      if (!mounted) return;
      if (value.hasError) {
        setState(() {
          _errorMessage = 'Playback error: ${value.error.name}';
        });
      } else if (value.playerState == PlayerState.playing ||
          value.playerState == PlayerState.cued ||
          value.playerState == PlayerState.buffering) {
        setState(() => _errorMessage = null);
      }
    });
    // Load the video (will wait for WebView init before executing)
    controller.loadVideoById(videoId: videoId);

    setState(() {
      _ytController = controller;
      _isRunning = true;
    });

    // Start caption pipeline
    final liveCaptionsCubit = context.read<LiveCaptionsCubit>();
    liveCaptionsCubit.startCaptions();

    // Start sound detection
    final soundCubit = context.read<SoundDetectionCubit>();
    if (!soundCubit.isActive) {
      soundCubit.start();
    }

    // Enable translation with auto-detection for multilingual content
    _enableTranslation();

    _logger.i('Video test started with captions and translation',
        category: LogCategory.ui);
  }

  void _enableTranslation() {
    try {
      final translationCubit = context.read<TranslationCubit>();
      final state = translationCubit.state;
      if (state is TranslationReady && !state.isEnabled) {
        translationCubit.toggleEnabled();
        _logger.i('Translation auto-enabled for video test',
            category: LogCategory.ui);
      }
    } catch (_) {
      // TranslationCubit not in widget tree — skip
      _logger.d('TranslationCubit not available, skipping auto-enable',
          category: LogCategory.ui);
    }
  }

  void _stop() {
    _logger.i('Stopping video test', category: LogCategory.ui);

    _ytController?.pauseVideo();

    final liveCaptionsCubit = context.read<LiveCaptionsCubit>();
    liveCaptionsCubit.stopCaptions();

    final soundCubit = context.read<SoundDetectionCubit>();
    if (soundCubit.isActive) {
      soundCubit.stop();
    }

    setState(() {
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // URL input bar
          _buildUrlBar(),
          // Video + overlays
          Expanded(child: _buildVideoArea()),
          // Bottom status bar
          _buildStatusBar(),
        ],
      ),
    );
  }

  Widget _buildUrlBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.grey[900],
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _urlController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Paste YouTube URL...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.link, color: Colors.grey[500], size: 20),
                errorText: _errorMessage,
                errorStyle: const TextStyle(fontSize: 11),
              ),
              onSubmitted: (_) {
                if (!_isRunning) _loadAndStart();
              },
            ),
          ),
          const SizedBox(width: 8),
          _isRunning
              ? ElevatedButton.icon(
                  onPressed: _stop,
                  icon: const Icon(Icons.stop, size: 18),
                  label: const Text('Stop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: _loadAndStart,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Load & Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildVideoArea() {
    return Stack(
      children: [
        // Video player
        Positioned.fill(
          child: _ytController != null
              ? YoutubePlayer(controller: _ytController!)
              : Container(
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white54),
                  ),
                ),
        ),
        // Caption overlay (bottom center)
        if (_isRunning)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Center(
              child: LiveCaptionsWidget(
                onToggle: () {
                  final cubit = context.read<LiveCaptionsCubit>();
                  final state = cubit.state;
                  if (state is LiveCaptionsActive && state.isListening) {
                    cubit.stopCaptions();
                  } else {
                    cubit.startCaptions();
                  }
                },
                onClear: () =>
                    context.read<LiveCaptionsCubit>().clearCaptions(),
                maxWidth: 500,
                showHistory: false,
              ),
            ),
          ),
        // Translation indicator (top left)
        if (_isRunning)
          Positioned(
            top: 12,
            left: 12,
            child: _buildTranslationIndicator(),
          ),
        // Sound detection indicator (top right)
        if (_isRunning)
          Positioned(
            top: 12,
            right: 12,
            child: _buildSoundIndicator(),
          ),
        // WebView error overlay
        if (_errorMessage != null && _isRunning)
          Positioned(
            left: 16,
            right: 16,
            top: 48,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha((255 * 0.85).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTranslationIndicator() {
    try {
      return BlocBuilder<TranslationCubit, TranslationState>(
        builder: (context, state) {
          if (state is! TranslationReady) return const SizedBox.shrink();
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha((255 * 0.7).round()),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: state.isEnabled ? Colors.lightBlueAccent : Colors.grey,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.translate,
                  size: 16,
                  color: state.isEnabled ? Colors.lightBlueAccent : Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  state.isEnabled
                      ? '${state.sourceLanguage.code} → ${state.targetLanguage.code}'
                      : 'Off',
                  style: TextStyle(
                    color:
                        state.isEnabled ? Colors.lightBlueAccent : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildSoundIndicator() {
    return BlocBuilder<SoundDetectionCubit, SoundDetectionState>(
      builder: (context, state) {
        final hasEvents =
            state is SoundDetectionLoaded && state.events.isNotEmpty;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha((255 * 0.7).round()),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasEvents ? Colors.amber : Colors.grey,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.hearing,
                size: 16,
                color: hasEvents ? Colors.amber : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                hasEvents ? state.events.last.type : 'Listening...',
                style: TextStyle(
                  color: hasEvents ? Colors.amber : Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.grey[900],
      child: BlocBuilder<LiveCaptionsCubit, LiveCaptionsState>(
        builder: (context, state) {
          return Row(
            children: [
              _buildStatusChip(
                label: 'ASR',
                active: state is LiveCaptionsActive && state.isListening,
                activeColor: Colors.green,
              ),
              const SizedBox(width: 8),
              _buildStatusChip(
                label: 'Captions',
                active: state is LiveCaptionsActive,
                activeColor: Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildStatusChip(
                label: 'Translate',
                active: _isTranslationActive(),
                activeColor: Colors.lightBlueAccent,
              ),
              const SizedBox(width: 8),
              BlocBuilder<SoundDetectionCubit, SoundDetectionState>(
                builder: (context, sdState) {
                  return _buildStatusChip(
                    label: 'Sound',
                    active: context.read<SoundDetectionCubit>().isActive,
                    activeColor: Colors.amber,
                  );
                },
              ),
              const Spacer(),
              if (state is LiveCaptionsLoading)
                Text(
                  state.message ?? 'Loading...',
                  style: const TextStyle(color: Colors.orange, fontSize: 12),
                ),
              if (state is LiveCaptionsError)
                Text(
                  state.message,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
            ],
          );
        },
      ),
    );
  }

  bool _isTranslationActive() {
    try {
      final state = context.read<TranslationCubit>().state;
      return state is TranslationReady && state.isEnabled;
    } catch (_) {
      return false;
    }
  }

  Widget _buildStatusChip({
    required String label,
    required bool active,
    required Color activeColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active
            ? activeColor.withAlpha((255 * 0.2).round())
            : Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? activeColor : Colors.grey[700]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: active ? activeColor : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: active ? activeColor : Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
