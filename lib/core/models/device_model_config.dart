import 'dart:io';

import 'package:flutter/services.dart';

import '../services/app_logger.dart';
import '../services/nexa_asr_service.dart';

/// Device form factor for model selection
enum DeviceFormFactor {
  phone,
  tablet,
  xrHeadset,    // Samsung Galaxy XR, Meta Quest, etc.
  arGlasses,    // Samsung glasses, Ray-Ban Meta, etc.
  unknown,
}

/// Device tier based on capabilities
enum DeviceTier {
  flagship,     // 8+ GB RAM, latest Snapdragon (8 Gen 3/4)
  highEnd,      // 6-8 GB RAM, recent Snapdragon (8 Gen 1/2)
  midRange,     // 4-6 GB RAM, mid-tier Snapdragon (7 series)
  lowEnd,       // <4 GB RAM, older/budget chipsets
  unknown,
}

/// Qualcomm chipset family for NPU optimization
enum SnapdragonFamily {
  gen4,         // Snapdragon 8 Elite (8 Gen 4) - Latest, best NPU
  gen3,         // Snapdragon 8 Gen 3 - Excellent NPU
  gen2,         // Snapdragon 8 Gen 2 - Great NPU
  gen1,         // Snapdragon 8 Gen 1 - Good NPU
  series7,      // Snapdragon 7 series - Mid-tier NPU
  series6,      // Snapdragon 6 series - Basic NPU
  xrPlatform,   // Snapdragon XR platform
  other,        // Non-Snapdragon or unknown
}

/// Model size category
enum ModelSize {
  tiny,         // <100 MB - Minimal memory, fastest
  small,        // 100-500 MB - Low memory, fast
  medium,       // 500 MB - 2 GB - Balanced
  large,        // 2-4 GB - High quality
  xlarge,       // 4+ GB - Maximum quality
}

/// Configuration for a specific AI model
class ModelSpec {
  final String name; // Download ID (e.g. 'parakeet-tdt-0.6b-v3-npu')
  final String displayName;
  final ModelSize size;
  final int estimatedSizeMb;
  final bool supportsNpu;
  final bool supportsVision;
  final String? downloadUrl;
  final String? checksum;

  /// Short model name for Nexa SDK NPU plugin (e.g. 'parakeet').
  /// The NPU JNI uses this to look up the model graph internally.
  /// If null, falls back to [name] (for non-Nexa models like Whisper/Gemma).
  final String? pluginModelName;

  const ModelSpec({
    required this.name,
    required this.displayName,
    required this.size,
    required this.estimatedSizeMb,
    this.supportsNpu = true,
    this.supportsVision = false,
    this.downloadUrl,
    this.checksum,
    this.pluginModelName,
  });

  /// Returns the name to pass as model_name in Nexa SDK create() calls.
  String get nexaModelName => pluginModelName ?? name;

  @override
  String toString() => 'ModelSpec($name, ${size.name}, ${estimatedSizeMb}MB)';
}

/// Device-specific model configuration
class DeviceModelConfig {
  final String deviceId;
  final DeviceFormFactor formFactor;
  final DeviceTier tier;
  final SnapdragonFamily snapdragonFamily;
  final int availableRamMb;
  final bool npuAvailable;

  // Selected models for this device
  final ModelSpec asrModel;
  final ModelSpec llmModel;
  final List<ModelSpec> asrFallbacks;
  final List<ModelSpec> llmFallbacks;

  const DeviceModelConfig({
    required this.deviceId,
    required this.formFactor,
    required this.tier,
    required this.snapdragonFamily,
    required this.availableRamMb,
    required this.npuAvailable,
    required this.asrModel,
    required this.llmModel,
    this.asrFallbacks = const [],
    this.llmFallbacks = const [],
  });

  /// Whether this device can run multimodal (vision) models
  bool get canRunVisionModels =>
      tier == DeviceTier.flagship &&
      availableRamMb >= 6000 &&
      llmModel.supportsVision;

  /// Whether NPU acceleration should be preferred
  bool get preferNpu =>
      npuAvailable &&
      snapdragonFamily != SnapdragonFamily.other;

