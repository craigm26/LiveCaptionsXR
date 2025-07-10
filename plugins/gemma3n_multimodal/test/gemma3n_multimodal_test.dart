import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemma3n_multimodal/gemma3n_multimodal.dart';
import 'dart:typed_data';

class _FakeEventChannel {
  static const String channelName = 'gemma3n_multimodal_stream';
  static void mockStream({required List<dynamic> events, bool throwError = false}) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      channelName,
      (ByteData? message) async {
        if (throwError) {
          throw PlatformException(code: 'STREAM_FAILED', message: 'Stream error');
        }
        // Simulate a stream of events
        for (final event in events) {
          ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
            channelName,
            const StandardMethodCodec().encodeSuccessEnvelope(event),
            (_) {},
          );
        }
        return null;
      },
    );
  }
  static void clear() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(channelName, null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel('gemma3n_multimodal');
  final plugin = Gemma3nMultimodal();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'loadModel':
            if (methodCall.arguments['path'] == 'fail') {
              throw PlatformException(code: 'LOAD_FAILED', message: 'Failed to load');
            }
            return null;
          case 'unloadModel':
            return null;
          case 'isModelLoaded':
            return methodCall.arguments?['loaded'] ?? true;
          case 'getPlatformVersion':
            return 'iOS 17.0';
          case 'transcribeAudio':
            if (methodCall.arguments['audio'] == null) {
              throw PlatformException(code: 'INVALID_ARGUMENT', message: 'Missing audio');
            }
            return 'transcribed text';
          case 'runMultimodal':
            if (methodCall.arguments['audio'] == null && methodCall.arguments['image'] == null && methodCall.arguments['text'] == null) {
              throw PlatformException(code: 'INVALID_ARGUMENT', message: 'No input');
            }
            return 'multimodal result';
          case 'startAudioCapture':
            return null;
          case 'stopAudioCapture':
            return null;
          case 'processAudioChunk':
            if (methodCall.arguments['audioData'] == null) {
              throw PlatformException(code: 'NOT_READY', message: 'Audio capture not started or missing audio data');
            }
            return null;
          case 'generateText':
            if (methodCall.arguments['prompt'] == null) {
              throw PlatformException(code: 'INVALID_ARGUMENT', message: 'Missing prompt or model not loaded');
            }
            return {'success': true, 'text': 'generated text result'};
          default:
            throw PlatformException(code: 'NOT_IMPLEMENTED', message: 'Not implemented');
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('loadModel succeeds', () async {
    await plugin.loadModel('path/to/model.task', useANE: true, useGPU: false);
  });

  test('loadModel throws on failure', () async {
    expect(
      () => plugin.loadModel('fail'),
      throwsA(isA<PlatformException>()),
    );
  });

  test('unloadModel succeeds', () async {
    await plugin.unloadModel();
  });

  test('isModelLoaded returns true', () async {
    expect(await plugin.isModelLoaded, true);
  });

  test('getPlatformVersion returns version', () async {
    expect(await plugin.getPlatformVersion(), 'iOS 17.0');
  });

  test('transcribeAudio returns transcription', () async {
    final audio = Uint8List.fromList([1, 2, 3]);
    expect(await plugin.transcribeAudio(audio: audio), 'transcribed text');
  });

  test('transcribeAudio throws on missing audio', () async {
    expect(
      () => plugin.transcribeAudio(audio: Uint8List(0)),
      throwsA(isA<PlatformException>()),
    );
  });

  test('runMultimodal returns result', () async {
    final audio = Uint8List.fromList([1, 2, 3]);
    expect(await plugin.runMultimodal(audio: audio), 'multimodal result');
    expect(await plugin.runMultimodal(image: audio), 'multimodal result');
    expect(await plugin.runMultimodal(text: 'hello'), 'multimodal result');
  });

  test('runMultimodal throws on no input', () async {
    expect(
      () => plugin.runMultimodal(),
      throwsA(isA<PlatformException>()),
    );
  });

  group('streamTranscription', () {
    test('receives partial results', () async {
      final audio = Uint8List.fromList([1, 2, 3]);
      _FakeEventChannel.mockStream(events: ['partial1', 'partial2', 'partial3']);
      final plugin = Gemma3nMultimodal();
      final results = await plugin.streamTranscription(audio).take(3).toList();
      expect(results, ['partial1', 'partial2', 'partial3']);
      _FakeEventChannel.clear();
    });
    test('throws on stream error', () async {
      final audio = Uint8List.fromList([1, 2, 3]);
      _FakeEventChannel.mockStream(events: [], throwError: true);
      final plugin = Gemma3nMultimodal();
      expect(
        () => plugin.streamTranscription(audio).first,
        throwsA(isA<PlatformException>()),
      );
      _FakeEventChannel.clear();
    });
  });

  group('streamMultimodal', () {
    test('receives partial multimodal results', () async {
      final audio = Uint8List.fromList([1, 2, 3]);
      _FakeEventChannel.mockStream(events: ['mm1', 'mm2']);
      final plugin = Gemma3nMultimodal();
      final results = await plugin.streamMultimodal(audio: audio).take(2).toList();
      expect(results, ['mm1', 'mm2']);
      _FakeEventChannel.clear();
    });
    test('throws on stream error', () async {
      final audio = Uint8List.fromList([1, 2, 3]);
      _FakeEventChannel.mockStream(events: [], throwError: true);
      final plugin = Gemma3nMultimodal();
      expect(
        () => plugin.streamMultimodal(audio: audio).first,
        throwsA(isA<PlatformException>()),
      );
      _FakeEventChannel.clear();
    });
  });

  // Tests for new audio capture methods
  group('audio capture methods', () {
    test('startAudioCapture succeeds', () async {
      const MethodChannel channel = MethodChannel('gemma3n_multimodal');
      final plugin = Gemma3nMultimodal();

      // This should not throw since we added startAudioCapture to the mock
      await channel.invokeMethod('startAudioCapture', {
        'sampleRate': 16000,
        'channels': 1,
        'format': 'pcm16',
      });
    });

    test('stopAudioCapture succeeds', () async {
      const MethodChannel channel = MethodChannel('gemma3n_multimodal');
      final plugin = Gemma3nMultimodal();

      // This should not throw since we added stopAudioCapture to the mock
      await channel.invokeMethod('stopAudioCapture');
    });

    test('processAudioChunk succeeds with audio data', () async {
      const MethodChannel channel = MethodChannel('gemma3n_multimodal');
      final plugin = Gemma3nMultimodal();
      final audioData = Uint8List.fromList([1, 2, 3, 4]);

      // This should not throw since we added processAudioChunk to the mock
      await channel.invokeMethod('processAudioChunk', {
        'audioData': audioData,
        'sampleRate': 16000,
      });
    });

    test('processAudioChunk throws on missing audio data', () async {
      const MethodChannel channel = MethodChannel('gemma3n_multimodal');

      expect(
        () => channel.invokeMethod('processAudioChunk', {}),
        throwsA(isA<PlatformException>()),
      );
    });

    test('generateText succeeds with prompt', () async {
      const MethodChannel channel = MethodChannel('gemma3n_multimodal');
      final plugin = Gemma3nMultimodal();

      final result = await channel.invokeMethod('generateText', {
        'prompt': 'Test prompt',
        'maxTokens': 100,
        'temperature': 0.3,
      });

      expect(result['success'], true);
      expect(result['text'], 'generated text result');
    });

    test('generateText throws on missing prompt', () async {
      const MethodChannel channel = MethodChannel('gemma3n_multimodal');

      expect(
        () => channel.invokeMethod('generateText', {}),
        throwsA(isA<PlatformException>()),
      );
    });
  });
}
