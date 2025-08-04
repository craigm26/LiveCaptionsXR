import 'package:equatable/equatable.dart';

/// Configuration class for speech processing parameters
class SpeechConfig extends Equatable {
  final double voiceActivityThreshold;
  final double finalResultThreshold;
  final int bufferSizeMs;
  final int interimResultIntervalMs;
  final int finalResultIntervalMs;
  final String language;
  final List<String> supportedLanguages;
  final bool enableLanguageDetection;
  final bool enableRealTimeEnhancement;
  final double enhancementTemperature;
  final int enhancementMaxTokens;
  
  // Whisper-specific configuration
  final String whisperModel;
  final bool whisperTranslateToEnglish;
  final int whisperMaxTokens;
  final double whisperTemperature;
  final bool whisperSuppressNonSpeechTokens;
  
  // Apple Speech specific configuration
  final bool forceOfflineMode;

  const SpeechConfig({
    this.voiceActivityThreshold = 0.01,
    this.finalResultThreshold = 0.005,
    this.bufferSizeMs = 2000,
    this.interimResultIntervalMs = 1000,
    this.finalResultIntervalMs = 3000,
    this.language = 'en',
    this.supportedLanguages = const ['en', 'es', 'fr', 'de', 'it', 'pt', 'zh'],
    this.enableLanguageDetection = false,
    this.enableRealTimeEnhancement = true,
    this.enhancementTemperature = 0.3,
    this.enhancementMaxTokens = 100,
    this.whisperModel = 'base',
    this.whisperTranslateToEnglish = false,
    this.whisperMaxTokens = 448,
    this.whisperTemperature = 0.0,
    this.whisperSuppressNonSpeechTokens = true,
    this.forceOfflineMode = false,
  });

  /// Create config with custom parameters
  SpeechConfig copyWith({
    double? voiceActivityThreshold,
    double? finalResultThreshold,
    int? bufferSizeMs,
    int? interimResultIntervalMs,
    int? finalResultIntervalMs,
    String? language,
    List<String>? supportedLanguages,
    bool? enableLanguageDetection,
    bool? enableRealTimeEnhancement,
    double? enhancementTemperature,
    int? enhancementMaxTokens,
    String? whisperModel,
    bool? whisperTranslateToEnglish,
    int? whisperMaxTokens,
    double? whisperTemperature,
    bool? whisperSuppressNonSpeechTokens,
    bool? forceOfflineMode,
  }) {
    return SpeechConfig(
      voiceActivityThreshold: voiceActivityThreshold ?? this.voiceActivityThreshold,
      finalResultThreshold: finalResultThreshold ?? this.finalResultThreshold,
      bufferSizeMs: bufferSizeMs ?? this.bufferSizeMs,
      interimResultIntervalMs: interimResultIntervalMs ?? this.interimResultIntervalMs,
      finalResultIntervalMs: finalResultIntervalMs ?? this.finalResultIntervalMs,
      language: language ?? this.language,
      supportedLanguages: supportedLanguages ?? this.supportedLanguages,
      enableLanguageDetection: enableLanguageDetection ?? this.enableLanguageDetection,
      enableRealTimeEnhancement: enableRealTimeEnhancement ?? this.enableRealTimeEnhancement,
      enhancementTemperature: enhancementTemperature ?? this.enhancementTemperature,
      enhancementMaxTokens: enhancementMaxTokens ?? this.enhancementMaxTokens,
      whisperModel: whisperModel ?? this.whisperModel,
      whisperTranslateToEnglish: whisperTranslateToEnglish ?? this.whisperTranslateToEnglish,
      whisperMaxTokens: whisperMaxTokens ?? this.whisperMaxTokens,
      whisperTemperature: whisperTemperature ?? this.whisperTemperature,
      whisperSuppressNonSpeechTokens: whisperSuppressNonSpeechTokens ?? this.whisperSuppressNonSpeechTokens,
      forceOfflineMode: forceOfflineMode ?? this.forceOfflineMode,
    );
  }

