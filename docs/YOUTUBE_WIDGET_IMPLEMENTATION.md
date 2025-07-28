# YouTube Widget Implementation

## Overview

The Live Captions XR web application now uses the [youtube_player_flutter](https://pub.dev/packages/youtube_player_flutter) package for enhanced YouTube video embedding. This package provides better cross-platform support, more features, and improved performance compared to the previous implementation.

## Features

### Basic YouTube Embed (`YouTubeEmbed`)
- **Responsive Design**: Automatically adapts to different screen sizes
- **Custom Controls**: Full control over player appearance and behavior
- **Progress Indicators**: Visual progress bar with custom colors
- **Fullscreen Support**: Built-in fullscreen functionality
- **Event Handling**: Support for video end and state change events

### Enhanced YouTube Embed (`EnhancedYouTubeEmbed`)
- **Loading States**: Custom loading indicators
- **Error Handling**: Graceful error handling with retry functionality
- **Custom Widgets**: Support for custom loading and error widgets
- **Better UX**: Improved user experience with proper state management

## Implementation

### Dependencies

The implementation requires the following dependency in `pubspec.yaml`:

```yaml
dependencies:
  youtube_player_flutter: ^9.1.1
```

### Basic Usage

```dart
import 'package:live_captions_xr/web/widgets/youtube_embed.dart';

// Basic YouTube embed
YouTubeEmbed(
  videoId: 'dQw4w9WgXcQ',
  autoPlay: false,
  showControls: true,
  enableCaption: true,
)
```

### Enhanced Usage

```dart
// Enhanced YouTube embed with custom loading and error states
EnhancedYouTubeEmbed(
  videoId: 'dQw4w9WgXcQ',
  autoPlay: false,
  showControls: true,
  enableCaption: true,
  loadingWidget: Center(
    child: Column(
      children: [
        CircularProgressIndicator(),
        Text('Loading video...'),
      ],
    ),
  ),
  errorWidget: Center(
    child: Column(
      children: [
        Icon(Icons.error),
        Text('Failed to load video'),
        ElevatedButton(
          onPressed: () => retry(),
          child: Text('Retry'),
        ),
      ],
    ),
  ),
)
```

## Configuration Options

### YouTubeEmbed Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `videoId` | String | Required | YouTube video ID |
| `width` | double? | null | Custom width (responsive if null) |
| `height` | double? | null | Custom height (responsive if null) |
| `autoPlay` | bool | false | Auto-play video on load |
| `showControls` | bool | true | Show player controls |
| `enableCaption` | bool | true | Enable video captions |

### EnhancedYouTubeEmbed Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `videoId` | String | Required | YouTube video ID |
| `width` | double? | null | Custom width (responsive if null) |
| `height` | double? | null | Custom height (responsive if null) |
| `autoPlay` | bool | false | Auto-play video on load |
| `showControls` | bool | true | Show player controls |
| `enableCaption` | bool | true | Enable video captions |
| `loadingWidget` | Widget? | null | Custom loading widget |
| `errorWidget` | Widget? | null | Custom error widget |

## Responsive Design

The YouTube widget automatically adapts to different screen sizes:

- **Mobile (< 768px)**: 90% of screen width
- **Tablet (768px - 1023px)**: 80% of screen width
- **Desktop (≥ 1024px)**: 70% of screen width

All sizes maintain a 16:9 aspect ratio for optimal video viewing.

## Player Controls

The widget includes the following built-in controls:

- **Play/Pause Button**: Control video playback
- **Progress Bar**: Visual progress indicator with seek functionality
- **Current Position**: Display current playback time
- **Total Duration**: Display total video duration
- **Playback Speed**: Control video playback speed
- **Fullscreen Button**: Toggle fullscreen mode

## Event Handling

The widget supports various events:

```dart
YouTubeEmbed(
  videoId: 'dQw4w9WgXcQ',
  onReady: () {
    print('Video is ready to play');
  },
  onEnded: (YoutubeMetaData metaData) {
    print('Video ended: ${metaData.title}');
  },
  onStateChange: (YoutubePlayerState state) {
    print('Player state changed: $state');
  },
)
```

## Customization

### Custom Progress Bar Colors

```dart
YouTubeEmbed(
  videoId: 'dQw4w9WgXcQ',
  progressColors: ProgressBarColors(
    playedColor: Colors.blue,
    handleColor: Colors.blueAccent,
    backgroundColor: Colors.grey[300]!,
    bufferedColor: Colors.grey[500]!,
  ),
)
```

### Custom Player Actions

```dart
YouTubeEmbed(
  videoId: 'dQw4w9WgXcQ',
  topActions: [
    IconButton(
      icon: Icon(Icons.share),
      onPressed: () => shareVideo(),
    ),
  ],
  bottomActions: [
    CurrentPosition(),
    ProgressBar(isExpanded: true),
    TotalDuration(),
    PlaybackSpeedButton(),
  ],
)
```

## Error Handling

The enhanced widget provides comprehensive error handling:

1. **Network Errors**: Handles network connectivity issues
2. **Invalid Video IDs**: Gracefully handles invalid video IDs
3. **Player Initialization Errors**: Handles player setup failures
4. **Retry Functionality**: Allows users to retry failed loads

## Performance Considerations

- **Lazy Loading**: Videos are loaded only when needed
- **Memory Management**: Proper disposal of player controllers
- **Responsive Loading**: Optimized for different network conditions
- **Platform Optimization**: Uses platform-specific optimizations

## Browser Compatibility

The YouTube widget works across all modern browsers:
- Chrome/Chromium
- Firefox
- Safari
- Edge

## Testing

The implementation includes comprehensive tests:

```bash
flutter test test/web/youtube_widget_test.dart
```

Tests cover:
- Basic widget rendering
- Enhanced widget functionality
- Loading states
- Error handling
- Responsive behavior
- Custom widgets

## Migration from Previous Implementation

### Before (Old Implementation)
```dart
// Old HTML-based implementation
YouTubeEmbed(
  videoId: 'dQw4w9WgXcQ',
  width: 800,
  height: 450,
)
```

### After (New Implementation)
```dart
// New Flutter-based implementation
EnhancedYouTubeEmbed(
  videoId: 'dQw4w9WgXcQ',
  autoPlay: false,
  showControls: true,
  enableCaption: true,
)
```

## Best Practices

1. **Use Enhanced Widget**: Prefer `EnhancedYouTubeEmbed` for better UX
2. **Handle Errors**: Always provide error handling for production apps
3. **Responsive Design**: Let the widget handle responsive sizing automatically
4. **Performance**: Dispose controllers properly to prevent memory leaks
5. **Accessibility**: Ensure videos have captions enabled for accessibility

## Troubleshooting

### Common Issues

1. **Video Not Loading**
   - Check internet connectivity
   - Verify video ID is correct
   - Ensure video is publicly accessible

2. **Controls Not Showing**
   - Verify `showControls` is set to `true`
   - Check if video is in a restricted region

3. **Fullscreen Not Working**
   - Ensure proper permissions are set
   - Check browser fullscreen policies

### Debug Information

Enable debug logging for troubleshooting:

```dart
YouTubeEmbed(
  videoId: 'dQw4w9WgXcQ',
  onReady: () => debugPrint('Video ready'),
  onEnded: (metaData) => debugPrint('Video ended: ${metaData.title}'),
  onStateChange: (state) => debugPrint('State: $state'),
)
```

## Future Enhancements

Potential future improvements:
- **Picture-in-Picture Support**: For multitasking scenarios
- **Quality Selection**: Allow users to choose video quality
- **Playlist Support**: Support for YouTube playlists
- **Analytics Integration**: Track video engagement metrics
- **Advanced Controls**: Custom control layouts and themes 