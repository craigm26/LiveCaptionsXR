import 'dart:typed_data';
import 'package:flutter/services.dart';

/// Dart API for the gemma3n_multimodal plugin, providing model loading,
/// unloading, status, and multimodal inference via MethodChannel.
class Gemma3nMultimodal {
  static const MethodChannel _channel = MethodChannel('gemma3n_multimodal');
  static const EventChannel _streamChannel = EventChannel('gemma3n_multimodal_stream');

  /// Loads a Gemma-3n .task model from [path] on the native side.
  ///
  /// [useANE] (iOS) requests Apple's Neural Engine; [useGPU] requests GPU backend.
  /// Defaults to ANE on iOS, CPU on Android if both are false.
  /// Throws [PlatformException] on error.
  Future<void> loadModel(
    String path, {
    bool useANE = true,
    bool useGPU = false,
  }) async {
    await _channel.invokeMethod('loadModel', {
      'path': path,
      'useANE': useANE,
      'useGPU': useGPU,
    });
  }

  /// Unloads the model and frees native resources.
  Future<void> unloadModel() async {
    await _channel.invokeMethod('unloadModel');
  }

  /// Returns true if the model is loaded and ready for inference.
  Future<bool> get isModelLoaded async {
    final loaded = await _channel.invokeMethod<bool>('isModelLoaded');
    return loaded ?? false;
  }

  /// Returns the platform version string.
  Future<String?> getPlatformVersion() async {
    return await _channel.invokeMethod<String>('getPlatformVersion');
  }

  /// Transcribes audio using the hybrid ASR implementation.
  ///
  /// [audio] should be a PCM-encoded audio buffer.
  /// [isFinal] indicates if this is a final or interim transcription.
  /// [language] specifies the target language (default: 'en').
  /// [useNativeSpeechRecognition] enables native platform ASR (default: true).
  /// [enableRealTimeEnhancement] enables Gemma 3n enhancement (default: true).
  /// Returns the transcription result as a [String].
  Future<String> transcribeAudio({
    required Uint8List audio,
    bool isFinal = false,
    String language = 'en',
    bool useNativeSpeechRecognition = true,
    bool enableRealTimeEnhancement = true,
  }) async {
    final result = await _channel.invokeMethod<String>('transcribeAudio', {
      'audio': audio,
      'isFinal': isFinal,
      'language': language,
      'useNativeSpeechRecognition': useNativeSpeechRecognition,
      'enableRealTimeEnhancement': enableRealTimeEnhancement,
    });
    if (result == null) {
      throw PlatformException(
        code: 'NULL_RESULT',
        message: 'No result returned from native transcribeAudio',
      );
    }
    return result;
  }

  /// Legacy transcribes audio method for backward compatibility.
  ///
  /// [audioBytes] should be a PCM-encoded audio buffer.
  /// Returns the transcription result as a [String].
  @Deprecated('Use transcribeAudio with named parameters instead')
  Future<String> transcribeAudioLegacy(Uint8List audioBytes) async {
    return transcribeAudio(audio: audioBytes, isFinal: true);
  }

  /// Runs multimodal inference using the native model.
  ///
  /// Provide any combination of [audio], [image], and [text].
  /// Returns the inference result as a [String].
  Future<String> runMultimodal({Uint8List? audio, Uint8List? image, String? text}) async {
    final result = await _channel.invokeMethod<String>('runMultimodal', {
      if (audio != null) 'audio': audio,
      if (image != null) 'image': image,
      if (text != null) 'text': text,
    });
    if (result == null) {
      throw PlatformException(
        code: 'NULL_RESULT',
        message: 'No result returned from native runMultimodal',
      );
    }
    return result;
  }

  /// Streams partial transcription results from the native model.
  ///
  /// [audioBytes] should be a PCM-encoded audio buffer.
  /// Returns a Stream of partial transcription strings.
  Stream<String> streamTranscription(Uint8List audioBytes) {
    return _streamChannel
        .receiveBroadcastStream({
          'type': 'transcription',
          'audio': audioBytes,
        })
        .map((event) => event as String);
  }

