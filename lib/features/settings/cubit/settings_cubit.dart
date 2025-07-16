import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/debug_logger_service.dart';
import '../../../core/services/debug_capturing_logger.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/user_settings.dart';
import '../../../core/services/debug_logger_service.dart';
import '../../../core/services/debug_capturing_logger.dart';

class SettingsCubit extends Cubit<UserSettings> {
  SettingsCubit() : super(const UserSettings()) {
    _loadSettings();
  }

  static final DebugCapturingLogger _logger = DebugCapturingLogger();
  final DebugLoggerService _debugLogger = DebugLoggerService();

  Future<void> _loadSettings() async {
    try {
      _logger.i('⚙️ Loading app settings...');
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('user_settings');
      if (settingsJson != null) {
        final settings = UserSettings.fromJson(jsonDecode(settingsJson));
        emit(settings);
        _logger.i('✅ Settings loaded successfully');
      } else {
        _logger.i('ℹ️ No saved settings found, using defaults.');
        emit(const UserSettings());
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Error loading settings', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _saveSettings(UserSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(settings.toJson());
      await prefs.setString('user_settings', settingsJson);
      emit(settings);
    } catch (e, stackTrace) {
      _logger.e('❌ Error saving settings', error: e, stackTrace: stackTrace);
    }
  }

  void updateSettings(UserSettings newSettings) {
    _saveSettings(newSettings);
  }

  void toggleEnhancement(bool value) {
    _saveSettings(state.copyWith(enhancementEnabled: value));
  }

  void setSttMode(SttMode mode) {
    _saveSettings(state.copyWith(sttMode: mode));
  }

  void toggleHighContrast(bool value) {
    _saveSettings(state.copyWith(highContrastEnabled: value));
  }

  void setCaptionFontSize(double size) {
    _saveSettings(state.copyWith(captionFontSize: size));
  }

  Future<void> resetSettings() async {
    try {
      _logger.i('🔄 Resetting all settings to defaults...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_settings');
      emit(const UserSettings());
      _logger.i('�� All settings reset to defaults');
    } catch (e, stackTrace) {
      _logger.e('❌ Error resetting settings', error: e, stackTrace: stackTrace);
    }
  }
}
