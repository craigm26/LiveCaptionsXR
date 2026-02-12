class SamplerConfig {
  final double? temperature;
  final int? topK;
  final double? topP;
  final double? minP;
  final double? repeatPenalty;
  final double? presencePenalty;
  final double? frequencyPenalty;
  final String? grammarString;

  SamplerConfig({
    this.temperature,
    this.topK,
    this.topP,
    this.minP,
    this.repeatPenalty,
    this.presencePenalty,
    this.frequencyPenalty,
    this.grammarString,
  });

  Map<String, dynamic> toMap() {
    return {
      if (temperature != null) 'temperature': temperature,
      if (topK != null) 'topK': topK,
      if (topP != null) 'topP': topP,
      if (minP != null) 'minP': minP,
      if (repeatPenalty != null) 'repeatPenalty': repeatPenalty,
      if (presencePenalty != null) 'presencePenalty': presencePenalty,
      if (frequencyPenalty != null) 'frequencyPenalty': frequencyPenalty,
      if (grammarString != null) 'grammarString': grammarString,
    };
  }
}

class GenerationConfig {
  final int? maxTokens;
  final List<String>? stopWords;
  final int? stopCount;
  final int? nPast;
  final SamplerConfig? samplerConfig;
  final List<String>? imagePaths;
  final int? imageCount;
  final List<String>? audioPaths;
  final int? audioCount;

  GenerationConfig({
    this.maxTokens,
    this.stopWords,
    this.stopCount,
    this.nPast,
    this.samplerConfig,
    this.imagePaths,
    this.imageCount,
    this.audioPaths,
    this.audioCount,
  });

  Map<String, dynamic> toMap() {
    return {
      if (maxTokens != null) 'maxTokens': maxTokens,
      if (stopWords != null) 'stopWords': stopWords,
      if (stopCount != null) 'stopCount': stopCount,
      if (nPast != null) 'nPast': nPast,
      if (samplerConfig != null) 'samplerConfig': samplerConfig!.toMap(),
      if (imagePaths != null) 'imagePaths': imagePaths,
      if (imageCount != null) 'imageCount': imageCount,
      if (audioPaths != null) 'audioPaths': audioPaths,
      if (audioCount != null) 'audioCount': audioCount,
    };
  }
}
