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

  const UserSettings({
    this.sttMode = SttMode.online,
    this.enhancementEnabled = true,
    this.hapticsEnabled = true,
    this.ledAlertsEnabled = true,
    this.captionFontSize = 1.0,
    this.highContrastEnabled = false,
  });

  /// Create a copy of the settings with modified properties.
  UserSettings copyWith({
    SttMode? sttMode,
    bool? enhancementEnabled,
    bool? hapticsEnabled,
    bool? ledAlertsEnabled,
    double? captionFontSize,
    bool? highContrastEnabled,
  }) {
    return UserSettings(
      sttMode: sttMode ?? this.sttMode,
      enhancementEnabled: enhancementEnabled ?? this.enhancementEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      ledAlertsEnabled: ledAlertsEnabled ?? this.ledAlertsEnabled,
      captionFontSize: captionFontSize ?? this.captionFontSize,
      highContrastEnabled: highContrastEnabled ?? this.highContrastEnabled,
    );
  }

  /// Convert to JSON for persistence.
  Map<String, dynamic> toJson() {
    return {
      'sttMode': sttMode.name,
      'enhancementEnabled': enhancementEnabled,
      'hapticsEnabled': hapticsEnabled,
      'ledAlertsEnabled': ledAlertsEnabled,
      'captionFontSize': captionFontSize,
      'highContrastEnabled': highContrastEnabled,
    };
  }

  /// Create from JSON.
  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      sttMode: SttMode.values.byName(json['sttMode'] as String? ?? 'online'),
      enhancementEnabled: json['enhancementEnabled'] as bool? ?? true,
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
      ledAlertsEnabled: json['ledAlertsEnabled'] as bool? ?? true,
      captionFontSize: (json['captionFontSize'] as num?)?.toDouble() ?? 1.0,
      highContrastEnabled: json['highContrastEnabled'] as bool? ?? false,
    );
  }
} 