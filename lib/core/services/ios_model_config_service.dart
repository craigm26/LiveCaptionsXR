import 'dart:io';
import 'package:flutter/foundation.dart';
import 'app_logger.dart';

/// Model configuration options for iOS
class IOSModelConfig {
  final bool useMetalDelegate;
  final bool disableXNNPACK;
  final bool enableMemoryMapping;
  final int maxTokens;
  final int maxNumImages;
  final bool enableVerboseLogging;
  final String? customModelPath;

  const IOSModelConfig({
    this.useMetalDelegate = true,
    this.disableXNNPACK = true,
    this.enableMemoryMapping = false,
    this.maxTokens = 1024,
    this.maxNumImages = 1,
    this.enableVerboseLogging = false,
    this.customModelPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'useMetalDelegate': useMetalDelegate,
      'disableXNNPACK': disableXNNPACK,
      'enableMemoryMapping': enableMemoryMapping,
      'maxTokens': maxTokens,
      'maxNumImages': maxNumImages,
      'enableVerboseLogging': enableVerboseLogging,
      'customModelPath': customModelPath,
    };
  }
}

/// iOS-specific model configuration service to handle TensorFlow Lite delegate issues
/// This service helps prevent XNNPACK crashes on iOS by providing alternative configurations
class IOSModelConfigService {
  static final IOSModelConfigService _instance = IOSModelConfigService._internal();
  factory IOSModelConfigService() => _instance;
  IOSModelConfigService._internal();

  final AppLogger _logger = AppLogger.instance;

  /// Get optimal configuration for a specific model
  IOSModelConfig getOptimalConfig(String modelName) {
    if (!Platform.isIOS) {
      return const IOSModelConfig();
    }

    final modelNameLower = modelName.toLowerCase();
    
    // Configuration for large Gemma models
    if (modelNameLower.contains('gemma') && modelNameLower.contains('4b')) {
      return const IOSModelConfig(
        useMetalDelegate: true,
        disableXNNPACK: true,
        enableMemoryMapping: false,
        maxTokens: 512, // Reduced for memory constraints
        maxNumImages: 1,
        enableVerboseLogging: true,
      );
    }
    
    // Configuration for smaller Gemma models
    if (modelNameLower.contains('gemma') && modelNameLower.contains('2b')) {
      return const IOSModelConfig(
        useMetalDelegate: true,
        disableXNNPACK: true,
        enableMemoryMapping: false,
        maxTokens: 1024,
        maxNumImages: 1,
        enableVerboseLogging: false,
      );
    }
    
    // Configuration for Whisper models
    if (modelNameLower.contains('whisper')) {
      return const IOSModelConfig(
        useMetalDelegate: false, // Whisper works fine with CPU
        disableXNNPACK: false,
        enableMemoryMapping: true,
        maxTokens: 2048,
        maxNumImages: 0,
        enableVerboseLogging: false,
      );
    }
    
    // Default configuration
    return const IOSModelConfig(
      useMetalDelegate: true,
      disableXNNPACK: true,
      enableMemoryMapping: false,
      maxTokens: 1024,
      maxNumImages: 1,
      enableVerboseLogging: false,
    );
  }

  /// Get configuration based on device capabilities
  IOSModelConfig getDeviceOptimizedConfig() {
    if (!Platform.isIOS) {
      return const IOSModelConfig();
    }

    // This would ideally use platform channels to get actual device info
    // For now, we'll use conservative settings
    return const IOSModelConfig(
      useMetalDelegate: true,
      disableXNNPACK: true,
      enableMemoryMapping: false,
      maxTokens: 512,
      maxNumImages: 1,
      enableVerboseLogging: true,
    );
  }

  /// Get fallback configuration for when primary config fails
  IOSModelConfig getFallbackConfig() {
    return const IOSModelConfig(
      useMetalDelegate: false,
      disableXNNPACK: true,
      enableMemoryMapping: false,
      maxTokens: 256,
      maxNumImages: 0,
      enableVerboseLogging: true,
    );
  }

  /// Validate if a model configuration is safe for iOS
  bool isConfigurationSafe(IOSModelConfig config) {
    if (!Platform.isIOS) return true;

    // Check for potentially problematic configurations
    if (config.useMetalDelegate && config.enableMemoryMapping) {
      _logger.w('⚠️ Metal delegate with memory mapping may cause issues on iOS');
      return false;
    }

    if (!config.disableXNNPACK && config.maxTokens > 1024) {
      _logger.w('⚠️ XNNPACK with large token count may cause crashes on iOS');
      return false;
    }

    return true;
  }

  /// Get diagnostic information for model loading
  Map<String, dynamic> getDiagnosticInfo() {
    return {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'isIOS': Platform.isIOS,
      'recommendations': {
        'useMetalDelegate': Platform.isIOS,
        'disableXNNPACK': Platform.isIOS,
        'enableMemoryMapping': false,
        'maxModelSizeGB': Platform.isIOS ? 2.0 : 4.0,
        'enableVerboseLogging': Platform.isIOS,
      },
      'knownIssues': Platform.isIOS ? [
        'XNNPACK crashes with large models on iOS 18.5+',
        'Memory mapping issues with Metal delegate',
        'Large fully-connected layers may cause SIGABRT',
      ] : [],
    };
  }

  /// Log configuration for debugging
  void logConfiguration(IOSModelConfig config, String modelName) {
    _logger.i('🔧 Model configuration for $modelName:', category: LogCategory.gemma);
    _logger.i('   - Metal Delegate: ${config.useMetalDelegate}', category: LogCategory.gemma);
    _logger.i('   - Disable XNNPACK: ${config.disableXNNPACK}', category: LogCategory.gemma);
    _logger.i('   - Memory Mapping: ${config.enableMemoryMapping}', category: LogCategory.gemma);
    _logger.i('   - Max Tokens: ${config.maxTokens}', category: LogCategory.gemma);
    _logger.i('   - Max Images: ${config.maxNumImages}', category: LogCategory.gemma);
    _logger.i('   - Verbose Logging: ${config.enableVerboseLogging}', category: LogCategory.gemma);
  }
} 