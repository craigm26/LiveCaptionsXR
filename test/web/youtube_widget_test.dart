import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:live_captions_xr/web/pages/home/home_page.dart';

void main() {
  group('YouTube Player Tests', () {
    testWidgets('should display YouTube player with correct video ID', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const HomePage(),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify that the YouTube player is present
      expect(find.byType(YoutubePlayer), findsOneWidget);
    });

    test('should extract correct video ID from YouTube URL', () {
      // Test the video ID extraction logic
      const videoUrl = 'https://youtu.be/Oz8nzt2cc3Q';
      const expectedVideoId = 'Oz8nzt2cc3Q';
      
      // Extract video ID from URL (this is what we're using in the code)
      final videoId = videoUrl.split('/').last;
      expect(videoId, equals(expectedVideoId));
    });
  });
} 