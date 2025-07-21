import 'package:flutter_test/flutter_test.dart';
import 'package:live_captions_xr/core/services/model_download_manager.dart';

void main() {
  group('Model Availability Tests', () {
    late ModelDownloadManager modelManager;

    setUp(() {
      modelManager = ModelDownloadManager();
    });

    test('should have correct model configurations', () {
      final whisperConfig = modelManager.getModelConfig('whisper-base');
      final gemmaConfig = modelManager.getModelConfig('gemma-3n-E4B-it-int4');
      
      expect(whisperConfig, isNotNull);
      expect(gemmaConfig, isNotNull);
      
      expect(whisperConfig!.assetPath, equals('assets/models/whisper_base.bin'));
      expect(gemmaConfig!.assetPath, equals('assets/models/gemma-3n-E4B-it-int4.task'));
      
      expect(whisperConfig.fileName, equals('ggml-base.bin'));
      expect(gemmaConfig.fileName, equals('gemma-3n-E4B-it-int4.task'));
    });

    test('should list available models', () {
      final models = modelManager.availableModels;
      expect(models, contains('whisper-base'));
      expect(models, contains('gemma-3n-E4B-it-int4'));
    });

    test('should categorize models by type', () {
      final whisperModels = modelManager.whisperModels;
      final gemmaModels = modelManager.gemmaModels;
      
      expect(whisperModels, contains('whisper-base'));
      expect(gemmaModels, contains('gemma-3n-E4B-it-int4'));
    });

    test('should have correct model sizes', () {
      final whisperSize = modelManager.getModelSize('whisper-base');
      final gemmaSize = modelManager.getModelSize('gemma-3n-E4B-it-int4');
      
      expect(whisperSize, equals(155189248)); // 147.95 MB
      expect(gemmaSize, equals(4398046511)); // 4.1 GB
    });

    test('should calculate total model size', () {
      final totalSize = modelManager.getTotalModelsSize();
      expect(totalSize, equals(155189248 + 4398046511));
    });
  });
} 