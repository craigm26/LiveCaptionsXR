import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/user_settings.dart';
import '../../../core/models/device_model_config.dart';
import '../../../core/services/enhanced_speech_processor.dart'
    show SpeechEngine;
import '../../../core/services/nexa_asr_service.dart';
import '../cubit/settings_cubit.dart';
import '../../translation/widgets/translation_settings_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  DeviceModelConfig? _deviceConfig;
  bool _loadingDeviceInfo = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceConfig();
  }

  Future<void> _loadDeviceConfig() async {
    if (kIsWeb || !Platform.isAndroid) {
      setState(() => _loadingDeviceInfo = false);
      return;
    }
    try {
      final registry = DeviceModelRegistry();
      final config = await registry.getDeviceConfig();
      if (mounted) {
        setState(() {
          _deviceConfig = config;
          _loadingDeviceInfo = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingDeviceInfo = false);
    }
  }

  bool get _isNpuDevice =>
      _deviceConfig != null && _deviceConfig!.npuAvailable;

  String get _inferenceModeName {
    if (_deviceConfig == null) return 'CPU';
    switch (_deviceConfig!.recommendedInferenceMode) {
      case NexaInferenceMode.npu:
        return 'NPU';
      case NexaInferenceMode.gpu:
        return 'GPU';
      case NexaInferenceMode.cpu:
        return 'CPU';
    }
  }

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
              // ── Device & AI Section ──
              if (!_loadingDeviceInfo) ...[
                _buildSectionHeader('Device & AI'),
                _buildDeviceInfoCard(context, state),
                const SizedBox(height: 16),
              ],

              _buildSectionHeader('Caption Settings'),
              Tooltip(
                message:
                    'Apply a non-AR accessibility preset optimized for 2D captions: larger text, high contrast, and tuned caption visibility.',
                child: _buildSettingTile(
                  context,
                  icon: Icons.accessibility_new,
                  title: 'Accessibility Caption Mode',
                  subtitle:
                      'One-tap preset for high-clarity non-AR captions',
                  trailing: Switch(
                    value: state.accessibilityCaptionModeEnabled,
                    onChanged: (value) {
                      context
                          .read<SettingsCubit>()
                          .setAccessibilityCaptionMode(value);
                    },
                  ),
                ),
              ),
              Tooltip(
                message:
                    'Emphasize speaker identity in captions with stronger speaker labels for faster tracking.',
                child: _buildSettingTile(
                  context,
                  icon: Icons.record_voice_over,
                  title: 'Speaker Focus Mode',
                  subtitle: 'Highlight who is speaking in each caption',
                  trailing: Switch(
                    value: state.speakerFocusModeEnabled,
                    onChanged: (value) {
                      context
                          .read<SettingsCubit>()
                          .toggleSpeakerFocusMode(value);
                    },
                  ),
                ),
              ),
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
                    'Online mode uses cloud services for higher accuracy (may send audio to server). Offline mode keeps audio on device for privacy.',
                child: _buildSettingTile(
                  context,
                  icon: Icons.cloud_outlined,
                  title: 'Speech-to-Text Mode',
                  subtitle: 'Online for accuracy, Offline for privacy',
                  trailing: DropdownButton<SttMode>(
                    value: state.sttMode,
                    items: [
                      DropdownMenuItem<SttMode>(
                        value: SttMode.online,
                        enabled: false,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Opacity(
                                opacity: 0.5,
                                child: Text('Online'),
                              ),
                            ),
                            Tooltip(
                              message: 'Disabled for now (requires paid API)',
                              child: Icon(Icons.lock,
                                  size: 16, color: Colors.grey),
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
                message:
                    'Select which speech recognition engine to use. Some engines may offer better speed, privacy, or accuracy.',
                child: _buildSettingTile(
                  context,
                  icon: Icons.settings_voice,
                  title: 'ASR Backend',
                  subtitle: _isNpuDevice
                      ? 'Nexa Parakeet recommended for this device'
                      : 'Choose the speech engine backend',
                  trailing: DropdownButton<AsrBackend>(
                    value: state.asrBackend,
                    items: _asrBackendDropdownItems(context),
                    onChanged: (backend) async {
                      if (backend != null && backend != AsrBackend.openAI) {
                        final engine = _asrBackendToSpeechEngine(backend);
                        context.read<SettingsCubit>().setAsrBackend(backend);
                        await context
                            .read<SettingsCubit>()
                            .setSpeechEngine(engine);
                      }
                    },
                  ),
                ),
              ),
              Tooltip(
                message:
                    'Select which LLM/enhancement engine to use for caption improvement and translation.',
                child: _buildSettingTile(
                  context,
                  icon: Icons.auto_awesome,
                  title: 'LLM Backend',
                  subtitle: _llmBackendSubtitle(state.llmBackend),
                  trailing: DropdownButton<LlmBackend>(
                    value: state.llmBackend,
                    items: _llmBackendDropdownItems(context),
                    onChanged: (backend) {
                      if (backend != null) {
                        context.read<SettingsCubit>().setLlmBackend(backend);
                      }
                    },
                  ),
                ),
              ),
              Tooltip(
                message:
                    'Enable to improve captions with context-aware enhancements (may use more processing).',
                child: _buildSettingTile(
                  context,
                  icon: Icons.auto_fix_high,
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
                    'Requires OmniNeural-4B to be downloaded. Shows speaker name labels that track each person\'s position, and uses a continuously-responsive directional pointer.',
                child: _buildSettingTile(
                  context,
                  icon: Icons.spatial_audio,
                  title: 'Enhanced Captions',
                  subtitle: 'Sticky speaker labels + precise directional tracking (OmniNeural)',
                  trailing: Switch(
                    value: state.enhancedCaptionsEnabled,
                    onChanged: (value) {
                      context.read<SettingsCubit>().toggleEnhancedCaptions(value);
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
                message:
                    'Show a debug logging overlay for troubleshooting and developer support.',
                child: _buildSettingTile(
                  context,
                  icon: Icons.bug_report,
                  title: 'Debug Logging Overlay',
                  subtitle: 'Show debug logs as a dropdown overlay',
                  trailing: Switch(
                    value: state.debugLoggingOverlayEnabled,
                    onChanged: (value) {
                      context
                          .read<SettingsCubit>()
                          .toggleDebugLoggingOverlay(value);
                    },
                  ),
                ),
              ),

              Tooltip(
                message:
                    'Show the temporary raw speech-to-text line under captions for headset debugging.',
                child: _buildSettingTile(
                  context,
                  icon: Icons.text_fields,
                  title: 'Raw STT Debug Line',
                  subtitle: 'Show raw speech text line under captions',
                  trailing: Switch(
                    value: state.rawSttDebugLineEnabled,
                    onChanged: (value) {
                      context.read<SettingsCubit>().toggleRawSttDebugLine(value);
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
              // ── Spatial Audio Settings ──
              const SizedBox(height: 16),
              _buildSectionHeader('Spatial Audio'),
              Tooltip(
                message: 'Enable speaker localization to position captions in 3D space.',
                child: _buildSettingTile(
                  context,
                  icon: Icons.spatial_audio,
                  title: 'Speaker Localization',
                  subtitle: 'Position captions based on speaker direction',
                  trailing: Switch(
                    value: state.spatialLocalizationEnabled,
                    onChanged: (value) {
                      context.read<SettingsCubit>().toggleSpatialLocalization(value);
                    },
                  ),
                ),
              ),
              Tooltip(
                message: 'Adjust how sensitive speaker direction detection is.',
                child: _buildSettingTile(
                  context,
                  icon: Icons.tune,
                  title: 'Localization Sensitivity',
                  subtitle: 'Higher values detect subtler direction changes',
                  trailing: Slider(
                    value: state.localizationSensitivity,
                    min: 0.1,
                    max: 1.0,
                    divisions: 9,
                    label: state.localizationSensitivity.toStringAsFixed(1),
                    onChanged: (value) {
                      context.read<SettingsCubit>().setLocalizationSensitivity(value);
                    },
                  ),
                ),
              ),

              // ── Caption Display Settings ──
              const SizedBox(height: 16),
              _buildSectionHeader('Caption Display'),
              Tooltip(
                message: 'How long captions remain visible on screen.',
                child: _buildSettingTile(
                  context,
                  icon: Icons.timer,
                  title: 'Caption Duration',
                  subtitle: '${state.captionDurationSeconds.toInt()} seconds',
                  trailing: Slider(
                    value: state.captionDurationSeconds,
                    min: 2.0,
                    max: 15.0,
                    divisions: 13,
                    label: '${state.captionDurationSeconds.toInt()}s',
                    onChanged: (value) {
                      context.read<SettingsCubit>().setCaptionDuration(value);
                    },
                  ),
                ),
              ),
              Tooltip(
                message: 'Maximum number of captions shown simultaneously.',
                child: _buildSettingTile(
                  context,
                  icon: Icons.format_list_numbered,
                  title: 'Max Visible Captions',
                  subtitle: '${state.maxVisibleCaptions} captions',
                  trailing: Slider(
                    value: state.maxVisibleCaptions.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '${state.maxVisibleCaptions}',
                    onChanged: (value) {
                      context.read<SettingsCubit>().setMaxVisibleCaptions(value.toInt());
                    },
                  ),
                ),
              ),

              // ── Pipeline Status ──
              const SizedBox(height: 16),
              _buildSectionHeader('Pipeline Status'),
              _buildPipelineStatusCard(context),

              // ── Model Management ──
              const SizedBox(height: 16),
              _buildSectionHeader('Model Management'),
              _buildSettingTile(
                context,
                icon: Icons.storage,
                title: _isNpuDevice ? 'AI Models (Auto-managed)' : 'AI Models',
                subtitle: _isNpuDevice
                    ? 'Models auto-managed by Nexa SDK'
                    : 'Download and manage AI models',
                trailing: ElevatedButton.icon(
                  onPressed: () => context.push('/models'),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open'),
                ),
              ),

              const SizedBox(height: 16),
              _buildSectionHeader('Translation'),
              const SizedBox(height: 8),
              const TranslationSettingsCard(),
            ],
          );
        },
      ),
    );
  }

  /// Device & AI info card showing NPU status, engine selection, inference mode
  Widget _buildDeviceInfoCard(BuildContext context, UserSettings state) {
    final config = _deviceConfig;
    final isNpu = _isNpuDevice;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isNpu ? Colors.green.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isNpu ? Icons.memory : Icons.phone_android,
                  color: isNpu ? Colors.green.shade700 : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  isNpu ? 'NPU Accelerated' : 'Standard Device',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isNpu ? Colors.green.shade700 : null,
                  ),
                ),
                const Spacer(),
                if (isNpu)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _inferenceModeName,
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            if (config != null) ...[
              const SizedBox(height: 12),
              if (config.formFactor == DeviceFormFactor.xrHeadset ||
                  config.formFactor == DeviceFormFactor.arGlasses)
                _infoRow('Device', _deviceDisplayName(config))
              else
                _infoRow('Device Tier', config.tier.name.toUpperCase()),
              if (config.formFactor == DeviceFormFactor.xrHeadset ||
                  config.formFactor == DeviceFormFactor.arGlasses)
                _infoRow('Type', config.formFactor == DeviceFormFactor.xrHeadset
                    ? 'XR Headset' : 'AR Glasses'),
              _infoRow(
                  'Chipset Family', _snapdragonFamilyName(config.snapdragonFamily)),
              _infoRow('ASR Engine', 'Nexa ${config.asrModel.displayName}'),
              _infoRow('LLM Engine', 'Nexa ${config.llmModel.displayName}'),
              _infoRow('Inference', _inferenceModeName),
              _infoRow('NPU', isNpu ? 'Available ✅' : 'Not available'),
            ],
            if (config == null && !kIsWeb && Platform.isAndroid) ...[
              const SizedBox(height: 8),
              const Text('Could not detect device capabilities',
                  style: TextStyle(color: Colors.grey)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  String _snapdragonFamilyName(SnapdragonFamily family) {
    switch (family) {
      case SnapdragonFamily.gen4:
        return 'Snapdragon 8 Elite';
      case SnapdragonFamily.gen3:
        return 'Snapdragon 8 Gen 3';
      case SnapdragonFamily.gen2:
        return 'Snapdragon 8 Gen 2';
      case SnapdragonFamily.gen1:
        return 'Snapdragon 8 Gen 1';
      case SnapdragonFamily.series7:
        return 'Snapdragon 7 Series';
      case SnapdragonFamily.series6:
        return 'Snapdragon 6 Series';
      case SnapdragonFamily.xr2Gen2:
        return 'Snapdragon XR2 Gen 2';
      case SnapdragonFamily.xr2Gen1:
        return 'Snapdragon XR2 Gen 1';
      case SnapdragonFamily.xrPlatform:
        return 'Snapdragon XR';
      case SnapdragonFamily.other:
        return 'Other';
    }
  }

  String _deviceDisplayName(DeviceModelConfig config) {
    switch (config.deviceId) {
      case 'samsung_galaxy_xr':
        return 'Samsung Galaxy XR';
      case 'meta_quest_3':
        return 'Meta Quest 3';
      case 'meta_quest_pro':
        return 'Meta Quest Pro';
      case 'meta_quest_2':
        return 'Meta Quest 2';
      case 'htc_vive_xr':
        return 'HTC Vive XR';
      case 'pico_xr':
        return 'Pico XR';
      case 'pico_xr_flagship':
        return 'Pico XR (Flagship)';
      case 'xreal_ar_glasses':
        return 'XREAL AR Glasses';
      case 'samsung_ar_glasses':
        return 'Samsung AR Glasses';
      case 'xr_headset_generic':
        return 'XR Headset';
      default:
        return config.tier.name.toUpperCase();
    }
  }

  Widget _buildPipelineStatusCard(BuildContext context) {
    final asrName = _deviceConfig?.asrModel.displayName ?? 'Whisper';
    final llmName = _deviceConfig?.llmModel.displayName ?? 'Gemma';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _pipelineStatusRow(
                  asrName,
                  true, // Available (downloaded on demand)
                  Icons.mic,
                ),
                const SizedBox(width: 16),
                _pipelineStatusRow(
                  llmName,
                  true, // Available (downloaded on demand)
                  Icons.auto_awesome,
                ),
                const SizedBox(width: 16),
                _pipelineStatusRow(
                  'Translation',
                  true,
                  Icons.translate,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pipelineStatusRow(String label, bool ready, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: ready ? Colors.green : Colors.red),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$label ${ready ? '✓' : '✗'}',
              style: TextStyle(
                color: ready ? Colors.green : Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _llmBackendSubtitle(LlmBackend backend) {
    switch (backend) {
      case LlmBackend.omniNeural4B:
        return 'Multimodal (vision + language) — recommended for XR';
      case LlmBackend.smolVlm256M:
        return 'Lightweight multimodal (0.48 GB)';
      case LlmBackend.lfm2_1_2B:
        return 'Chat-only, lightweight NPU model (0.75 GB)';
      case LlmBackend.gemma3n:
        return 'CPU/GPU fallback';
      case LlmBackend.granite:
        return 'Legacy NPU model';
    }
  }

  List<DropdownMenuItem<LlmBackend>> _llmBackendDropdownItems(BuildContext context) {
    return LlmBackend.values.map((backend) {
      String displayName;
      bool isRecommended = false;

      switch (backend) {
        case LlmBackend.omniNeural4B:
          displayName = 'OmniNeural 4B';
          isRecommended = _isNpuDevice;
          break;
        case LlmBackend.smolVlm256M:
          displayName = 'SmolVLM 256M';
          break;
        case LlmBackend.lfm2_1_2B:
          displayName = 'LFM2 1.2B';
          break;
        case LlmBackend.gemma3n:
          displayName = 'Gemma 3n';
          isRecommended = !_isNpuDevice;
          break;
        case LlmBackend.granite:
          displayName = 'Granite';
          break;
      }

      return DropdownMenuItem<LlmBackend>(
        value: backend,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isRecommended)
              Icon(Icons.star, size: 16, color: _isNpuDevice ? Colors.green : Colors.amber),
            Flexible(child: Text(displayName)),
            if (isRecommended && _isNpuDevice)
              Text(' (NPU)', style: TextStyle(fontSize: 11, color: Colors.green)),
          ],
        ),
      );
    }).toList();
  }

  List<DropdownMenuItem<AsrBackend>> _asrBackendDropdownItems(
      BuildContext context) {
    return AsrBackend.values.map((backend) {
      String displayName;
      bool isEnabled = true;

      switch (backend) {
        case AsrBackend.flutterSound:
          displayName = 'Flutter Sound';
          break;
        case AsrBackend.gemma3n:
          displayName = 'Gemma 3n';
          break;
        case AsrBackend.native:
          displayName = 'Native';
          break;
        case AsrBackend.nexaParakeet:
          displayName = 'Nexa Parakeet';
          break;
        case AsrBackend.openAI:
          displayName = 'OpenAI';
          isEnabled = false;
          break;
        case AsrBackend.whisperGgml:
          displayName = 'Whisper';
          break;
      }

      final isRecommended = _isNpuDevice && backend == AsrBackend.nexaParakeet;

      return DropdownMenuItem<AsrBackend>(
        value: backend,
        enabled: isEnabled,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (backend == AsrBackend.whisperGgml && !_isNpuDevice)
              Icon(Icons.star, size: 16, color: Colors.amber),
            if (isRecommended)
              Icon(Icons.star, size: 16, color: Colors.green),
            Flexible(
              child: !isEnabled
                  ? Opacity(opacity: 0.5, child: Text(displayName))
                  : Text(displayName),
            ),
            if (isRecommended)
              Text(' (NPU)',
                  style: TextStyle(fontSize: 11, color: Colors.green)),
            if (!isEnabled)
              Tooltip(
                message: 'Disabled for now (requires paid API)',
                child: Icon(Icons.lock, size: 16, color: Colors.grey),
              ),
          ],
        ),
      );
    }).toList();
  }
}

SpeechEngine _asrBackendToSpeechEngine(AsrBackend backend) {
  switch (backend) {
    case AsrBackend.flutterSound:
      return SpeechEngine.flutter_sound;
    case AsrBackend.gemma3n:
      return SpeechEngine.gemma3n;
    case AsrBackend.native:
      return SpeechEngine.native;
    case AsrBackend.nexaParakeet:
      return SpeechEngine.nexa_asr;
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
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: SizedBox(width: 160, child: trailing),
    ),
  );
}
