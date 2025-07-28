import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_captions_xr/web/widgets/youtube_embed.dart';

void main() {
  group('YouTube Widget Tests', () {
    testWidgets('should render YouTube embed widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: YouTubeEmbed(
              videoId: 'dQw4w9WgXcQ',
            ),
          ),
        ),
      );

      // Should show the YouTube player container
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should render enhanced YouTube embed widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedYouTubeEmbed(
              videoId: 'dQw4w9WgXcQ',
            ),
          ),
        ),
      );

      // Should show the enhanced YouTube player
      expect(find.byType(EnhancedYouTubeEmbed), findsOneWidget);
    });

    testWidgets('should show loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedYouTubeEmbed(
              videoId: 'dQw4w9WgXcQ',
            ),
          ),
        ),
      );

      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading video...'), findsOneWidget);
    });

    testWidgets('should handle custom loading widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedYouTubeEmbed(
              videoId: 'dQw4w9WgXcQ',
              loadingWidget: const Center(
                child: Text('Custom Loading...'),
              ),
            ),
          ),
        ),
      );

      // Should show custom loading widget
      expect(find.text('Custom Loading...'), findsOneWidget);
    });

    testWidgets('should handle custom error widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedYouTubeEmbed(
              videoId: 'invalid_video_id',
              errorWidget: const Center(
                child: Text('Custom Error Message'),
              ),
            ),
          ),
        ),
      );

      // Should show custom error widget for invalid video ID
      expect(find.text('Custom Error Message'), findsOneWidget);
    });

    testWidgets('should be responsive on different screen sizes', (WidgetTester tester) async {
      // Test mobile size
      tester.binding.window.physicalSizeTestValue = const Size(375, 812);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: YouTubeEmbed(
              videoId: 'dQw4w9WgXcQ',
            ),
          ),
        ),
      );

      // Should render without errors on mobile
      expect(find.byType(YouTubeEmbed), findsOneWidget);

      // Test desktop size
      tester.binding.window.physicalSizeTestValue = const Size(1920, 1080);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: YouTubeEmbed(
              videoId: 'dQw4w9WgXcQ',
            ),
          ),
        ),
      );

      // Should render without errors on desktop
      expect(find.byType(YouTubeEmbed), findsOneWidget);
    });

    test('YouTube embed should have correct properties', () {
      const widget = YouTubeEmbed(
        videoId: 'test_video_id',
        autoPlay: true,
        showControls: false,
        enableCaption: true,
      );

      expect(widget.videoId, equals('test_video_id'));
      expect(widget.autoPlay, isTrue);
      expect(widget.showControls, isFalse);
      expect(widget.enableCaption, isTrue);
    });

    test('Enhanced YouTube embed should have correct properties', () {
      const widget = EnhancedYouTubeEmbed(
        videoId: 'test_video_id',
        autoPlay: false,
        showControls: true,
        enableCaption: false,
      );

      expect(widget.videoId, equals('test_video_id'));
      expect(widget.autoPlay, isFalse);
      expect(widget.showControls, isTrue);
      expect(widget.enableCaption, isFalse);
    });
  });
} 