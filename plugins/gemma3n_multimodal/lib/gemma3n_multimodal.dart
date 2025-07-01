import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'package:flutter_gemma/core/model.dart';
import 'gemma3n_multimodal_platform_interface.dart';

/// Wrapper around [FlutterGemmaPlugin] providing helpers for
/// the LiveCaptionsXR application.
class Gemma3nMultimodal {
  Gemma3nMultimodal({FlutterGemmaPlugin? gemma})
      : _gemma = gemma ?? FlutterGemmaPlugin.instance;

  final FlutterGemmaPlugin _gemma;

  /// Loads a Gemma model from [path] using [flutter_gemma].
  ///
  /// When [useANE] is true, the plugin attempts to use Apple's
  /// Neural Engine (mapped to [PreferredBackend.tpu]). If false,
  /// [useGPU] may request a GPU backend; otherwise the CPU is used.
  Future<void> loadModel(
    String path, {
    bool useANE = true,
    bool useGPU = false,
  }) async {
    await _gemma.modelManager.setModelPath(path);
    final backend = useANE
        ? PreferredBackend.tpu
        : useGPU
            ? PreferredBackend.gpu
            : PreferredBackend.cpu;
    await _gemma.createModel(
      modelType: ModelType.general,
      preferredBackend: backend,
      supportImage: true,
      maxNumImages: 1,
    );
  }

  Future<String?> getPlatformVersion() {
    return Gemma3nMultimodalPlatform.instance.getPlatformVersion();
  }
}