  /// Get the best inference mode for this device
  NexaInferenceMode get recommendedInferenceMode {
    if (npuAvailable && snapdragonFamily != SnapdragonFamily.other) {
      return NexaInferenceMode.npu;
    } else if (tier == DeviceTier.flagship || tier == DeviceTier.highEnd) {
      return NexaInferenceMode.gpu;
    }
    return NexaInferenceMode.cpu;
  }

  @override
  String toString() =>
      'DeviceModelConfig($deviceId, ${formFactor.name}, ${tier.name}, '
      'ASR: ${asrModel.name}, LLM: ${llmModel.name})';
}

/// Registry of available models and device configurations
class DeviceModelRegistry {
  static final AppLogger _logger = AppLogger.instance;

  // Method channel for native device info
  static const MethodChannel _deviceChannel =
      MethodChannel('live_captions_xr/nexa_asr');

  // Cached device config
  DeviceModelConfig? _cachedConfig;

  // ============================================
  // ASR Model Definitions
  // ============================================

  // NOTE: There is only ONE Parakeet model in the Nexa SDK.
  // All tiers that use Nexa ASR must use asrParakeet.
  // These aliases exist for backward compatibility but point to the same model.
  static const ModelSpec asrParakeetTiny = asrParakeet;
  static const ModelSpec asrParakeetSmall = asrParakeet;

  static const ModelSpec asrParakeet = ModelSpec(
    name: 'parakeet-tdt-0.6b-v3-npu',
    displayName: 'Parakeet TDT 0.6B',
    size: ModelSize.medium,
    estimatedSizeMb: 600,
    supportsNpu: true,
    pluginModelName: 'parakeet', // Short name for Nexa NPU plugin JNI
  );

  static const ModelSpec asrWhisperTiny = ModelSpec(
    name: 'whisper-tiny',
    displayName: 'Whisper Tiny',
    size: ModelSize.tiny,
    estimatedSizeMb: 75,
    supportsNpu: false,
  );

  static const ModelSpec asrWhisperBase = ModelSpec(
    name: 'whisper-base',
    displayName: 'Whisper Base',
    size: ModelSize.small,
    estimatedSizeMb: 141,
    supportsNpu: false,
  );

  static const ModelSpec asrWhisperSmall = ModelSpec(
    name: 'whisper-small',
    displayName: 'Whisper Small',
    size: ModelSize.medium,
    estimatedSizeMb: 466,
    supportsNpu: false,
  );

  // ============================================
  // LLM Model Definitions
  // ============================================

  // LFM2 1.2B — the only small chat model in the Nexa SDK
  static const ModelSpec llmLfm2 = ModelSpec(
    name: 'LFM2-1.2B-npu',
    displayName: 'LFM2 1.2B NPU',
    size: ModelSize.medium,
    estimatedSizeMb: 750,
    supportsNpu: true,
    supportsVision: false,
    pluginModelName: 'LFM2-1.2B', // Short name for Nexa NPU plugin JNI
  );

  // Backward-compat aliases — all point to LFM2 since Granite doesn't exist in SDK
  static const ModelSpec llmGraniteTiny = llmLfm2;
  static const ModelSpec llmGraniteSmall = llmLfm2;
  static const ModelSpec llmGraniteMedium = llmLfm2;

  static const ModelSpec llmOmniNeural = ModelSpec(
    name: 'OmniNeural-4B',
    displayName: 'OmniNeural 4B',
    size: ModelSize.large,
    estimatedSizeMb: 4000,
    supportsNpu: true,
    supportsVision: true,
    pluginModelName: 'OmniNeural-4B', // Short name for Nexa NPU plugin JNI
  );

  static const ModelSpec llmGemma3n = ModelSpec(
    name: 'gemma-3n-e4b-it',
    displayName: 'Gemma 3n',
    size: ModelSize.large,
    estimatedSizeMb: 4100,
    supportsNpu: false,
    supportsVision: true,
  );

  static const ModelSpec llmGemma3nSmall = ModelSpec(
    name: 'gemma-3n-e2b-it',
    displayName: 'Gemma 3n Small',
    size: ModelSize.medium,
    estimatedSizeMb: 2000,
    supportsNpu: false,
    supportsVision: true,
  );

