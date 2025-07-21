import 'package:flutter_test/flutter_test.dart';
import 'package:live_captions_xr/core/services/model_download_manager.dart';

void main() {
  group('Model Download Manager Tests', () {
    late ModelDownloadManager modelManager;

    setUp(() {
      modelManager = ModelDownloadManager();
    });

    test('should create correct model file names', () {
      final config = modelManager.getModelConfig('whisper-base');
      expect(config, isNotNull);
      expect(config!.fileName, equals('ggml-base.bin'));
      expect(config.assetPath, equals('assets/models/whisper_base.bin'));
      expect(config.type, equals(ModelType.whisper));
      expect(config.displayName, equals('Whisper Base'));
    });

    test('should have correct model configurations', () {
      final whisperConfig = modelManager.getModelConfig('whisper-base');
      final gemmaConfig = modelManager.getModelConfig('gemma-3n-E4B-it-int4');
      
      expect(whisperConfig, isNotNull);
      expect(gemmaConfig, isNotNull);
      
      expect(whisperConfig!.type, equals(ModelType.whisper));
      expect(gemmaConfig!.type, equals(ModelType.gemma));
    });

    test('should list available models', () {
      final models = modelManager.availableModels;
      expect(models, contains('whisper-base'));
      expect(models, contains('gemma-3n-E4B-it-int4'));
    });
  });
} 