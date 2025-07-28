import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../utils/responsive_utils.dart';

class YouTubeEmbed extends StatefulWidget {
  final String videoId;
  final double? width;
  final double? height;
  final bool autoPlay;
  final bool showControls;
  final bool enableCaption;

  const YouTubeEmbed({
    super.key,
    required this.videoId,
    this.width,
    this.height,
    this.autoPlay = false,
    this.showControls = true,
    this.enableCaption = true,
  });

  @override
  State<YouTubeEmbed> createState() => _YouTubeEmbedState();
}

class _YouTubeEmbedState extends State<YouTubeEmbed> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: YoutubePlayerFlags(
        autoPlay: widget.autoPlay,
        mute: false,
        enableCaption: widget.enableCaption,
        isLive: false,
        forceHD: false,
        hideControls: !widget.showControls,
        loop: false,
        showLiveFullscreenButton: false,
      ),
    );

    _controller.addListener(_listener);
  }

  void _listener() {
    if (_controller.value.isReady && !_isPlayerReady) {
      setState(() {
        _isPlayerReady = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_listener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    
    // Calculate responsive dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final responsiveWidth = widget.width ?? 
        (isMobile ? screenWidth * 0.9 : 
         isTablet ? screenWidth * 0.8 : 
         screenWidth * 0.7);
    
    final responsiveHeight = widget.height ?? 
        (isMobile ? responsiveWidth * 0.56 : 
         isTablet ? responsiveWidth * 0.56 : 
         responsiveWidth * 0.56); // 16:9 aspect ratio

    return Container(
      width: responsiveWidth,
      height: responsiveHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Theme.of(context).primaryColor,
          progressColors: ProgressBarColors(
            playedColor: Theme.of(context).primaryColor,
            handleColor: Theme.of(context).primaryColor.withOpacity(0.8),
            backgroundColor: Colors.grey.withOpacity(0.3),
            bufferedColor: Colors.grey.withOpacity(0.5),
          ),
          onReady: () {
            setState(() {
              _isPlayerReady = true;
            });
          },
          onEnded: (YoutubeMetaData metaData) {
            // Handle video end
            debugPrint('Video ended: ${metaData.title}');
          },
          topActions: [
            IconButton(
              icon: const Icon(Icons.fullscreen),
              onPressed: () {
                _controller.toggleFullScreenMode();
              },
            ),
          ],
          bottomActions: [
            CurrentPosition(),
            ProgressBar(isExpanded: true),
            PlaybackSpeedButton(),
          ],
        ),
      ),
    );
  }
}

/// Enhanced YouTube embed with loading state and error handling
class EnhancedYouTubeEmbed extends StatefulWidget {
  final String videoId;
  final double? width;
  final double? height;
  final bool autoPlay;
  final bool showControls;
  final bool enableCaption;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const EnhancedYouTubeEmbed({
    super.key,
    required this.videoId,
    this.width,
    this.height,
    this.autoPlay = false,
    this.showControls = true,
    this.enableCaption = true,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  State<EnhancedYouTubeEmbed> createState() => _EnhancedYouTubeEmbedState();
}

class _EnhancedYouTubeEmbedState extends State<EnhancedYouTubeEmbed> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    try {
      _controller = YoutubePlayerController(
        initialVideoId: widget.videoId,
        flags: YoutubePlayerFlags(
          autoPlay: widget.autoPlay,
          mute: false,
          enableCaption: widget.enableCaption,
          isLive: false,
          forceHD: false,
          hideControls: !widget.showControls,
          loop: false,
          showLiveFullscreenButton: false,
        ),
      );

      _controller.addListener(_listener);
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _listener() {
    if (_controller.value.isReady && !_isPlayerReady) {
      setState(() {
        _isPlayerReady = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_listener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorWidget();
    }

    if (!_isPlayerReady) {
      return _buildLoadingWidget();
    }

    return YouTubeEmbed(
      videoId: widget.videoId,
      width: widget.width,
      height: widget.height,
      autoPlay: widget.autoPlay,
      showControls: widget.showControls,
      enableCaption: widget.enableCaption,
    );
  }

  Widget _buildLoadingWidget() {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    
    final screenWidth = MediaQuery.of(context).size.width;
    final responsiveWidth = widget.width ?? 
        (isMobile ? screenWidth * 0.9 : 
         isTablet ? screenWidth * 0.8 : 
         screenWidth * 0.7);
    
    final responsiveHeight = widget.height ?? 
        (isMobile ? responsiveWidth * 0.56 : 
         isTablet ? responsiveWidth * 0.56 : 
         responsiveWidth * 0.56);

    return widget.loadingWidget ?? Container(
      width: responsiveWidth,
      height: responsiveHeight,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading video...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    
    final screenWidth = MediaQuery.of(context).size.width;
    final responsiveWidth = widget.width ?? 
        (isMobile ? screenWidth * 0.9 : 
         isTablet ? screenWidth * 0.8 : 
         screenWidth * 0.7);
    
    final responsiveHeight = widget.height ?? 
        (isMobile ? responsiveWidth * 0.56 : 
         isTablet ? responsiveWidth * 0.56 : 
         responsiveWidth * 0.56);

    return widget.errorWidget ?? Container(
      width: responsiveWidth,
      height: responsiveHeight,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load video',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Video ID: ${widget.videoId}',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _errorMessage = '';
                });
                _initializeController();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
} 