import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/settings_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  /// Check if we're in a development or testing build
  /// This includes debug mode, profile mode, TestFlight builds, or when assertions are enabled
  bool get _isDevelopmentBuild {
    bool isInDevelopmentMode = kDebugMode || kProfileMode;
    
    // Also check for assertions (which are enabled in debug and profile builds)
    bool assertionsEnabled = false;
    assert(assertionsEnabled = true);
    
    // Check for TestFlight builds using build-time flag
    const bool isTestFlight = bool.fromEnvironment('IS_TESTFLIGHT', defaultValue: false);
    
    return isInDevelopmentMode || assertionsEnabled || isTestFlight;
  }

  /// Get the current build mode description
  String _getBuildModeText() {
    const bool isTestFlight = bool.fromEnvironment('IS_TESTFLIGHT', defaultValue: false);
    
    if (kDebugMode) {
      return 'Debug';
    } else if (kProfileMode) {
      return 'Profile';
    } else if (isTestFlight) {
      return 'Release (TestFlight)';
    } else {
      return 'Release';
    }
  }

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

              // Developer Settings Section (show in development builds including TestFlight)
              if (_isDevelopmentBuild) ...[
                _buildSectionHeader('Developer & Testing'),
                const SizedBox(height: 16),

                // Debug Logging Toggle - Make it more prominent
                Card(
                  elevation: 2,
                  child: ListTile(
                    leading: Icon(
                      Icons.bug_report,
                      color: state.debugLoggingEnabled ? Colors.orange : Theme.of(context).primaryColor,
                    ),
                    title: const Text(
                      'Debug Logging Overlay',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Show transparent debug log overlay on screen\n'
                      'Useful for TestFlight debugging and issue reporting',
                    ),
                    trailing: Switch(
                      value: state.debugLoggingEnabled,
                      onChanged: (_) {
                        context.read<SettingsCubit>().toggleDebugLogging();
                      },
                    ),
                    onTap: () {
                      context.read<SettingsCubit>().toggleDebugLogging();
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Debug Info Card
                if (state.debugLoggingEnabled)
                  Card(
                    color: Colors.green.withOpacity(0.1),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: Colors.green[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Debug Logging Active',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '📱 Look for the overlay on the Home screen',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'A transparent black box will appear at the top of the Home screen showing debug logs in real-time.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'How to use the overlay:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '• Tap the overlay header to expand/collapse\n'
                            '• Blue arrow button: Toggle auto-scroll to latest logs\n'
                            '• Copy button: Copy all logs to clipboard\n'
                            '• Clear button: Clear all captured logs\n'
                            '• Orange test button: Generate sample logs (when expanded)',
                            style: TextStyle(fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Helper card when debug logging is disabled
                if (!state.debugLoggingEnabled)
                  Card(
                    color: Colors.blue.withOpacity(0.1),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: Colors.blue[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Enable Debug Logging',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Turn on debug logging to see a transparent overlay with real-time app logs on the Home screen. '
                            'This is especially useful for TestFlight testing and troubleshooting issues.',
                            style: TextStyle(fontSize: 12),
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
                subtitle: Text(_getBuildModeText()),
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
