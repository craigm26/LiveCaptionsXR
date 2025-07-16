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
      _updateEngine(settings.sttMode);
    });
    // Set initial engine
    _updateEngine(_settingsCubit.state.sttMode);
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
        engine = SpeechEngine.speechToText;
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
