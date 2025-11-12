# Predictive Caption Validation Checklist

1. **Replay Benchmarks**
   - Run `dart run bench/harness/bench_runner.dart <scenario.jsonl>` for deterministic clips.
   - Aggregate results: `python bench/reports/make_report.py bench/logs/*.jsonl`.
   - Verify TTC ≤ 400 ms (p95) and edit flicker rate ≤ 5%.

2. **Calibration Drift**
   - Capture calibration snapshot via `PredictiveCaptionEngine.calibrator.snapshot()`.
   - Alert if ECE > 0.05 or Brier > 0.12; reload per-domain calibrators from `assets/spatial_intel/calibration/`.

3. **Spatial Anchoring**
   - Inspect logs for angular error mean ≤ 10° and jitter ≤ 6°/s.
   - Confirm occlusion watchdog triggers neutral rail when face overlap > 8%.

4. **Performance Budgets**
   - Ensure CPU < 40%, GPU < 35%, memory < 900 MB, battery drain < 2200 mW on target device during replay.

5. **Fallback Behaviour**
   - Simulate loss of DOA or vision; verify `SpatialAnchorCoordinator` returns neutral rail positions without crashes.

6. **UI Consistency**
   - Confirm ghost tokens fade-in with `policy.ghostAlpha`, committed tokens bolden, and revoked tokens strike-through.

