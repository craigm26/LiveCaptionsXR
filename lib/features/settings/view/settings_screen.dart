         
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/user_settings.dart';
import '../../../core/services/enhanced_speech_processor.dart'
    show SpeechEngine;
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
                message:
                    'Change how large captions appear on screen. Useful for readability and accessibility.',
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
                message:
                    'Enable for better visibility in bright or low-contrast environments.',
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
                message:
                    'Live Captions XR currently performs speech recognition fully on-device using Whisper GGML (Android) or Apple Speech plus Gemma 3n. Cloud APIs are disabled to keep every conversation private.',
                child: _buildSettingTile(
                  context,
                  icon: Icons.cloud_outlined,
                  title: 'Speech-to-Text Mode',
                  subtitle: 'On-device pipeline (cloud mode disabled)',
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Chip(
                        label: const Text('On-device'),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Whisper + Gemma 3n',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.end,
                      ),
                    ],
                  ),
                ),
              ),
              Tooltip(
                message:
                    'Choose which on-device engine drives the captions. Whisper GGML is preferred on Android, Apple Speech (Native) shines on iOS, and Gemma 3n powers contextual rephrasing.',
                child: _buildSettingTile(
                  context,
                  icon: Icons.settings_voice,
                  title: 'ASR Backend',
                  subtitle: 'Choose the on-device speech engine',
                  trailing: DropdownButton<AsrBackend>(
                    value: state.asrBackend,
                    items: _asrBackendDropdownItems(context),
                    onChanged: (backend) async {
                      if (backend != null && backend != AsrBackend.openAI) {
                        final engine = _asrBackendToSpeechEngine(backend);
                        context.read<SettingsCubit>().setAsrBackend(backend);
                        await context.read<SettingsCubit>().setSpeechEngine(engine);
                      }
                    },
                  ),
                  trailingWidth: 260,
                ),
              ),
              Tooltip(
                message:
                    'Enable to improve captions with context-aware enhancements (may use more processing).',
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
                message:
                    'Enable to receive vibration feedback for important events.',
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
                message: 'Show a debug logging overlay for troubleshooting and developer support.',
                child: _buildSettingTile(
                  context,
                  icon: Icons.bug_report,
                  title: 'Debug Logging Overlay',
                  subtitle: 'Show debug logs as a dropdown overlay',
                  trailing: Switch(
                    value: state.debugLoggingOverlayEnabled,
                    onChanged: (value) {
                      context.read<SettingsCubit>().toggleDebugLoggingOverlay(value);
                    },
                  ),
                ),
              ),

              Tooltip(
                message:
                    'Enable to use device LED for visual alerts (useful for accessibility).',
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
              Tooltip(
                message:
                    'Review Whisper Base and Gemma 3n downloads, see storage impact, and retry failed transfers.',
                child: _buildSettingTile(
                  context,
                  icon: Icons.storage,
                  title: 'Model Management',
                  subtitle: 'Check Whisper & Gemma downloads',
                  trailing: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/model-status');
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open'),
                  ),
                ),
              ),
              _buildSectionHeader('Model Configuration'),
              Tooltip(
                message: 'HuggingFace token for downloading gated Gemma models. Leave empty to use bucket downloads. Can also be set via .env file as HUGGINGFACE_TOKEN.',
                child: _buildHuggingFaceTokenTile(context, state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHuggingFaceTokenTile(BuildContext context, UserSettings state) {
    return _HuggingFaceTokenInput(state: state);
  }
}

class _HuggingFaceTokenInput extends StatefulWidget {
  final UserSettings state;

  const _HuggingFaceTokenInput({required this.state});

  @override
  State<_HuggingFaceTokenInput> createState() => _HuggingFaceTokenInputState();
}

class _HuggingFaceTokenInputState extends State<_HuggingFaceTokenInput> {
  late TextEditingController _tokenController;
  bool _isTokenVisible = false;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: widget.state.huggingFaceToken ?? '');
  }

  @override
  void didUpdateWidget(_HuggingFaceTokenInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.huggingFaceToken != widget.state.huggingFaceToken) {
      _tokenController.text = widget.state.huggingFaceToken ?? '';
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.key, color: Theme.of(context).primaryColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HuggingFace Token',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.state.hasHuggingFaceToken
                            ? 'Token configured'
                            : 'Not configured - using bucket downloads',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.state.hasHuggingFaceToken
                              ? Colors.green
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tokenController,
              obscureText: !_isTokenVisible,
              decoration: InputDecoration(
                labelText: 'HuggingFace Token',
                hintText: 'Enter your HuggingFace token',
                suffixIcon: IconButton(
                  icon: Icon(
                    _isTokenVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isTokenVisible = !_isTokenVisible;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
                helperText: 'Required for downloading gated Gemma models from HuggingFace',
              ),
              onChanged: (value) {
                context.read<SettingsCubit>().setHuggingFaceToken(value);
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (widget.state.hasHuggingFaceToken)
                  TextButton.icon(
                    onPressed: () {
                      _tokenController.clear();
                      context.read<SettingsCubit>().setHuggingFaceToken(null);
                    },
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear Token'),
                  ),
                const Spacer(),
                TextButton.icon(
                  onPressed: widget.state.hasHuggingFaceToken
                      ? () {
                          Clipboard.setData(
                              ClipboardData(text: widget.state.huggingFaceToken ?? ''));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Token copied to clipboard'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

List<DropdownMenuItem<AsrBackend>> _asrBackendDropdownItems(
    BuildContext context) {
  return AsrBackend.values.map((backend) {
    String displayName;
    bool isEnabled = true;
    
    switch (backend) {
      case AsrBackend.flutterSound:
        displayName = 'Flutter Sound (legacy capture)';
        break;
      case AsrBackend.gemma3n:
        displayName = 'Gemma 3n Enhancer';
        break;
      case AsrBackend.native:
        displayName = 'Native (Apple Speech/iOS)';
        break;
      case AsrBackend.openAI:
        displayName = 'OpenAI (disabled)';
        isEnabled = false;
        break;
      case AsrBackend.whisperGgml:
        displayName = 'Whisper GGML (Android)';
        break;
    }
    
    return DropdownMenuItem<AsrBackend>(
      value: backend,
      enabled: isEnabled,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (backend == AsrBackend.whisperGgml)
            Icon(Icons.star, size: 16, color: Colors.amber),
          Flexible(
            child: !isEnabled
                ? Opacity(opacity: 0.5, child: Text(displayName))
                : Text(displayName),
          ),
          if (!isEnabled)
            Tooltip(
              message: 'Requires paid API key',
              child: Icon(Icons.lock, size: 16, color: Colors.grey),
            ),
        ],
      ),
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
    case AsrBackend.whisperGgml:
      return SpeechEngine.whisper_ggml;
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
  double? trailingWidth,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: SizedBox(
        width: trailingWidth ?? 180,
        child: Align(
          alignment: Alignment.centerRight,
          child: trailing,
        ),
      ),
    ),
  );
}
