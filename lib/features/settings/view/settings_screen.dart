import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // App Settings Section
              _buildSectionHeader('App Settings'),
              const SizedBox(height: 16),

              // Notifications Toggle
              _buildSettingTile(
                context,
                icon: Icons.notifications,
                title: 'Notifications',
                subtitle: 'Receive notifications for sound events',
                trailing: Switch(
                  value: state.notificationsEnabled,
                  onChanged: (_) {
                    context.read<SettingsCubit>().toggleNotifications();
                  },
                ),
              ),

              // Haptic Feedback Toggle
              _buildSettingTile(
                context,
                icon: Icons.vibration,
                title: 'Haptic Feedback',
                subtitle: 'Feel vibrations for audio cues',
                trailing: Switch(
                  value: state.hapticsEnabled,
                  onChanged: (_) {
                    context.read<SettingsCubit>().toggleHaptics();
                  },
                ),
              ),

              // Text Size Slider
              _buildSettingTile(
                context,
                icon: Icons.text_fields,
                title: 'Text Size',
                subtitle: 'Adjust caption text size',
                trailing: SizedBox(
                  width: 100,
                  child: Slider(
                    value: state.textSize,
                    min: 10.0,
                    max: 32.0,
                    divisions: 11,
                    label: state.textSize.round().toString(),
                    onChanged: (value) {
                      context.read<SettingsCubit>().updateTextSize(value);
                    },
                  ),
                ),
              ),

              // Language Selection
              _buildSettingTile(
                context,
                icon: Icons.language,
                title: 'Language',
                subtitle: 'Select app language',
                trailing: DropdownButton<String>(
                  value: state.language,
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'es', child: Text('Español')),
                    DropdownMenuItem(value: 'fr', child: Text('Français')),
                    DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      context.read<SettingsCubit>().updateLanguage(value);
                    }
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Developer Settings Section (only show in debug/profile mode)
              if (kDebugMode || kProfileMode) ...[
                _buildSectionHeader('Developer Settings'),
                const SizedBox(height: 16),

                // Debug Logging Toggle
                _buildSettingTile(
                  context,
                  icon: Icons.bug_report,
                  title: 'Debug Logging Overlay',
                  subtitle: 'Show real-time debug logs on screen (TestFlight)',
                  trailing: Switch(
                    value: state.debugLoggingEnabled,
                    onChanged: (_) {
                      context.read<SettingsCubit>().toggleDebugLogging();
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Debug Info Card
                if (state.debugLoggingEnabled)
                  Card(
                    color: Colors.orange.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.orange[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Debug Logging Active',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Debug logs are now being captured and displayed in a transparent overlay. '
                            'You can expand the overlay to view logs, copy them to clipboard, or clear them. '
                            'This feature is designed for TestFlight debugging.',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Overlay Controls:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '• Tap to expand/collapse\n'
                            '• Blue arrow: Toggle auto-scroll\n'
                            '• Copy icon: Copy logs to clipboard\n'
                            '• Clear icon: Clear all logs',
                            style: TextStyle(fontSize: 11, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 32),
              ],

              // Actions Section
              _buildSectionHeader('Actions'),
              const SizedBox(height: 16),

              // Reset Settings Button
              ListTile(
                leading: const Icon(Icons.restore, color: Colors.red),
                title: const Text('Reset Settings'),
                subtitle: const Text('Reset all settings to defaults'),
                onTap: () => _showResetConfirmation(context),
              ),

              const SizedBox(height: 32),

              // App Info Section
              _buildSectionHeader('About'),
              const SizedBox(height: 16),

              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('App Version'),
                subtitle: const Text('1.0.0'),
              ),

              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('Build Mode'),
                subtitle: Text(kDebugMode
                    ? 'Debug'
                    : kProfileMode
                        ? 'Profile'
                        : 'Release'),
              ),

              const SizedBox(height: 32),
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

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Settings'),
          content: const Text(
            'Are you sure you want to reset all settings to their default values? '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<SettingsCubit>().resetSettings();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings reset to defaults'),
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }
}
