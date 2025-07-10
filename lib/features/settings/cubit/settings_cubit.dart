import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/debug_logger_service.dart';
import '../../../core/services/debug_capturing_logger.dart';

class SettingsState {
  final bool debugLoggingEnabled;
  final bool notificationsEnabled;
  final bool hapticsEnabled;
  final double textSize;
  final String language;

  const SettingsState({
    this.debugLoggingEnabled = false,
    this.notificationsEnabled = true,
    this.hapticsEnabled = true,
    this.textSize = 16.0,
    this.language = 'en',
  });

  SettingsState copyWith({
    bool? debugLoggingEnabled,
    bool? notificationsEnabled,
    bool? hapticsEnabled,
    double? textSize,
    String? language,
  }) {
    return SettingsState(
      debugLoggingEnabled: debugLoggingEnabled ?? this.debugLoggingEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      textSize: textSize ?? this.textSize,
      language: language ?? this.language,
    );
  }
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState()) {
    _loadSettings();
  }

  static final DebugCapturingLogger _logger = DebugCapturingLogger();

  final DebugLoggerService _debugLogger = DebugLoggerService();

  /// Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      _logger.i('⚙️ Loading app settings...');
      final prefs = await SharedPreferences.getInstance();

      final debugLoggingEnabled =
          prefs.getBool('debug_logging_enabled') ?? false;
      final notificationsEnabled =
          prefs.getBool('notifications_enabled') ?? true;
      final hapticsEnabled = prefs.getBool('haptics_enabled') ?? true;
      final textSize = prefs.getDouble('text_size') ?? 16.0;
      final language = prefs.getString('language') ?? 'en';

      emit(SettingsState(
        debugLoggingEnabled: debugLoggingEnabled,
        notificationsEnabled: notificationsEnabled,
        hapticsEnabled: hapticsEnabled,
        textSize: textSize,
        language: language,
      ));

      // Initialize debug logging based on saved setting
      _debugLogger.setEnabled(debugLoggingEnabled);

      _logger.i('✅ Settings loaded successfully');
      _logger.d('🔧 Debug logging: $debugLoggingEnabled');
      _logger.d('🔔 Notifications: $notificationsEnabled');
      _logger.d('📳 Haptics: $hapticsEnabled');
      _logger.d('📝 Text size: $textSize');
      _logger.d('🌍 Language: $language');
    } catch (e, stackTrace) {
      _logger.e('❌ Error loading settings', error: e, stackTrace: stackTrace);
    }
  }

  /// Toggle debug logging on/off
  Future<void> toggleDebugLogging() async {
    try {
      final newValue = !state.debugLoggingEnabled;
      _logger.i('🐛 Toggling debug logging: $newValue');

      emit(state.copyWith(debugLoggingEnabled: newValue));
      _debugLogger.setEnabled(newValue);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('debug_logging_enabled', newValue);

      _logger.i('✅ Debug logging ${newValue ? "enabled" : "disabled"}');
    } catch (e, stackTrace) {
      _logger.e('❌ Error toggling debug logging',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Toggle notifications on/off
  Future<void> toggleNotifications() async {
    try {
      final newValue = !state.notificationsEnabled;
      _logger.i('🔔 Toggling notifications: $newValue');

      emit(state.copyWith(notificationsEnabled: newValue));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', newValue);

      _logger.i('✅ Notifications ${newValue ? "enabled" : "disabled"}');
    } catch (e, stackTrace) {
      _logger.e('❌ Error toggling notifications',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Toggle haptic feedback on/off
  Future<void> toggleHaptics() async {
    try {
      final newValue = !state.hapticsEnabled;
      _logger.i('📳 Toggling haptics: $newValue');

      emit(state.copyWith(hapticsEnabled: newValue));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('haptics_enabled', newValue);

      _logger.i('✅ Haptics ${newValue ? "enabled" : "disabled"}');
    } catch (e, stackTrace) {
      _logger.e('❌ Error toggling haptics', error: e, stackTrace: stackTrace);
    }
  }

  /// Update text size
  Future<void> updateTextSize(double size) async {
    try {
      if (size < 10.0 || size > 32.0) {
        _logger.w('⚠️ Text size out of range: $size');
        return;
      }

      _logger.i('📝 Updating text size: $size');

      emit(state.copyWith(textSize: size));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('text_size', size);

      _logger.i('✅ Text size updated to $size');
    } catch (e, stackTrace) {
      _logger.e('❌ Error updating text size', error: e, stackTrace: stackTrace);
    }
  }

  /// Update language
  Future<void> updateLanguage(String language) async {
    try {
      _logger.i('🌍 Updating language: $language');

      emit(state.copyWith(language: language));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', language);

      _logger.i('✅ Language updated to $language');
    } catch (e, stackTrace) {
      _logger.e('❌ Error updating language', error: e, stackTrace: stackTrace);
    }
  }

  /// Reset all settings to defaults
  Future<void> resetSettings() async {
    try {
      _logger.i('🔄 Resetting all settings to defaults...');

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      emit(const SettingsState());
      _debugLogger.setEnabled(false);

      _logger.i('✅ All settings reset to defaults');
    } catch (e, stackTrace) {
      _logger.e('❌ Error resetting settings', error: e, stackTrace: stackTrace);
    }
  }
}
