import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/user_settings.dart';
import '../../../core/services/enhanced_speech_processor.dart' show SpeechEngine;
import '../cubit/settings_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 2,
      ),
      body: BlocBuilder<SettingsCubit, UserSettings>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader('Caption Settings'),
              Tooltip(
                message: 'Change how large captions appear on screen. Useful for readability and accessibility.',
                child: _buildSettingTile(
                  context,
                  icon: Icons.text_fields,
                  title: 'Caption Font Size',
                  subtitle: 'Adjust the size of the captions',
                  trailing: Slider(
                    value: state.captionFontSize,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    label: state.captionFontSize.toStringAsFixed(1),
                    onChanged: (value) {
                      context.read<SettingsCubit>().setCaptionFontSize(value);
                    },
                  ),
                ),
              ),
              Tooltip(
                message: 'Enable for better visibility in bright or low-contrast environments.',
                child: _buildSettingTile(
                  context,
                  icon: Icons.contrast,
                  title: 'High Contrast',
                  subtitle: 'Improve caption visibility',
                  trailing: Switch(
                    value: state.highContrastEnabled,
                    onChanged: (value) {
                      context.read<SettingsCubit>().toggleHighContrast(value);
                    },
                  ),
                ),
              ),
              _buildSectionHeader('Speech & Enhancement'),
              Tooltip(
                message: 'Online mode uses cloud services for higher accuracy (may send audio to server). Offline mode keeps audio on device for privacy.',
                child: _buildSettingTile(
                  context,
                  icon: Icons.cloud_outlined,
                  title: 'Speech-to-Text Mode',
                  subtitle: 'Online for accuracy, Offline for privacy',
                  trailing: DropdownButton<SttMode>(
                    value: state.sttMode == SttMode.online
                        ? SttMode.offline
                        : state.sttMode,
                    items: [
                      DropdownMenuItem<SttMode>(
                        value: SttMode.online,
                        enabled: false,
                        child: Row(
                          children: [
                            Opacity(
                              opacity: 0.5,
                              child: Text('Online'),
                            ),
                            Tooltip(
                              message: 'Disabled for now (requires paid API)',
                              child:
                                  Icon(Icons.lock, size: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const DropdownMenuItem<SttMode>(
                        value: SttMode.offline,
                        child: Text('Offline'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == SttMode.offline) {
                        context
                            .read<SettingsCubit>()
                            .setSttMode(value as SttMode);
                      }
                    },
                  ),
                ),
              ),
              Tooltip(
                message: 'Select which speech recognition engine to use. Some engines may offer better speed, privacy, or accuracy.',
                child: _buildSettingTile(
                  context,
                  icon: Icons.settings_voice,
                  title: 'ASR Backend',
                  subtitle: 'Choose the speech engine backend',
                  trailing: DropdownButton<AsrBackend>(
                    value: state.asrBackend,
                    items: _asrBackendDropdownItems(context),
                    onChanged: (backend) {
                      if (backend != null) {
                        final engine = _asrBackendToSpeechEngine(backend);
                        context.read<SettingsCubit>().setAsrBackend(backend);
                        context.read<SettingsCubit>().setSpeechEngine(engine);
                      }
                    },
                  ),
                ),
              ),
              Tooltip(
                message: 'Enable to improve captions with context-aware enhancements (may use more processing).',
                child: _buildSettingTile(
                  context,
                  icon: Icons.auto_awesome,
                  title: 'Enhancement',
                  subtitle: 'Enable contextual enhancement of captions',
                  trailing: Switch(
                    value: state.enhancementEnabled,
                    onChanged: (value) {
                      context.read<SettingsCubit>().toggleEnhancement(value);
                    },
                  ),
                ),
              ),
              Tooltip(
                message: 'Enable to receive vibration feedback for important events.',
                child: _buildSettingTile(
                  context,
                  icon: Icons.vibration,
                  title: 'Haptic Feedback',
                  subtitle: 'Enable haptic feedback for events',
                  trailing: Switch(
                    value: state.hapticsEnabled,
                    onChanged: (value) {
                      context.read<SettingsCubit>().toggleHaptics(value);
                    },
                  ),
                ),
              ),
              Tooltip(
                message: 'Enable to use device LED for visual alerts (useful for accessibility).',
                child: _buildSettingTile(
                  context,
                  icon: Icons.lightbulb_outline,
                  title: 'LED Alerts',
                  subtitle: 'Enable LED alerts for accessibility',
                  trailing: Switch(
                    value: state.ledAlertsEnabled,
                    onChanged: (value) {
                      context.read<SettingsCubit>().toggleLedAlerts(value);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

List<DropdownMenuItem<AsrBackend>> _asrBackendDropdownItems(
    BuildContext context) {
  return AsrBackend.values.map((backend) {
    return DropdownMenuItem<AsrBackend>(
      value: backend,
      child: Text(backend.name),
    );
  }).toList();
}

SpeechEngine _asrBackendToSpeechEngine(AsrBackend backend) {
  switch (backend) {
    case AsrBackend.flutterSound:
      return SpeechEngine.flutter_sound;
    case AsrBackend.gemma3n:
      return SpeechEngine.gemma3n;
    case AsrBackend.native:
      return SpeechEngine.native;
    case AsrBackend.openAI:
      return SpeechEngine.openAI;
  }
}

Widget _buildSectionHeader(String title) {
  return Text(
    title,
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.blue,
    ),
  );
}

Widget _buildSettingTile(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required Widget trailing,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
    ),
  );
}
