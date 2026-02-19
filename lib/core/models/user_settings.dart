/// Enum for selecting the ASR backend/engine.
enum AsrBackend {
  flutterSound,
  gemma3n,
  native,
  nexaParakeet,
  openAI,
  whisperGgml,
}

/// Enum for selecting the LLM/enhancement backend.
enum LlmBackend {
  /// OmniNeural 4B — multimodal (vision + language), recommended for XR
  omniNeural4B,
  /// SmolVLM 256M — lightweight multimodal option
  smolVlm256M,
  /// LFM2 1.2B — chat-only, lighter weight NPU model
  lfm2_1_2B,
  /// Gemma 3n — CPU/GPU fallback
  gemma3n,
  /// Granite — legacy NPU option
  granite,
}

/// Enum for selecting the Speech-to-Text (STT) mode.
enum SttMode {
  /// Uses a cloud-based STT service for higher accuracy.
  online,

  /// Uses an on-device STT model for privacy and offline use.
  offline,
}

/// Model representing user-configurable settings.
///
/// As defined in `prd/19_livecaptionsxr_multistage_captioning_pipeline.md`.
class UserSettings {
  /// The selected STT mode (online or offline).
  final SttMode sttMode;

  /// The selected ASR backend/engine.
  final AsrBackend asrBackend;

  /// The selected LLM/enhancement backend.
  final LlmBackend llmBackend;

  /// Whether contextual enhancement of captions is enabled.
  final bool enhancementEnabled;

  /// Whether haptic feedback is enabled.
  final bool hapticsEnabled;

  /// Whether LED alerts are enabled.
  final bool ledAlertsEnabled;

  /// Font size for captions, as a scale factor.
  final double captionFontSize;

  /// High contrast mode for captions.
  final bool highContrastEnabled;
  final bool accessibilityCaptionModeEnabled;
  final bool speakerFocusModeEnabled;
  final bool debugLoggingOverlayEnabled;
  final bool rawSttDebugLineEnabled;

  /// Whether spatial localization (speaker direction tracking) is enabled.
  final bool spatialLocalizationEnabled;

  /// Sensitivity for speaker localization (0.1–1.0).
  final double localizationSensitivity;

  /// How long captions stay visible (seconds).
  final double captionDurationSeconds;

  /// Maximum number of captions shown at once.
  final int maxVisibleCaptions;

  const UserSettings({
    this.sttMode = SttMode.offline,
    this.asrBackend = AsrBackend.whisperGgml,
    this.llmBackend = LlmBackend.gemma3n,
    this.enhancementEnabled = true,
    this.hapticsEnabled = true,
    this.ledAlertsEnabled = true,
    this.captionFontSize = 1.0,
    this.highContrastEnabled = false,
    this.accessibilityCaptionModeEnabled = false,
    this.speakerFocusModeEnabled = false,
    this.debugLoggingOverlayEnabled = true,
    this.rawSttDebugLineEnabled = true,
    this.spatialLocalizationEnabled = true,
    this.localizationSensitivity = 0.5,
    this.captionDurationSeconds = 6.0,
    this.maxVisibleCaptions = 5,
  });

