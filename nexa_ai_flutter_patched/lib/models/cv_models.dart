enum CVCapability {
  ocr,
  detection,
  classification,
}

class CVModelConfig {
  final CVCapability capabilities;
  final String? detModelPath; // Detection model path
  final String? recModelPath; // Recognition model path
  final String? charDictPath; // Character dictionary path
  final String? qnnModelFolderPath; // QNN model folder (NPU)
  final String? qnnLibFolderPath; // QNN library path (NPU)

  CVModelConfig({
    required this.capabilities,
    this.detModelPath,
    this.recModelPath,
    this.charDictPath,
    this.qnnModelFolderPath,
    this.qnnLibFolderPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'capabilities': capabilities.name.toUpperCase(),
      if (detModelPath != null) 'detModelPath': detModelPath,
      if (recModelPath != null) 'recModelPath': recModelPath,
      if (charDictPath != null) 'charDictPath': charDictPath,
      if (qnnModelFolderPath != null) 'qnnModelFolderPath': qnnModelFolderPath,
      if (qnnLibFolderPath != null) 'qnnLibFolderPath': qnnLibFolderPath,
    };
  }
}

class CVCreateInput {
  final String modelName; // "paddleocr", etc.
  final CVModelConfig config;
  final String? pluginId; // "npu", "cpu_gpu", or null

  CVCreateInput({
    required this.modelName,
    required this.config,
    this.pluginId,
  });

  Map<String, dynamic> toMap() {
    return {
      'modelName': modelName,
      'config': config.toMap(),
      if (pluginId != null) 'pluginId': pluginId,
    };
  }
}

class BoundingBox {
  final double x;
  final double y;
  final double width;
  final double height;

  BoundingBox(this.x, this.y, this.width, this.height);

  factory BoundingBox.fromMap(Map<String, dynamic> map) {
    return BoundingBox(
      (map['x'] as num).toDouble(),
      (map['y'] as num).toDouble(),
      (map['width'] as num).toDouble(),
      (map['height'] as num).toDouble(),
    );
  }
}

class CVResult {
  final String text; // Recognized text (OCR)
  final double confidence; // Confidence score (0.0 - 1.0)
  final BoundingBox? boundingBox; // Bounding box coordinates
  final String? label; // Class label (classification)
  final double score; // Detection/classification score

  CVResult({
    required this.text,
    required this.confidence,
    this.boundingBox,
    this.label,
    required this.score,
  });

  factory CVResult.fromMap(Map<String, dynamic> map) {
    return CVResult(
      text: map['text'] as String,
      confidence: (map['confidence'] as num).toDouble(),
      boundingBox: map['boundingBox'] != null
          ? BoundingBox.fromMap(map['boundingBox'] as Map<String, dynamic>)
          : null,
      label: map['label'] as String?,
      score: (map['score'] as num).toDouble(),
    );
  }
}