  // ============================================
  // Device Configuration Presets
  // ============================================

  /// Flagship phone configuration (Samsung S24 Ultra, Pixel 9 Pro, etc.)
  static DeviceModelConfig get flagshipPhone => const DeviceModelConfig(
    deviceId: 'flagship_phone',
    formFactor: DeviceFormFactor.phone,
    tier: DeviceTier.flagship,
    snapdragonFamily: SnapdragonFamily.gen3,
    availableRamMb: 12000,
    npuAvailable: true,
    asrModel: asrParakeet,
    llmModel: llmOmniNeural,
    asrFallbacks: [asrWhisperSmall],
    llmFallbacks: [llmLfm2, llmGemma3n],
  );

  /// High-end phone configuration
  static DeviceModelConfig get highEndPhone => const DeviceModelConfig(
    deviceId: 'high_end_phone',
    formFactor: DeviceFormFactor.phone,
    tier: DeviceTier.highEnd,
    snapdragonFamily: SnapdragonFamily.gen2,
    availableRamMb: 8000,
    npuAvailable: true,
    asrModel: asrParakeet,
    llmModel: llmOmniNeural,
    asrFallbacks: [asrWhisperBase],
    llmFallbacks: [llmLfm2, llmGemma3nSmall],
  );

  /// Mid-range phone configuration
  static DeviceModelConfig get midRangePhone => const DeviceModelConfig(
    deviceId: 'mid_range_phone',
    formFactor: DeviceFormFactor.phone,
    tier: DeviceTier.midRange,
    snapdragonFamily: SnapdragonFamily.series7,
    availableRamMb: 6000,
    npuAvailable: true,
    asrModel: asrParakeet,
    llmModel: llmLfm2,
    asrFallbacks: [asrWhisperTiny],
    llmFallbacks: [],
  );

  /// Low-end phone configuration
  static DeviceModelConfig get lowEndPhone => const DeviceModelConfig(
    deviceId: 'low_end_phone',
    formFactor: DeviceFormFactor.phone,
    tier: DeviceTier.lowEnd,
    snapdragonFamily: SnapdragonFamily.series6,
    availableRamMb: 4000,
    npuAvailable: false,
    asrModel: asrWhisperTiny,
    llmModel: llmGraniteTiny,
    asrFallbacks: [],
    llmFallbacks: [],
  );

  /// Samsung Galaxy XR headset configuration
  static DeviceModelConfig get samsungGalaxyXr => const DeviceModelConfig(
    deviceId: 'samsung_galaxy_xr',
    formFactor: DeviceFormFactor.xrHeadset,
    tier: DeviceTier.flagship,
    snapdragonFamily: SnapdragonFamily.xrPlatform,
    availableRamMb: 8000,
    npuAvailable: true,
    asrModel: asrParakeet,
    llmModel: llmOmniNeural,
    asrFallbacks: [],
    llmFallbacks: [llmLfm2],
  );

  /// Samsung AR glasses configuration
  static DeviceModelConfig get samsungArGlasses => const DeviceModelConfig(
    deviceId: 'samsung_ar_glasses',
    formFactor: DeviceFormFactor.arGlasses,
    tier: DeviceTier.midRange,
    snapdragonFamily: SnapdragonFamily.xrPlatform,
    availableRamMb: 4000,
    npuAvailable: true,
    asrModel: asrParakeet,
    llmModel: llmLfm2,
    asrFallbacks: [asrWhisperTiny],
    llmFallbacks: [],
  );

  /// Non-Snapdragon Android device (uses Whisper + Gemma fallback)
  static DeviceModelConfig get genericAndroid => const DeviceModelConfig(
    deviceId: 'generic_android',
    formFactor: DeviceFormFactor.phone,
    tier: DeviceTier.midRange,
    snapdragonFamily: SnapdragonFamily.other,
    availableRamMb: 6000,
    npuAvailable: false,
    asrModel: asrWhisperBase,
    llmModel: llmGemma3nSmall,
    asrFallbacks: [asrWhisperTiny],
    llmFallbacks: [],
  );

