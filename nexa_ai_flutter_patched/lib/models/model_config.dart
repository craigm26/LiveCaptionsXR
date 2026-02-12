class ModelConfig {
  final int? nCtx;
  final int? maxTokens;
  final bool? enableThinking;
  final String? npuLibFolderPath;
  final String? npuModelFolderPath;

  ModelConfig({
    this.nCtx,
    this.maxTokens,
    this.enableThinking,
    this.npuLibFolderPath,
    this.npuModelFolderPath,
  });

  Map<String, dynamic> toMap() {
    return {
      if (nCtx != null) 'nCtx': nCtx,
      if (maxTokens != null) 'maxTokens': maxTokens,
      if (enableThinking != null) 'enableThinking': enableThinking,
      if (npuLibFolderPath != null) 'npuLibFolderPath': npuLibFolderPath,
      if (npuModelFolderPath != null) 'npuModelFolderPath': npuModelFolderPath,
    };
  }

  factory ModelConfig.fromMap(Map<String, dynamic> map) {
    return ModelConfig(
      nCtx: map['nCtx'] as int?,
      maxTokens: map['maxTokens'] as int?,
      enableThinking: map['enableThinking'] as bool?,
      npuLibFolderPath: map['npuLibFolderPath'] as String?,
      npuModelFolderPath: map['npuModelFolderPath'] as String?,
    );
  }
}
