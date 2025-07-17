/// Enum for selecting the ASR backend/engine.
enum AsrBackend {
  flutterSound,
  gemma3n,
  native,
  openAI,
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
    this.sttMode = SttMode.online,
    this.asrBackend = AsrBackend.flutterSound,
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
      'enhancementEnabled': enhancementEnabled,
      'hapticsEnabled': hapticsEnabled,
      'ledAlertsEnabled': ledAlertsEnabled,
      'captionFontSize': captionFontSize,
      'highContrastEnabled': highContrastEnabled,
      'debugLoggingOverlayEnabled': debugLoggingOverlayEnabled,
    };
  }

  /// Create from JSON.
  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      sttMode: SttMode.values.byName(json['sttMode'] as String? ?? 'online'),
      asrBackend: AsrBackend.values
          .byName(json['asrBackend'] as String? ?? 'flutterSound'),
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
