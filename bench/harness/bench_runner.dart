import 'dart:convert';
import 'dart:io';

import 'package:live_captions_xr/core/models/speech_result.dart';
import 'package:live_captions_xr/spatial_intel/predict/predictive_caption_engine.dart';
import 'package:live_captions_xr/spatial_intel/decoding/decode_policy.dart';

import 'metrics.dart';
import 'realtime_replay.dart';

class BenchmarkScenario {
  BenchmarkScenario({
    required this.name,
    required this.clipPath,
    this.policyOverrides,
  });

  final String name;
  final String clipPath;
  final Map<String, dynamic>? policyOverrides;
}

class BenchmarkRunner {
  BenchmarkRunner({
    required PredictiveCaptionEngine captionEngine,
  }) : _engine = captionEngine;

  final PredictiveCaptionEngine _engine;

  Future<Map<String, dynamic>> run(BenchmarkScenario scenario) async {
    await _engine.initialize();
    if (scenario.policyOverrides != null) {
      final policy =
          DecodePolicy.fromMap(scenario.policyOverrides as Map<dynamic, dynamic>);
      _engine.updatePolicy(policy);
    }

    final frames = await _loadFrames(scenario.clipPath);
    final metrics = MetricsAggregator();
    final replay = RealtimeReplay(
      frames: frames,
      onFrame: (frame) async {
        final type = frame.payload['type'] as String?;
        if (type == 'speech') {
          final result = SpeechResult(
            text: frame.payload['text'] as String,
            confidence: (frame.payload['confidence'] as num).toDouble(),
            isFinal: frame.payload['isFinal'] as bool,
            timestamp: DateTime.now(),
          );
          _engine.handleSpeechResult(result);
          metrics.recordTokenLifecycle(
            TokenLifecycle(
              partialLatency: Duration(
                milliseconds:
                    (frame.payload['partialLatencyMs'] as num?)?.toInt() ?? 0,
              ),
              commitLatency: Duration(
                milliseconds:
                    (frame.payload['commitLatencyMs'] as num?)?.toInt() ?? 0,
              ),
              changedAfterDisplay:
                  frame.payload['changedAfterDisplay'] as bool? ?? false,
            ),
          );
        } else if (type == 'prediction') {
          metrics.recordPrediction(
            PredictionRecord(
              probability:
                  (frame.payload['probability'] as num?)?.toDouble() ?? 0.0,
              outcome: frame.payload['outcome'] as bool? ?? false,
            ),
          );
        } else if (type == 'spatial') {
          metrics.recordSpatial(
            SpatialRecord(
              angularErrorDeg:
                  (frame.payload['angularErrorDeg'] as num?)?.toDouble() ?? 0.0,
              anchorJitterDps:
                  (frame.payload['jitterDps'] as num?)?.toDouble() ?? 0.0,
              occlusionRate:
                  (frame.payload['occlusionPct'] as num?)?.toDouble() ?? 0.0,
            ),
          );
        } else if (type == 'performance') {
          metrics.recordPerformance(
            PerformanceRecord(
              cpuPercent:
                  (frame.payload['cpu'] as num?)?.toDouble() ?? 0.0,
              gpuPercent:
                  (frame.payload['gpu'] as num?)?.toDouble() ?? 0.0,
              memoryMb:
                  (frame.payload['memoryMb'] as num?)?.toDouble() ?? 0.0,
              deviceTempC:
                  (frame.payload['deviceTempC'] as num?)?.toDouble() ?? 0.0,
              batteryMw:
                  (frame.payload['batteryMw'] as num?)?.toDouble() ?? 0.0,
            ),
          );
        }
      },
    );
    await replay.start();
    return {
      'scenario': scenario.name,
      'metrics': metrics.summary(),
    };
  }

  Future<List<ReplayFrame>> _loadFrames(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw ArgumentError('Benchmark clip not found: $path');
    }
    final lines = await file.readAsLines();
    final frames = <ReplayFrame>[];
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final json = jsonDecode(line) as Map<String, dynamic>;
      frames.add(
        ReplayFrame(
          offset: Duration(milliseconds: (json['offsetMs'] as num).toInt()),
          payload: json['payload'] as Map<String, dynamic>,
        ),
      );
    }
    return frames;
  }
}

