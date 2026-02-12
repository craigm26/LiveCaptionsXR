import 'dart:io';

import 'package:flutter/services.dart';

import '../services/app_logger.dart';

/// Utility class for detecting Nexa SDK compatibility and NPU support
///
/// This class helps identify whether the current device supports:
/// - Nexa SDK (Android only)
/// - Qualcomm Hexagon NPU acceleration
/// - Specific Snapdragon chipsets optimized for on-device AI
///
/// For the Qualcomm x Nexa On-Device AI Bounty Program.
class NexaDeviceUtils {
  static final AppLogger _logger = AppLogger.instance;

  // Method channel for native device info
  static const MethodChannel _channel =
      MethodChannel('live_captions_xr/nexa_asr');

  /// Supported Snapdragon chipsets for NPU acceleration
  /// These chipsets have optimized Qualcomm Hexagon NPU support
  static const List<String> npuSupportedChipsets = [
    'SM8750', // Snapdragon 8 Elite (aka 8 Gen 4)
    'SM8735', // Snapdragon 8s Elite
    'SM8650', // Snapdragon 8 Gen 3
    'SM8550', // Snapdragon 8 Gen 2
    'SM8475', // Snapdragon 8+ Gen 1
    'SM8450', // Snapdragon 8 Gen 1
  ];

  /// Marketing names for supported chipsets (for user-friendly display)
  static const Map<String, String> chipsetMarketingNames = {
    'SM8750': 'Snapdragon 8 Elite',
    'SM8735': 'Snapdragon 8s Elite',
    'SM8650': 'Snapdragon 8 Gen 3',
    'SM8550': 'Snapdragon 8 Gen 2',
    'SM8475': 'Snapdragon 8+ Gen 1',
    'SM8450': 'Snapdragon 8 Gen 1',
  };

  /// Check if Nexa SDK is available on this platform
  static bool get isNexaAvailable => Platform.isAndroid;

  /// Check if the current device supports NPU acceleration
  static Future<bool> isNpuSupported() async {
    if (!Platform.isAndroid) {
      _logger.d('NPU not supported: not Android platform');
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('isNpuAvailable');
      _logger.d('NPU availability check: $result');
      return result ?? false;
    } catch (e) {
      _logger.e('Failed to check NPU availability', error: e);
      return false;
    }
  }

  /// Get detailed device information for Nexa compatibility
  static Future<NexaDeviceCompatibility?> getDeviceCompatibility() async {
    if (!Platform.isAndroid) {
      return NexaDeviceCompatibility(
        isAndroid: false,
        isNexaAvailable: false,
        isNpuSupported: false,
        chipset: 'N/A (${Platform.operatingSystem})',
        recommendedInferenceMode: 'N/A',
        deviceModel: 'N/A',
      );
    }

    try {
      final result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('getDeviceInfo');

      if (result != null) {
        final chipset = result['chipset'] as String? ?? 'Unknown';
        final npuAvailable = result['npuAvailable'] as bool? ?? false;
        final gpuAvailable = result['gpuAvailable'] as bool? ?? false;

        String recommendedMode;
        if (npuAvailable) {
          recommendedMode = 'NPU (Qualcomm Hexagon)';
        } else if (gpuAvailable) {
          recommendedMode = 'GPU';
        } else {
          recommendedMode = 'CPU';
        }

        return NexaDeviceCompatibility(
          isAndroid: true,
          isNexaAvailable: true,
          isNpuSupported: npuAvailable,
          chipset: _getChipsetDisplayName(chipset),
          recommendedInferenceMode: recommendedMode,
          deviceModel: '${result['manufacturer']} ${result['model']}',
          manufacturer: result['manufacturer'] as String?,
          model: result['model'] as String?,
          hardware: result['hardware'] as String?,
          sdkVersion: result['sdkVersion'] as int?,
        );
      }

      return null;
    } catch (e) {
      _logger.e('Failed to get device compatibility', error: e);
      return null;
    }
  }

  /// Get user-friendly chipset display name
  static String _getChipsetDisplayName(String chipset) {
    for (final entry in chipsetMarketingNames.entries) {
      if (chipset.contains(entry.key)) {
        return '${entry.value} ($chipset)';
      }
    }
    return chipset;
  }

  /// Check if device is optimal for Nexa SDK (has NPU)
  static Future<bool> isOptimalDevice() async {
    if (!Platform.isAndroid) return false;
    return await isNpuSupported();
  }

  /// Get a recommendation message for the user
  static Future<String> getRecommendationMessage() async {
    if (!Platform.isAndroid) {
      return 'Nexa SDK is only available on Android devices. '
          'On iOS, we use Apple Speech Recognition instead.';
    }

    final npuSupported = await isNpuSupported();
    if (npuSupported) {
      return 'Your device supports Qualcomm Hexagon NPU acceleration! '
          'LiveCaptionsXR will use NPU for fast, efficient on-device AI.';
    } else {
      return 'Your device will use GPU/CPU for on-device AI. '
          'For best performance, use a device with Snapdragon 8 Gen 1 or newer.';
    }
  }
}

/// Device compatibility information for Nexa SDK
class NexaDeviceCompatibility {
  final bool isAndroid;
  final bool isNexaAvailable;
  final bool isNpuSupported;
  final String chipset;
  final String recommendedInferenceMode;
  final String deviceModel;
  final String? manufacturer;
  final String? model;
  final String? hardware;
  final int? sdkVersion;

  const NexaDeviceCompatibility({
    required this.isAndroid,
    required this.isNexaAvailable,
    required this.isNpuSupported,
    required this.chipset,
    required this.recommendedInferenceMode,
    required this.deviceModel,
    this.manufacturer,
    this.model,
    this.hardware,
    this.sdkVersion,
  });

  /// Check if device is optimal for on-device AI
  bool get isOptimal => isNpuSupported;

  /// Get performance tier (1 = best, 3 = fallback)
  int get performanceTier {
    if (isNpuSupported) return 1;
    if (isAndroid) return 2; // GPU/CPU on Android
    return 3; // Other platforms
  }

  /// Get performance description
  String get performanceDescription {
    switch (performanceTier) {
      case 1:
        return 'Excellent - NPU accelerated';
      case 2:
        return 'Good - GPU/CPU inference';
      default:
        return 'Standard - Platform-specific';
    }
  }

  @override
  String toString() {
    return 'NexaDeviceCompatibility('
        'device: $deviceModel, '
        'chipset: $chipset, '
        'npu: $isNpuSupported, '
        'mode: $recommendedInferenceMode)';
  }

  /// Convert to map for analytics/logging
  Map<String, dynamic> toMap() {
    return {
      'isAndroid': isAndroid,
      'isNexaAvailable': isNexaAvailable,
      'isNpuSupported': isNpuSupported,
      'chipset': chipset,
      'recommendedInferenceMode': recommendedInferenceMode,
      'deviceModel': deviceModel,
      'manufacturer': manufacturer,
      'model': model,
      'hardware': hardware,
      'sdkVersion': sdkVersion,
      'performanceTier': performanceTier,
    };
  }
}