  // ============================================
  // Device Detection and Configuration
  // ============================================

  /// Get the optimal model configuration for the current device
  Future<DeviceModelConfig> getDeviceConfig() async {
    if (_cachedConfig != null) {
      return _cachedConfig!;
    }

    if (!Platform.isAndroid) {
      _logger.w('DeviceModelRegistry only supports Android');
      _cachedConfig = genericAndroid;
      return _cachedConfig!;
    }

    try {
      final deviceInfo = await _getDeviceInfo();
      _cachedConfig = _selectConfigForDevice(deviceInfo);
      _logger.i('📱 Device config selected: ${_cachedConfig!.deviceId}');
      _logger.i('   ASR: ${_cachedConfig!.asrModel.name}');
      _logger.i('   LLM: ${_cachedConfig!.llmModel.name}');
      _logger.i('   NPU: ${_cachedConfig!.npuAvailable}');
      return _cachedConfig!;
    } catch (e, stackTrace) {
      _logger.e('Failed to detect device, using generic config',
          error: e, stackTrace: stackTrace);
      _cachedConfig = genericAndroid;
      return _cachedConfig!;
    }
  }

  /// Get raw device info from native channel
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      final result = await _deviceChannel.invokeMethod<Map<dynamic, dynamic>>('getDeviceInfo');
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } catch (e) {
      _logger.w('Could not get device info from native channel', error: e);
    }

    // Fallback to basic info
    return {
      'manufacturer': 'unknown',
      'model': 'unknown',
      'chipset': 'unknown',
      'sdkVersion': 0,
      'totalRam': 4000,
      'npuAvailable': false,
    };
  }

  /// Select the best configuration for the detected device
  DeviceModelConfig _selectConfigForDevice(Map<String, dynamic> deviceInfo) {
    final manufacturer = (deviceInfo['manufacturer'] as String?)?.toLowerCase() ?? '';
    final model = (deviceInfo['model'] as String?)?.toLowerCase() ?? '';
    final chipset = (deviceInfo['chipset'] as String?)?.toLowerCase() ?? '';
    final totalRam = deviceInfo['totalRam'] as int? ?? 4000;
    final npuAvailable = deviceInfo['npuAvailable'] as bool? ?? false;

    _logger.d('Device detection: manufacturer=$manufacturer, model=$model, '
        'chipset=$chipset, ram=${totalRam}MB, npu=$npuAvailable');

    // Check for XR devices first
    if (_isXrHeadset(manufacturer, model)) {
      return samsungGalaxyXr;
    }
    if (_isArGlasses(manufacturer, model)) {
      return samsungArGlasses;
    }

    // Check Snapdragon generation
    final snapdragonFamily = _detectSnapdragonFamily(chipset);

    // Select based on device tier
    // If NPU is detected but chipset family is unknown, treat as high-end
    if (!npuAvailable && snapdragonFamily == SnapdragonFamily.other) {
      return genericAndroid;
    }
    if (npuAvailable && snapdragonFamily == SnapdragonFamily.other) {
      _logger.w('NPU detected but chipset family unknown (chipset=$chipset). '
          'Treating as high-end device.');
      return highEndPhone;
    }

    // Determine tier based on RAM and chipset
    final tier = _determineTier(totalRam, snapdragonFamily);

    switch (tier) {
      case DeviceTier.flagship:
        return flagshipPhone;
      case DeviceTier.highEnd:
        return highEndPhone;
      case DeviceTier.midRange:
        return midRangePhone;
      case DeviceTier.lowEnd:
        return lowEndPhone;
      case DeviceTier.unknown:
        return genericAndroid;
    }
  }

  bool _isXrHeadset(String manufacturer, String model) {
    // Samsung Galaxy XR
    if (manufacturer.contains('samsung') &&
        (model.contains('xr') || model.contains('quest'))) {
      return true;
    }
    // Meta Quest
    if (manufacturer.contains('meta') || manufacturer.contains('oculus')) {
      return true;
    }
    return false;
  }

  bool _isArGlasses(String manufacturer, String model) {
    // Samsung AR glasses
    if (manufacturer.contains('samsung') && model.contains('glass')) {
      return true;
    }
    // Ray-Ban Meta
    if (model.contains('ray-ban') || model.contains('rayban')) {
      return true;
    }
    return false;
  }

  SnapdragonFamily _detectSnapdragonFamily(String chipset) {
    final chip = chipset.toLowerCase();

    // Snapdragon 8 Elite (aka 8 Gen 4) — codename "pineapple", board "QRD8750"
    if (chip.contains('8 elite') || chip.contains('8 gen 4') ||
        chip.contains('sm8750') || chip.contains('sm8735') ||
        chip.contains('pineapple') || chip.contains('qrd8750')) {
      return SnapdragonFamily.gen4;
    }
    // Snapdragon 8 Gen 3 — codename "kalama"
    if (chip.contains('8 gen 3') || chip.contains('sm8650') ||
        chip.contains('kalama') || chip.contains('qrd8650')) {
      return SnapdragonFamily.gen3;
    }
    // Snapdragon 8 Gen 2 — codename "waipio"
    if (chip.contains('8 gen 2') || chip.contains('sm8550') ||
        chip.contains('waipio') || chip.contains('qrd8550')) {
      return SnapdragonFamily.gen2;
    }
    // Snapdragon 8 Gen 1 — codename "taro"
    if (chip.contains('8 gen 1') || chip.contains('sm8450') ||
        chip.contains('taro') || chip.contains('qrd8450')) {
      return SnapdragonFamily.gen1;
    }
    // Snapdragon 7 series
    if (chip.contains('7 gen') || chip.contains('sm7')) {
      return SnapdragonFamily.series7;
    }
    // Snapdragon 6 series
    if (chip.contains('6 gen') || chip.contains('sm6')) {
      return SnapdragonFamily.series6;
    }
    // XR Platform
    if (chip.contains('xr') || chip.contains('snapdragon xr')) {
      return SnapdragonFamily.xrPlatform;
    }
    // Generic Qualcomm identifier (e.g. QDC boards reporting just "qcom")
    // Treat as gen4 since QDC reference boards are typically latest-gen
    if (chip == 'qcom' || chip.contains('qualcomm')) {
      return SnapdragonFamily.gen4;
    }

    return SnapdragonFamily.other;
  }

  DeviceTier _determineTier(int ramMb, SnapdragonFamily family) {
    // Flagship: 8+ GB RAM and Gen 3/4 chipset
    if (ramMb >= 8000 &&
        (family == SnapdragonFamily.gen4 || family == SnapdragonFamily.gen3)) {
      return DeviceTier.flagship;
    }
    // High-end: 6+ GB RAM and Gen 1/2 chipset
    if (ramMb >= 6000 &&
        (family == SnapdragonFamily.gen2 || family == SnapdragonFamily.gen1)) {
      return DeviceTier.highEnd;
    }
    // Mid-range: 4+ GB RAM
    if (ramMb >= 4000) {
      return DeviceTier.midRange;
    }
    // Low-end
    return DeviceTier.lowEnd;
  }

  /// Clear cached configuration (useful for testing)
  void clearCache() {
    _cachedConfig = null;
    _logger.d('DeviceModelRegistry cache cleared');
  }

  /// Get all available ASR models
  static List<ModelSpec> get allAsrModels => [
    asrParakeetTiny,
    asrParakeetSmall,
    asrParakeet,
    asrWhisperTiny,
    asrWhisperBase,
    asrWhisperSmall,
  ];

  /// Get all available LLM models
  static List<ModelSpec> get allLlmModels => [
    llmGraniteTiny,
    llmGraniteSmall,
    llmGraniteMedium,
    llmOmniNeural,
    llmGemma3n,
    llmGemma3nSmall,
  ];

  /// Get models that support NPU acceleration
  static List<ModelSpec> get npuModels => [
    ...allAsrModels.where((m) => m.supportsNpu),
    ...allLlmModels.where((m) => m.supportsNpu),
  ];

  /// Get models that support vision/multimodal
  static List<ModelSpec> get visionModels =>
      allLlmModels.where((m) => m.supportsVision).toList();
}
