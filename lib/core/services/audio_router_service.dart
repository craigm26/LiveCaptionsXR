import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/settings/cubit/settings_cubit.dart';
import '../../core/models/user_settings.dart';
import 'enhanced_speech_processor.dart';
import 'debug_capturing_logger.dart';

/// A service that routes audio to the correct speech-to-text engine
/// based on user settings.
class AudioRouterService {
  static final DebugCapturingLogger _logger = DebugCapturingLogger();

  final EnhancedSpeechProcessor _speechProcessor;
  final SettingsCubit _settingsCubit;
  StreamSubscription? _settingsSubscription;

  AudioRouterService({
    required EnhancedSpeechProcessor speechProcessor,
    required SettingsCubit settingsCubit,
  })  : _speechProcessor = speechProcessor,
        _settingsCubit = settingsCubit {
    _listenForSettingsChanges();
  }

  void _listenForSettingsChanges() {
    _settingsSubscription = _settingsCubit.stream.listen((settings) {
      _logger.i('⚙️ Settings changed, updating speech engine...');
      _updateEngineFromSettings(settings);
    });
    // Set initial engine
    _updateEngineFromSettings(_settingsCubit.state);
  }

  /// Update the speech engine based on both ASR backend and STT mode.
  Future<void> _updateEngineFromSettings(UserSettings settings) async {
    // Determine engine from ASR backend if set, otherwise fall back to STT mode logic
    SpeechEngine? engine;
    // Prefer ASR backend selection if available
    switch (settings.asrBackend) {
      case AsrBackend.flutterSound:
        engine = SpeechEngine.flutter_sound;
        break;
      case AsrBackend.gemma3n:
        engine = SpeechEngine.gemma3n;
        break;
      case AsrBackend.native:
        engine = SpeechEngine.native;
        break;
      case AsrBackend.openAI:
        engine = SpeechEngine.openAI;
        break;
      case AsrBackend.whisperGgml:
        engine = SpeechEngine.whisper_ggml;
        break;
    }
    // If for some reason engine is null, fallback to STT mode logic
    if (engine == null) {
      switch (settings.sttMode) {
        case SttMode.online:
          engine = SpeechEngine.openAI;
          break;
        case SttMode.offline:
          engine = SpeechEngine.flutter_sound;
          break;
      }
    }
    if (_speechProcessor.activeEngine != engine) {
      _logger.i('🔄 Switching speech engine to $engine');
      await _speechProcessor.switchEngine(engine);
    }
  }

  Future<void> _updateEngine(SttMode mode) async {
    SpeechEngine engine;
    switch (mode) {
      case SttMode.online:
        // Defaulting to OpenAI for online, as it's the integrated cloud provider.
        engine = SpeechEngine.openAI;
        break;
      case SttMode.offline:
        // Defaulting to speech_to_text for offline, as it's a stable on-device option.
        // We can change this to gemma3n to test its performance.
        engine = SpeechEngine.flutter_sound;
        break;
    }

    if (_speechProcessor.activeEngine != engine) {
      _logger.i('🔄 Switching speech engine to $engine');
      await _speechProcessor.switchEngine(engine);
    }
  }

  void dispose() {
    _settingsSubscription?.cancel();
  }
}
