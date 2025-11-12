import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

/// Configuration driving deterministic decoding, stability gates, and placement.
class DecodePolicy {
  DecodePolicy({
    required this.deterministic,
    required this.temperature,
    required this.topK,
    required this.grammarEnabled,
    required this.grammarPaths,
    required this.tokenProbMin,
    required this.entropyMax,
    required this.spanProbMin,
    required this.ghostAlpha,
    required this.commitFade,
    required this.unreadableRecenter,
    required this.azimuthGateDeg,
    required this.jitterMaxDps,
    required this.faceOcclusionPctMax,
  });

  final bool deterministic;
  final double temperature;
  final int topK;
  final bool grammarEnabled;
  final List<String> grammarPaths;
  final double tokenProbMin;
  final double entropyMax;
  final double spanProbMin;
  final double ghostAlpha;
  final Duration commitFade;
  final bool unreadableRecenter;
  final double azimuthGateDeg;
  final double jitterMaxDps;
  final double faceOcclusionPctMax;

  static DecodePolicy defaultPolicy() {
    return DecodePolicy(
      deterministic: true,
      temperature: 0.0,
      topK: 1,
      grammarEnabled: true,
      grammarPaths: const [],
      tokenProbMin: 0.8,
      entropyMax: 1.2,
      spanProbMin: 0.75,
      ghostAlpha: 0.35,
      commitFade: const Duration(milliseconds: 120),
      unreadableRecenter: true,
      azimuthGateDeg: 12,
      jitterMaxDps: 6,
      faceOcclusionPctMax: 8,
    );
  }

  factory DecodePolicy.fromMap(Map<dynamic, dynamic> map) {
    final decode = map['decode'] as Map? ?? const {};
    final stability = map['stability'] as Map? ?? const {};
    final ui = map['ui'] as Map? ?? const {};
    final placement = map['placement'] as Map? ?? const {};

    return DecodePolicy(
      deterministic: (decode['mode'] as String?)?.toLowerCase() == 'deterministic',
      temperature: (decode['temperature'] as num?)?.toDouble() ?? 0.0,
      topK: (decode['top_k'] as num?)?.toInt() ?? 1,
      grammarEnabled: (decode['grammar'] as Map?)?['enable'] as bool? ?? false,
      grammarPaths: ((decode['grammar'] as Map?)?['paths'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      tokenProbMin: (stability['token_prob_min'] as num?)?.toDouble() ?? 0.8,
      entropyMax: (stability['entropy_max'] as num?)?.toDouble() ?? 1.2,
      spanProbMin: (stability['span_prob_min'] as num?)?.toDouble() ?? 0.75,
      ghostAlpha: (ui['ghost_alpha'] as num?)?.toDouble() ?? 0.35,
      commitFade: Duration(
        milliseconds: (ui['commit_fade_ms'] as num?)?.toInt() ?? 120,
      ),
      unreadableRecenter: ui['unreadable_recenter'] as bool? ?? true,
      azimuthGateDeg: (placement['azimuth_gate_deg'] as num?)?.toDouble() ?? 12,
      jitterMaxDps: (placement['jitter_max_dps'] as num?)?.toDouble() ?? 6,
      faceOcclusionPctMax:
          (placement['face_occlusion_pct_max'] as num?)?.toDouble() ?? 8,
    );
  }

  DecodePolicy copyWith({
    bool? deterministic,
    double? temperature,
    int? topK,
    bool? grammarEnabled,
    List<String>? grammarPaths,
    double? tokenProbMin,
    double? entropyMax,
    double? spanProbMin,
    double? ghostAlpha,
    Duration? commitFade,
    bool? unreadableRecenter,
    double? azimuthGateDeg,
    double? jitterMaxDps,
    double? faceOcclusionPctMax,
  }) {
    return DecodePolicy(
      deterministic: deterministic ?? this.deterministic,
      temperature: temperature ?? this.temperature,
      topK: topK ?? this.topK,
      grammarEnabled: grammarEnabled ?? this.grammarEnabled,
      grammarPaths: grammarPaths ?? this.grammarPaths,
      tokenProbMin: tokenProbMin ?? this.tokenProbMin,
      entropyMax: entropyMax ?? this.entropyMax,
      spanProbMin: spanProbMin ?? this.spanProbMin,
      ghostAlpha: ghostAlpha ?? this.ghostAlpha,
      commitFade: commitFade ?? this.commitFade,
      unreadableRecenter: unreadableRecenter ?? this.unreadableRecenter,
      azimuthGateDeg: azimuthGateDeg ?? this.azimuthGateDeg,
      jitterMaxDps: jitterMaxDps ?? this.jitterMaxDps,
      faceOcclusionPctMax: faceOcclusionPctMax ?? this.faceOcclusionPctMax,
    );
  }
}

/// Loader that resolves policy files (YAML) from assets.
class DecodePolicyLoader {
  DecodePolicyLoader({this.assetPath = 'assets/spatial_intel/decoding/policies.yaml'});

  final String assetPath;
  DecodePolicy? _cachedPolicy;

  Future<DecodePolicy> load() async {
    if (_cachedPolicy != null) {
      return _cachedPolicy!;
    }
    try {
      final yamlString = await rootBundle.loadString(assetPath);
      final dynamic yaml = loadYaml(yamlString);
      if (yaml is YamlMap) {
        final json = jsonDecode(jsonEncode(yaml)) as Map<String, dynamic>;
        _cachedPolicy = DecodePolicy.fromMap(json);
        return _cachedPolicy!;
      }
    } catch (_) {
      // Fall through to default
    }
    _cachedPolicy = DecodePolicy.defaultPolicy();
    return _cachedPolicy!;
  }

  void invalidateCache() {
    _cachedPolicy = null;
  }
}

