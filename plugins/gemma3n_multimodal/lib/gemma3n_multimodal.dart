
import 'gemma3n_multimodal_platform_interface.dart';

class Gemma3nMultimodal {
  Future<String?> getPlatformVersion() {
    return Gemma3nMultimodalPlatform.instance.getPlatformVersion();
  }
}
