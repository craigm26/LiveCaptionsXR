# Predictive Caption Calibration & Dataset Notes

## XR-Captions-Mini Corpus
- Target 3–5 hours of recordings with 2–3 speakers per scene across quiet, café, and street environments.
- Capture synchronized assets: 16 kHz mono + stereo audio, RGB/depth frames, pose traces, mic-array DOA estimates, and diarization labels.
- Annotate transcripts with token timestamps, partial vs. final commits, and speaker IDs. Store as JSONL with offsets in milliseconds.
- Record noise-only segments to learn ambient profiles (`noise_profile_id`) for biasing decode and for online calibration drift detection.

## Calibration Workflow
1. Export prediction logs from the benchmarking harness (`bench/harness`) capturing raw probabilities, commit decisions, and ground-truth outcomes.
2. Use `ProbabilityCalibrator` (temperature + isotonic) to fit per-domain curves:
   ```dart
   final calibrator = ProbabilityCalibrator(
     temperature: 1.1,
     isotonicCurve: domainPoints,
   );
   ```
3. Persist calibrator configs under `assets/spatial_intel/calibration/<domain>.json` (not yet committed). Load into `PredictiveCaptionEngine` at start-up.
4. Track calibration drift using `CalibrationStats` from `PredictiveCaptionEngine.calibrator.snapshot()` and alert when ECE exceeds 0.05.

## Gemma 3n Fine-Tuning Hints
- Multi-task objective: ASR next-token cross entropy + direction regression + diarization classification + commit-gate prediction.
- Curriculum: near-field clean → add noise/reverb → far-field.
- Apply quantization-aware training to target int8/float16 TFLite deployment; export to `models/gemma3n_task`.
- Distill from higher-capacity offline ASR to accelerate convergence; use teacher logits to seed deterministic decoding thresholds (`policies.yaml`).

## Whisper Streaming Integration
- Whisper GGML remains baseline streaming engine; deterministic decoding toggled via `DecodePolicy` (`temperature=0`, `top_k=1`).
- Use benchmarking harness to compare Whisper vs. Gemma pathways end-to-end; log JSONL results and aggregate with `bench/reports/make_report.py`.