  /// Streams partial multimodal inference results from the native model.
  ///
  /// Provide any combination of [audio], [image], and [text].
  /// Returns a Stream of partial inference strings.
  Stream<String> streamMultimodal({Uint8List? audio, Uint8List? image, String? text}) {
    final args = <String, dynamic>{'type': 'multimodal'};
    if (audio != null) args['audio'] = audio;
    if (image != null) args['image'] = image;
    if (text != null) args['text'] = text;
    return _streamChannel
        .receiveBroadcastStream(args)
        .map((event) => event as String);
  }

  /// Start audio capture for speech processing.
  ///
  /// [sampleRate] - Audio sample rate (default: 16000)
  /// [channels] - Number of audio channels (default: 1)
  /// [format] - Audio format (default: 'pcm16')
  Future<void> startAudioCapture({
    int sampleRate = 16000,
    int channels = 1,
    String format = 'pcm16',
  }) async {
    await _channel.invokeMethod('startAudioCapture', {
      'sampleRate': sampleRate,
      'channels': channels,
      'format': format,
    });
  }

  /// Stop audio capture for speech processing.
  Future<void> stopAudioCapture() async {
    await _channel.invokeMethod('stopAudioCapture');
  }

  /// Process an audio chunk for speech recognition.
  ///
  /// [audioData] - PCM audio data as Float32List
  /// [sampleRate] - Audio sample rate (default: 16000)
  Future<void> processAudioChunk(
    Uint8List audioData, {
    int sampleRate = 16000,
  }) async {
    await _channel.invokeMethod('processAudioChunk', {
      'audioData': audioData,
      'sampleRate': sampleRate,
    });
  }

  /// Generate enhanced text using the loaded model.
  ///
  /// [prompt] - Text prompt for generation
  /// [maxTokens] - Maximum number of tokens to generate (default: 100)
  /// [temperature] - Sampling temperature (default: 0.7)
  /// [topK] - Top-K sampling parameter (default: 40)
  /// [topP] - Top-P sampling parameter (default: 0.9)
  Future<Map<String, dynamic>> generateText(
    String prompt, {
    int maxTokens = 100,
    double temperature = 0.7,
    int topK = 40,
    double topP = 0.9,
  }) async {
    final result = await _channel.invokeMethod('generateText', {
      'prompt': prompt,
      'maxTokens': maxTokens,
      'temperature': temperature,
      'topK': topK,
      'topP': topP,
    });
    return Map<String, dynamic>.from(result);
  }

  /// Configure ASR settings for the plugin.
  ///
  /// [language] - Target language for speech recognition (default: 'en')
  /// [useNativeSpeechRecognition] - Enable native platform ASR (default: true)
  /// [enableRealTimeEnhancement] - Enable Gemma 3n enhancement (default: true)
  /// [voiceActivityThreshold] - Voice activity detection threshold (default: 0.01)
  /// [finalResultThreshold] - Final result confidence threshold (default: 0.005)
  Future<void> configureASR({
    String language = 'en',
    bool useNativeSpeechRecognition = true,
    bool enableRealTimeEnhancement = true,
    double voiceActivityThreshold = 0.01,
    double finalResultThreshold = 0.005,
  }) async {
    await _channel.invokeMethod('configureASR', {
      'language': language,
      'useNativeSpeechRecognition': useNativeSpeechRecognition,
      'enableRealTimeEnhancement': enableRealTimeEnhancement,
      'voiceActivityThreshold': voiceActivityThreshold,
      'finalResultThreshold': finalResultThreshold,
    });
  }

  /// Get ASR capabilities and status.
  ///
  /// Returns information about available ASR features and current configuration.
  Future<Map<String, dynamic>> getASRCapabilities() async {
    final result = await _channel.invokeMethod('getASRCapabilities');
    return Map<String, dynamic>.from(result ?? {});
  }
}