  /// Convert to map for platform communication
  Map<String, dynamic> toMap() {
    return {
      'voiceActivityThreshold': voiceActivityThreshold,
      'finalResultThreshold': finalResultThreshold,
      'bufferSizeMs': bufferSizeMs,
      'interimResultIntervalMs': interimResultIntervalMs,
      'finalResultIntervalMs': finalResultIntervalMs,
      'language': language,
      'supportedLanguages': supportedLanguages,
      'enableLanguageDetection': enableLanguageDetection,
      'enableRealTimeEnhancement': enableRealTimeEnhancement,
      'enhancementTemperature': enhancementTemperature,
      'enhancementMaxTokens': enhancementMaxTokens,
      'whisperModel': whisperModel,
      'whisperTranslateToEnglish': whisperTranslateToEnglish,
      'whisperMaxTokens': whisperMaxTokens,
      'whisperTemperature': whisperTemperature,
      'whisperSuppressNonSpeechTokens': whisperSuppressNonSpeechTokens,
    };
  }

  /// Create from map
  factory SpeechConfig.fromMap(Map<String, dynamic> map) {
    return SpeechConfig(
      voiceActivityThreshold: map['voiceActivityThreshold']?.toDouble() ?? 0.01,
      finalResultThreshold: map['finalResultThreshold']?.toDouble() ?? 0.005,
      bufferSizeMs: map['bufferSizeMs']?.toInt() ?? 2000,
      interimResultIntervalMs: map['interimResultIntervalMs']?.toInt() ?? 1000,
      finalResultIntervalMs: map['finalResultIntervalMs']?.toInt() ?? 3000,
      language: map['language'] ?? 'en',
      supportedLanguages: List<String>.from(map['supportedLanguages'] ?? ['en', 'es', 'fr', 'de', 'it', 'pt', 'zh']),
      enableLanguageDetection: map['enableLanguageDetection'] ?? false,
      enableRealTimeEnhancement: map['enableRealTimeEnhancement'] ?? true,
      enhancementTemperature: map['enhancementTemperature']?.toDouble() ?? 0.3,
      enhancementMaxTokens: map['enhancementMaxTokens']?.toInt() ?? 100,
      whisperModel: map['whisperModel'] ?? 'base',
      whisperTranslateToEnglish: map['whisperTranslateToEnglish'] ?? false,
      whisperMaxTokens: map['whisperMaxTokens']?.toInt() ?? 448,
      whisperTemperature: map['whisperTemperature']?.toDouble() ?? 0.0,
      whisperSuppressNonSpeechTokens: map['whisperSuppressNonSpeechTokens'] ?? true,
    );
  }

  /// Default config for different environments
  static const SpeechConfig lowLatency = SpeechConfig(
    voiceActivityThreshold: 0.02,
    finalResultThreshold: 0.01,
    bufferSizeMs: 1000,
    interimResultIntervalMs: 500,
    finalResultIntervalMs: 2000,
    enableRealTimeEnhancement: false,
  );

  static const SpeechConfig highAccuracy = SpeechConfig(
    voiceActivityThreshold: 0.005,
    finalResultThreshold: 0.002,
    bufferSizeMs: 3000,
    interimResultIntervalMs: 1500,
    finalResultIntervalMs: 4000,
    enableRealTimeEnhancement: true,
    enhancementTemperature: 0.1,
  );

  static const SpeechConfig multilingual = SpeechConfig(
    voiceActivityThreshold: 0.01,
    finalResultThreshold: 0.005,
    enableLanguageDetection: true,
    enableRealTimeEnhancement: true,
    supportedLanguages: ['en', 'es', 'fr', 'de', 'it', 'pt', 'zh', 'ja', 'ko', 'ar'],
  );

  @override
  List<Object?> get props => [
        voiceActivityThreshold,
        finalResultThreshold,
        bufferSizeMs,
        interimResultIntervalMs,
        finalResultIntervalMs,
        language,
        supportedLanguages,
        enableLanguageDetection,
        enableRealTimeEnhancement,
        enhancementTemperature,
        enhancementMaxTokens,
        whisperModel,
        whisperTranslateToEnglish,
        whisperMaxTokens,
        whisperTemperature,
        whisperSuppressNonSpeechTokens,
        forceOfflineMode,
      ];

  @override
  String toString() {
    return 'SpeechConfig(lang: $language, vad: $voiceActivityThreshold, enhancement: $enableRealTimeEnhancement)';
  }
}