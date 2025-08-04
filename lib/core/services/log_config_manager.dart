import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_logger.dart';

/// Manager for persisting and loading log configuration
class LogConfigManager {
  static const String _configKey = 'app_log_config';
  static LogConfigManager? _instance;
  static LogConfigManager get instance => _instance ??= LogConfigManager._();
  
  LogConfigManager._();

  /// Save log configuration to shared preferences
  Future<void> saveConfig(LogConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = _configToJson(config);
      await prefs.setString(_configKey, jsonEncode(configJson));
    } catch (e) {
      // Fail silently to avoid logging loops
    }
  }

  /// Load log configuration from shared preferences
  Future<LogConfig?> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configString = prefs.getString(_configKey);
      if (configString != null) {
        final configJson = jsonDecode(configString) as Map<String, dynamic>;
        return _jsonToConfig(configJson);
      }
    } catch (e) {
      // Fail silently to avoid logging loops
    }
    return null;
  }

  /// Convert LogConfig to JSON-serializable map
  Map<String, dynamic> _configToJson(LogConfig config) {
    return {
      'globalLevel': config.globalLevel.index,
      'categoryLevels': config.categoryLevels.map(
        (category, level) => MapEntry(category.name, level.index),
      ),
      'enableConsoleOutput': config.enableConsoleOutput,
      'enableFileOutput': config.enableFileOutput,
    };
  }

  /// Convert JSON map to LogConfig
  LogConfig _jsonToConfig(Map<String, dynamic> json) {
    final categoryLevels = <LogCategory, LogLevel>{};
    
    if (json['categoryLevels'] is Map) {
      final categoryLevelsJson = json['categoryLevels'] as Map<String, dynamic>;
      for (final entry in categoryLevelsJson.entries) {
        final category = LogCategory.values.firstWhere(
          (c) => c.name == entry.key,
          orElse: () => LogCategory.system,
        );
        final level = LogLevel.values[entry.value as int];
        categoryLevels[category] = level;
      }
    }

    return LogConfig(
      globalLevel: LogLevel.values[json['globalLevel'] as int],
      categoryLevels: categoryLevels,
      enableConsoleOutput: json['enableConsoleOutput'] as bool? ?? true,
      enableFileOutput: json['enableFileOutput'] as bool? ?? false,
    );
  }

  /// Quick configuration presets
  static const LogConfig debugConfig = LogConfig(
    globalLevel: LogLevel.debug,
    enableConsoleOutput: true,
    enableFileOutput: false,
  );

  static const LogConfig productionConfig = LogConfig(
    globalLevel: LogLevel.warning,
    categoryLevels: {
      LogCategory.gemma: LogLevel.error,
      LogCategory.audio: LogLevel.error,
    },
    enableConsoleOutput: false,
    enableFileOutput: false,
  );

  static const LogConfig minimalConfig = LogConfig(
    globalLevel: LogLevel.info,
    categoryLevels: {
      LogCategory.gemma: LogLevel.warning,
      LogCategory.audio: LogLevel.warning,
      LogCategory.ar: LogLevel.info,
      LogCategory.captions: LogLevel.info,
    },
    enableConsoleOutput: true,
    enableFileOutput: false,
  );
}