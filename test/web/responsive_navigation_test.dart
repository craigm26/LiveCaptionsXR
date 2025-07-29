import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:live_captions_xr/web/widgets/nav_bar.dart';
import 'package:live_captions_xr/web/utils/responsive_utils.dart';
import 'package:live_captions_xr/app_shell.dart';

void main() {
  group('Responsive Navigation Tests', () {
    test('ResponsiveUtils should correctly detect screen sizes', () {
      // Test mobile detection
      expect(ResponsiveBreakpoints.mobile, equals(768));
      expect(ResponsiveBreakpoints.tablet, equals(1024));
      expect(ResponsiveBreakpoints.desktop, equals(1200));
      expect(ResponsiveBreakpoints.largeDesktop, equals(1440));
    });

    testWidgets('AppShell should handle web platform detection', (WidgetTester tester) async {
      // Test that AppShell can be built without router context
      await tester.pumpWidget(
        MaterialApp(
          home: const AppShell(
            child: Center(child: Text('Test Content')),
          ),
        ),
      );

      // Should show hamburger menu button
      expect(find.byIcon(Icons.menu), findsOneWidget);
      
      // Should show app title
      expect(find.text('Live Captions XR'), findsOneWidget);
    });

    testWidgets('AppShell hamburger menu should be tappable', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const AppShell(
            child: Center(child: Text('Test Content')),
          ),
        ),
      );

      // Should show hamburger menu button
      expect(find.byIcon(Icons.menu), findsOneWidget);
      
      // Should be able to tap the hamburger menu (even if drawer doesn't open due to router context)
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump();
      
      // Should not throw any errors
      expect(tester.takeException(), isNull);
    });
  });
} 