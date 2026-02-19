  import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:live_captions_xr/core/services/enhanced_speech_processor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/debug_logger_service.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/models/user_settings.dart';
 
  

class SettingsCubit extends Cubit<UserSettings> {
  final EnhancedSpeechProcessor? _speechProcessor;

  SettingsCubit({EnhancedSpeechProcessor? speechProcessor}) 
      : _speechProcessor = speechProcessor,
        super(const UserSettings()) {
    _loadSettings();
  }

  static final AppLogger _logger = AppLogger.instance;
  final DebugLoggerService _debugLogger = DebugLoggerService();

  void toggleLedAlerts(bool value) {
    _saveSettings(state.copyWith(ledAlertsEnabled: value));
  }


  void toggleDebugLoggingOverlay(bool value) {
    _saveSettings(state.copyWith(debugLoggingOverlayEnabled: value));
    // Enable/disable the debug logger service
    _debugLogger.setEnabled(value);
  }

  void toggleRawSttDebugLine(bool value) {
    _saveSettings(state.copyWith(rawSttDebugLineEnabled: value));
  }


  // Optionally notify other services or update state when the speech engine changes
  Future<void> setSpeechEngine(SpeechEngine engine) async {
    _logger.i('🔄 Speech engine set to: $engine');
    
    // Actually switch the engine in the speech processor if available
    if (_speechProcessor != null) {
      try {
        await _speechProcessor!.switchEngine(engine);
        _logger.i('✅ Successfully switched speech engine to: $engine');
      } catch (e, stackTrace) {
        _logger.e('❌ Failed to switch speech engine to: $engine', error: e, stackTrace: stackTrace);
      }
    } else {
      _logger.w('⚠️ Speech processor not available, engine change not applied');
    }
  }

  /// Set the ASR backend/engine.
  void setAsrBackend(AsrBackend backend) {
    _saveSettings(state.copyWith(asrBackend: backend));
  }

  /// Set the LLM/enhancement backend.
  void setLlmBackend(LlmBackend backend) {
    _saveSettings(state.copyWith(llmBackend: backend));
  }

  void toggleHaptics(bool value) {
    _saveSettings(state.copyWith(hapticsEnabled: value));
  }

  Future<void> _loadSettings() async {
    try {
      _logger.i('⚙️ Loading app settings...');
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('user_settings');
      if (settingsJson != null) {
        final settings = UserSettings.fromJson(jsonDecode(settingsJson));
        emit(settings);
        // Enable debug logger service based on loaded setting
        _debugLogger.setEnabled(settings.debugLoggingOverlayEnabled);
        _logger.i('✅ Settings loaded successfully');
      } else {
        _logger.i('ℹ️ No saved settings found, using defaults.');
        final defaultSettings = const UserSettings();
        emit(defaultSettings);
        // Enable debug logger service based on default setting
        _debugLogger.setEnabled(defaultSettings.debugLoggingOverlayEnabled);
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

  void toggleSpatialLocalization(bool value) {
    _saveSettings(state.copyWith(spatialLocalizationEnabled: value));
  }

  void setLocalizationSensitivity(double value) {
    _saveSettings(state.copyWith(localizationSensitivity: value));
  }

  void setCaptionDuration(double seconds) {
    _saveSettings(state.copyWith(captionDurationSeconds: seconds));
  }

  void setMaxVisibleCaptions(int count) {
    _saveSettings(state.copyWith(maxVisibleCaptions: count));
  }

  void toggleSpeakerFocusMode(bool enabled) {
    _saveSettings(state.copyWith(speakerFocusModeEnabled: enabled));
  }

  void setAccessibilityCaptionMode(bool enabled) {
    if (enabled) {
      _saveSettings(state.copyWith(
        accessibilityCaptionModeEnabled: true,
        speakerFocusModeEnabled: true,
        highContrastEnabled: true,
        captionFontSize: 1.4,
        captionDurationSeconds: 8.0,
        maxVisibleCaptions: 4,
        spatialLocalizationEnabled: true,
      ));
      return;
    }

    _saveSettings(state.copyWith(accessibilityCaptionModeEnabled: false));
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
