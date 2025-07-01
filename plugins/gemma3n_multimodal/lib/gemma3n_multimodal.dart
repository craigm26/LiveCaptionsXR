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

  /// Transcribes audio using the native model.
  ///
  /// [audioBytes] should be a PCM-encoded audio buffer.
  /// Returns the transcription result as a [String].
  Future<String> transcribeAudio(Uint8List audioBytes) async {
    final result = await _channel.invokeMethod<String>('transcribeAudio', {
      'audio': audioBytes,
    });
    if (result == null) {
      throw PlatformException(
        code: 'NULL_RESULT',
        message: 'No result returned from native transcribeAudio',
      );
    }
    return result;
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
}
