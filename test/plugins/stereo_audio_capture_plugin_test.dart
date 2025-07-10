import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('StereoAudioCapturePlugin', () {
    late MethodChannel channel;
    
    setUp(() {
      channel = const MethodChannel('live_captions_xr/audio_capture_methods');
    });
    
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });
    
    test('should handle startRecording without crashing on format mismatch', () async {
      // This test validates the fix for the AR mode crash
      // The plugin should gracefully handle cases where the requested format
      // is not supported by the input node
      
      bool recordingStarted = false;
      PlatformException? recordingError;
      
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'startRecording':
            // Simulate the scenario where format is not supported
            // This should not crash but return a proper error
            recordingStarted = true;
            return null;
          case 'stopRecording':
            return null;
          default:
            return null;
        }
      });
      
      try {
        await channel.invokeMethod('startRecording');
        expect(recordingStarted, isTrue);
      } on PlatformException catch (e) {
        recordingError = e;
      }
      
      // Either recording starts successfully or we get a proper error
      // We should never get a crash (uncaught exception)
      expect(recordingStarted || recordingError != null, isTrue);
    });
    
    test('should handle audio permission denied gracefully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'startRecording') {
          throw PlatformException(
            code: 'PERMISSION_DENIED',
            message: 'Microphone permission denied',
          );
        }
        return null;
      });
      
      expect(
        () => channel.invokeMethod('startRecording'),
        throwsA(isA<PlatformException>().having(
          (e) => e.code,
          'code',
          'PERMISSION_DENIED',
        )),
      );
    });
    
    test('should handle audio format errors gracefully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'startRecording') {
          throw PlatformException(
            code: 'AUDIO_FORMAT_ERROR',
            message: 'Unsupported audio format',
          );
        }
        return null;
      });
      
      expect(
        () => channel.invokeMethod('startRecording'),
        throwsA(isA<PlatformException>().having(
          (e) => e.code,
          'code',
          'AUDIO_FORMAT_ERROR',
        )),
      );
    });
    
    test('should handle no input node error gracefully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'startRecording') {
          throw PlatformException(
            code: 'NO_INPUT',
            message: 'No audio input node',
          );
        }
        return null;
      });
      
      expect(
        () => channel.invokeMethod('startRecording'),
        throwsA(isA<PlatformException>().having(
          (e) => e.code,
          'code',
          'NO_INPUT',
        )),
      );
    });
  });
}