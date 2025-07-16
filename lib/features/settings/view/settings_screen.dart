import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:live_captions_xr/core/services/google_auth_service.dart';
import '../../../core/models/user_settings.dart';
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
              _buildSettingTile(
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
              _buildSettingTile(
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
              const SizedBox(height: 24),
              _buildSectionHeader('Speech & Enhancement'),
              _buildSettingTile(
                context,
                icon: Icons.cloud_outlined,
                title: 'Speech-to-Text Mode',
                subtitle: 'Online for accuracy, Offline for privacy',
                trailing: DropdownButton<SttMode>(
                  value: state.sttMode,
                  items: const [
                    DropdownMenuItem(value: SttMode.online, child: Text('Online')),
                    DropdownMenuItem(value: SttMode.offline, child: Text('Offline')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      context.read<SettingsCubit>().setSttMode(value);
                    }
                  },
                ),
              ),
              _buildSettingTile(
                context,
                icon: Icons.auto_awesome,
                title: 'Contextual Enhancement',
                subtitle: 'Use Gemma to improve captions',
                trailing: Switch(
                  value: state.enhancementEnabled,
                  onChanged: (value) {
                    context.read<SettingsCubit>().toggleEnhancement(value);
                  },
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Cloud Services'),
              _buildSettingTile(
                context,
                icon: Icons.login,
                title: 'Google Cloud',
                subtitle: 'Sign in to use Google Cloud STT',
                trailing: ElevatedButton(
                  onPressed: () {
                    context.read<GoogleAuthService>().signIn();
                  },
                  child: const Text('Sign In'),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Feedback'),
              _buildSettingTile(
                context,
                icon: Icons.vibration,
                title: 'Haptic Feedback',
                subtitle: 'Vibrations for important events',
                trailing: Switch(
                  value: state.hapticsEnabled,
                  onChanged: (value) {
                    // This needs to be implemented in the cubit
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
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
}
