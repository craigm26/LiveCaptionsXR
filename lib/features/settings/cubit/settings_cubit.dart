  import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

  void toggleHaptics(bool value) {
    _saveSettings(state.copyWith(hapticsEnabled: value));
  }

  Future<void> _loadSettings() async {
    try {
      _logger.i('⚙️ Loading app settings...');
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('user_settings');
      UserSettings settings;
      
      if (settingsJson != null) {
        settings = UserSettings.fromJson(jsonDecode(settingsJson));
      } else {
        _logger.i('ℹ️ No saved settings found, using defaults.');
        settings = const UserSettings();
        
        // If no token in settings, check .env file and save it
        if (!settings.hasHuggingFaceToken) {
          final envToken = dotenv.env['HUGGINGFACE_TOKEN'];
          if (envToken != null && envToken.isNotEmpty) {
            _logger.i('🔑 Found HuggingFace token in .env file, adding to settings');
            settings = settings.copyWith(huggingFaceToken: envToken);
            // Save the settings with the token from .env
            await _saveSettings(settings);
          }
        }
      }
      
      emit(settings);
      // Enable debug logger service based on loaded setting
      _debugLogger.setEnabled(settings.debugLoggingOverlayEnabled);
      _logger.i('✅ Settings loaded successfully');
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

  void setHuggingFaceToken(String? token) {
    _saveSettings(state.copyWith(huggingFaceToken: token?.isEmpty == true ? null : token));
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
