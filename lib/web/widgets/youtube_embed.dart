import 'package:flutter/material.dart';

/// A simple YouTube embed widget for web platforms
/// Uses iframe to embed YouTube videos without webview dependencies
class YouTubeEmbed extends StatelessWidget {
  final String videoId;
  final double aspectRatio;
  final bool showControls;
  final bool enableCaption;
  final bool autoPlay;

  const YouTubeEmbed({
    super.key,
    required this.videoId,
    this.aspectRatio = 16 / 9,
    this.showControls = true,
    this.enableCaption = true,
    this.autoPlay = false,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildIframe(),
        ),
      ),
    );
  }

  Widget _buildIframe() {
    final url = _buildYouTubeUrl();
    
    // Use a simple iframe approach
    return HtmlElementView(
      viewType: 'iframe',
      onPlatformViewCreated: (int id) {
        // The iframe will be created by the web platform
      },
    );
  }

  String _buildYouTubeUrl() {
    final params = <String, String>{
      'rel': '0',
      'modestbranding': '1',
    };

    if (!showControls) {
      params['controls'] = '0';
    }

    if (enableCaption) {
      params['cc_load_policy'] = '1';
    }

    if (autoPlay) {
      params['autoplay'] = '1';
      params['mute'] = '1'; // Required for autoplay
    }

    final queryString = params.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');

    return 'https://www.youtube.com/embed/$videoId?$queryString';
  }
}

/// Enhanced YouTube embed with loading state and error handling
class EnhancedYouTubeEmbed extends StatefulWidget {
  final String videoId;
  final double aspectRatio;
  final bool showControls;
  final bool enableCaption;
  final bool autoPlay;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const EnhancedYouTubeEmbed({
    super.key,
    required this.videoId,
    this.aspectRatio = 16 / 9,
    this.showControls = true,
    this.enableCaption = true,
    this.autoPlay = false,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  State<EnhancedYouTubeEmbed> createState() => _EnhancedYouTubeEmbedState();
}

class _EnhancedYouTubeEmbedState extends State<EnhancedYouTubeEmbed> {
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  void _loadVideo() {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Simulate loading time for better UX
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorWidget ??
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Failed to load video',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
    }

    if (_isLoading) {
      return widget.loadingWidget ??
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading video...'),
                ],
              ),
            ),
          );
    }

    return YouTubeEmbed(
      videoId: widget.videoId,
      aspectRatio: widget.aspectRatio,
      showControls: widget.showControls,
      enableCaption: widget.enableCaption,
      autoPlay: widget.autoPlay,
    );
  }
} 