import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:live_captions_xr/core/services/ar_anchor_manager.dart';

void main() {
  group('ARSession Fix Tests', () {
    late ARAnchorManager arAnchorManager;

    setUp(() {
      arAnchorManager = ARAnchorManager();
    });

    testWidgets('should retry when ARSession is not available', (tester) async {
      // Mock the method channel to simulate NO_SESSION error followed by success
      int callCount = 0;
      
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('live_captions_xr/ar_anchor_methods'),
        (MethodCall methodCall) async {
          callCount++;
          
          if (methodCall.method == 'getDeviceOrientation') {
            if (callCount == 1) {
              // First call - simulate session not ready
              throw PlatformException(
                code: 'NO_SESSION',
                message: 'ARSession not available',
              );
            } else if (callCount == 2) {
              // Second call - simulate session ready
              return List.generate(16, (index) => index * 0.1);
            }
          }
          
          return null;
        },
      );

      // This should succeed after retry
      final result = await arAnchorManager.getDeviceOrientation();
      
      expect(result, isNotNull);
      expect(result.length, equals(16));
      expect(callCount, equals(2)); // Should have retried once
    });

    testWidgets('should fail after max retries', (tester) async {
      // Mock the method channel to always return NO_SESSION error
      int callCount = 0;
      
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('live_captions_xr/ar_anchor_methods'),
        (MethodCall methodCall) async {
          callCount++;
          
          if (methodCall.method == 'getDeviceOrientation') {
            throw PlatformException(
              code: 'NO_SESSION',
              message: 'ARSession not available',
            );
          }
          
          return null;
        },
      );

      // This should fail after max retries
      expect(
        () => arAnchorManager.getDeviceOrientation(maxRetries: 2),
        throwsA(isA<PlatformException>().having(
          (e) => e.code,
          'code',
          'NO_SESSION',
        )),
      );
      
      expect(callCount, equals(2)); // Should have tried twice
    });

    testWidgets('should succeed immediately if session is ready', (tester) async {
      // Mock the method channel to return success immediately
      int callCount = 0;
      
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('live_captions_xr/ar_anchor_methods'),
        (MethodCall methodCall) async {
          callCount++;
          
          if (methodCall.method == 'getDeviceOrientation') {
            return List.generate(16, (index) => index * 0.1);
          }
          
          return null;
        },
      );

      // This should succeed immediately
      final result = await arAnchorManager.getDeviceOrientation();
      
      expect(result, isNotNull);
      expect(result.length, equals(16));
      expect(callCount, equals(1)); // Should have called only once
    });

    testWidgets('should handle invalid orientation matrix', (tester) async {
      // Mock the method channel to return invalid matrix
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('live_captions_xr/ar_anchor_methods'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getDeviceOrientation') {
            return [1.0, 2.0, 3.0]; // Invalid - should be 16 elements
          }
          
          return null;
        },
      );

      // This should fail due to invalid matrix size
      expect(
        () => arAnchorManager.getDeviceOrientation(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Invalid device orientation matrix length'),
        )),
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('live_captions_xr/ar_anchor_methods'),
        null,
      );
    });
  });
}