  /// Create a copy of the settings with modified properties.
  UserSettings copyWith({
    SttMode? sttMode,
    AsrBackend? asrBackend,
    LlmBackend? llmBackend,
    bool? enhancementEnabled,
    bool? hapticsEnabled,
    bool? ledAlertsEnabled,
    double? captionFontSize,
    bool? highContrastEnabled,
    bool? accessibilityCaptionModeEnabled,
    bool? speakerFocusModeEnabled,
    bool? debugLoggingOverlayEnabled,
    bool? rawSttDebugLineEnabled,
    bool? spatialLocalizationEnabled,
    double? localizationSensitivity,
    double? captionDurationSeconds,
    int? maxVisibleCaptions,
  }) {
    return UserSettings(
      sttMode: sttMode ?? this.sttMode,
      asrBackend: asrBackend ?? this.asrBackend,
      llmBackend: llmBackend ?? this.llmBackend,
      enhancementEnabled: enhancementEnabled ?? this.enhancementEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      ledAlertsEnabled: ledAlertsEnabled ?? this.ledAlertsEnabled,
      captionFontSize: captionFontSize ?? this.captionFontSize,
      highContrastEnabled: highContrastEnabled ?? this.highContrastEnabled,
      accessibilityCaptionModeEnabled:
          accessibilityCaptionModeEnabled ?? this.accessibilityCaptionModeEnabled,
      speakerFocusModeEnabled:
          speakerFocusModeEnabled ?? this.speakerFocusModeEnabled,
      debugLoggingOverlayEnabled:
          debugLoggingOverlayEnabled ?? this.debugLoggingOverlayEnabled,
        rawSttDebugLineEnabled:
          rawSttDebugLineEnabled ?? this.rawSttDebugLineEnabled,
      spatialLocalizationEnabled:
          spatialLocalizationEnabled ?? this.spatialLocalizationEnabled,
      localizationSensitivity:
          localizationSensitivity ?? this.localizationSensitivity,
      captionDurationSeconds:
          captionDurationSeconds ?? this.captionDurationSeconds,
      maxVisibleCaptions: maxVisibleCaptions ?? this.maxVisibleCaptions,
    );
  }

  /// Convert to JSON for persistence.
  Map<String, dynamic> toJson() {
    return {
      'sttMode': sttMode.name,
      'asrBackend': asrBackend.name,
      'llmBackend': llmBackend.name,
      'enhancementEnabled': enhancementEnabled,
      'hapticsEnabled': hapticsEnabled,
      'ledAlertsEnabled': ledAlertsEnabled,
      'captionFontSize': captionFontSize,
      'highContrastEnabled': highContrastEnabled,
      'accessibilityCaptionModeEnabled': accessibilityCaptionModeEnabled,
      'speakerFocusModeEnabled': speakerFocusModeEnabled,
      'debugLoggingOverlayEnabled': debugLoggingOverlayEnabled,
      'rawSttDebugLineEnabled': rawSttDebugLineEnabled,
      'spatialLocalizationEnabled': spatialLocalizationEnabled,
      'localizationSensitivity': localizationSensitivity,
      'captionDurationSeconds': captionDurationSeconds,
      'maxVisibleCaptions': maxVisibleCaptions,
    };
  }

  static AsrBackend _parseAsrBackend(String name) {
    try {
      return AsrBackend.values.byName(name);
    } catch (_) {
      return AsrBackend.whisperGgml;
    }
  }

  static LlmBackend _parseLlmBackend(String name) {
    try {
      return LlmBackend.values.byName(name);
    } catch (_) {
      return LlmBackend.gemma3n;
    }
  }

  /// Create from JSON.
  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      sttMode: SttMode.values.byName(json['sttMode'] as String? ?? 'online'),
      asrBackend: _parseAsrBackend(json['asrBackend'] as String? ?? 'whisperGgml'),
      llmBackend: _parseLlmBackend(json['llmBackend'] as String? ?? 'gemma3n'),
      enhancementEnabled: json['enhancementEnabled'] as bool? ?? true,
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
      ledAlertsEnabled: json['ledAlertsEnabled'] as bool? ?? true,
      captionFontSize: (json['captionFontSize'] as num?)?.toDouble() ?? 1.0,
      highContrastEnabled: json['highContrastEnabled'] as bool? ?? false,
      accessibilityCaptionModeEnabled:
          json['accessibilityCaptionModeEnabled'] as bool? ?? false,
      speakerFocusModeEnabled:
          json['speakerFocusModeEnabled'] as bool? ?? false,
      debugLoggingOverlayEnabled:
          json['debugLoggingOverlayEnabled'] as bool? ?? false,
        rawSttDebugLineEnabled:
          json['rawSttDebugLineEnabled'] as bool? ?? true,
      spatialLocalizationEnabled:
          json['spatialLocalizationEnabled'] as bool? ?? true,
      localizationSensitivity:
          (json['localizationSensitivity'] as num?)?.toDouble() ?? 0.5,
      captionDurationSeconds:
          (json['captionDurationSeconds'] as num?)?.toDouble() ?? 6.0,
      maxVisibleCaptions:
          json['maxVisibleCaptions'] as int? ?? 5,
    );
  }
}
