class DeviceInfo {
  final String deviceModel;
  final String deviceManufacturer;
  final String chipset;
  final int androidVersion;
  final bool hasNpu;
  final bool hasGpu;
  final bool hasCpu;
  final List<String> supportedPlugins;
  final String performanceLevel;

  DeviceInfo({
    required this.deviceModel,
    required this.deviceManufacturer,
    required this.chipset,
    required this.androidVersion,
    required this.hasNpu,
    required this.hasGpu,
    required this.hasCpu,
    required this.supportedPlugins,
    required this.performanceLevel,
  });

  factory DeviceInfo.fromMap(Map<String, dynamic> map) {
    return DeviceInfo(
      deviceModel: map['deviceModel'] as String,
      deviceManufacturer: map['deviceManufacturer'] as String,
      chipset: map['chipset'] as String,
      androidVersion: map['androidVersion'] as int,
      hasNpu: map['hasNpu'] as bool,
      hasGpu: map['hasGpu'] as bool,
      hasCpu: map['hasCpu'] as bool,
      supportedPlugins:
          (map['supportedPlugins'] as List<dynamic>).cast<String>(),
      performanceLevel: map['performanceLevel'] as String,
    );
  }

  String get performanceLevelText {
    switch (performanceLevel) {
      case 'fast':
        return 'High Performance';
      case 'medium':
        return 'Medium Performance';
      case 'slow':
        return 'Low Performance';
      default:
        return 'Unknown';
    }
  }

  String get chipsetFriendlyName {
    // Convert chipset code to friendly name
    final chipsetMap = {
      'SM8650': 'Snapdragon 8 Gen 3',
      'SM8750': 'Snapdragon 8 Gen 4',
      'SM8550': 'Snapdragon 8 Gen 2',
      'SM8450': 'Snapdragon 8 Gen 1',
      'SM8350': 'Snapdragon 888',
      'SM8250': 'Snapdragon 865',
      'msmnile': 'Snapdragon 855',
      'lito': 'Snapdragon 765',
      'SM7325': 'Snapdragon 778G',
      'SM7350': 'Snapdragon 780G',
    };

    return chipsetMap[chipset] ?? chipset;
  }
}

class ModelCompatibility {
  final String modelId;
  final bool isCompatible;
  final String requiredPlugin;
  final String availablePlugin;
  final String expectedSpeed;
  final String recommendation;
  final String chipset;
  final bool hasNpu;

  ModelCompatibility({
    required this.modelId,
    required this.isCompatible,
    required this.requiredPlugin,
    required this.availablePlugin,
    required this.expectedSpeed,
    required this.recommendation,
    required this.chipset,
    required this.hasNpu,
  });

  factory ModelCompatibility.fromMap(Map<String, dynamic> map) {
    return ModelCompatibility(
      modelId: map['modelId'] as String,
      isCompatible: map['isCompatible'] as bool,
      requiredPlugin: map['requiredPlugin'] as String,
      availablePlugin: map['availablePlugin'] as String,
      expectedSpeed: map['expectedSpeed'] as String,
      recommendation: map['recommendation'] as String,
      chipset: map['chipset'] as String,
      hasNpu: map['hasNpu'] as bool,
    );
  }

  String get speedText {
    switch (expectedSpeed) {
      case 'fast':
        return 'Fast';
      case 'medium':
        return 'Medium';
      case 'slow':
        return 'Slow';
      case 'not_supported':
        return 'Not Supported';
      default:
        return 'Unknown';
    }
  }

  String get compatibilityEmoji {
    if (!isCompatible) return '❌';
    switch (expectedSpeed) {
      case 'fast':
        return '⚡';
      case 'medium':
        return '✓';
      case 'slow':
        return '🐢';
      default:
        return '?';
    }
  }
}
