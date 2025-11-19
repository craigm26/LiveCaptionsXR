import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_logger.dart';
import '../models/user_settings.dart';

/// Service for managing HuggingFace token retrieval with priority order:
/// 1. UserSettings (from SharedPreferences)
/// 2. .env file
/// 3. null
class HuggingFaceTokenService {
  static final AppLogger _logger = AppLogger.instance;
  static HuggingFaceTokenService? _instance;
  static bool _envLoadAttempted = false;

  static HuggingFaceTokenService get instance =>
      _instance ??= HuggingFaceTokenService._();

  HuggingFaceTokenService._();

  /// Get HuggingFace token with priority order:
  /// 1. UserSettings (from SharedPreferences)
  /// 2. .env file (HUGGINGFACE_TOKEN)
  /// 3. null
  Future<String?> getToken() async {
    try {
      // Priority 1: Check UserSettings
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('user_settings');
      if (settingsJson != null) {
        try {
          final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
          final settings = UserSettings.fromJson(settingsMap);
          if (settings.hasHuggingFaceToken) {
            _logger.d('🔑 HuggingFace token found in UserSettings',
                category: LogCategory.system);
            return settings.huggingFaceToken;
          }
        } catch (e) {
          _logger.w('⚠️ Failed to parse UserSettings for token: $e',
              category: LogCategory.system);
        }
      }

      await _ensureEnvLoaded();

      // Priority 2: Check .env file
      final envToken = dotenv.env['HUGGINGFACE_TOKEN'];
      if (envToken != null && envToken.isNotEmpty) {
        _logger.d('🔑 HuggingFace token found in .env file',
            category: LogCategory.system);
        return envToken;
      }

      _logger.d('⚠️ No HuggingFace token found', category: LogCategory.system);
      return null;
    } catch (e, stackTrace) {
      _logger.e('❌ Error retrieving HuggingFace token',
          category: LogCategory.system, error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get token synchronously from UserSettings (if already loaded)
  /// This is a helper for cases where settings are already in memory
  String? getTokenFromSettings(UserSettings? settings) {
    if (settings?.hasHuggingFaceToken == true) {
      return settings!.huggingFaceToken;
    }
    return null;
  }

  /// Get token from .env file synchronously
  String? getTokenFromEnv() {
    if (!dotenv.isInitialized) {
      return null;
    }
    return dotenv.env['HUGGINGFACE_TOKEN'];
  }

  /// Validate token format (basic validation)
  bool isValidTokenFormat(String? token) {
    if (token == null || token.isEmpty) {
      return false;
    }
    // HuggingFace tokens are typically alphanumeric strings
    // Basic validation: at least 10 characters, contains letters and numbers
    return token.length >= 10 &&
        RegExp(r'[a-zA-Z]').hasMatch(token) &&
        RegExp(r'[0-9]').hasMatch(token);
  }

  /// Check if token is available (from any source)
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> _ensureEnvLoaded() async {
    if (dotenv.isInitialized || _envLoadAttempted) {
      return;
    }
    _envLoadAttempted = true;
    try {
      await dotenv.load(fileName: ".env");
      _logger.d('📄 Loaded .env file for HuggingFace tokens',
          category: LogCategory.system);
    } catch (e, stackTrace) {
      _logger.w(
        '⚠️ Failed to load .env file for HuggingFace tokens',
        category: LogCategory.system,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
