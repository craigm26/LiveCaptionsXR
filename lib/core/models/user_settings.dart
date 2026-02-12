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
  final bool debugLoggingOverlayEnabled;

  const UserSettings({
    this.sttMode = SttMode.offline,
    this.asrBackend = AsrBackend.whisperGgml,
    this.llmBackend = LlmBackend.gemma3n,
    this.enhancementEnabled = true,
    this.hapticsEnabled = true,
    this.ledAlertsEnabled = true,
    this.captionFontSize = 1.0,
    this.highContrastEnabled = false,
    this.debugLoggingOverlayEnabled = true,
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
    bool? debugLoggingOverlayEnabled,
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
      debugLoggingOverlayEnabled:
          debugLoggingOverlayEnabled ?? this.debugLoggingOverlayEnabled,
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
      'debugLoggingOverlayEnabled': debugLoggingOverlayEnabled,
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
      debugLoggingOverlayEnabled:
          json['debugLoggingOverlayEnabled'] as bool? ?? false,
    );
  }
}
