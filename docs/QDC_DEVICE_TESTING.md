# QDC/Qualcomm Device Testing Results

## Tested Devices

| Device | Chipset | Android Version | Test Date | Tester |
|--------|---------|-----------------|-----------|--------|
| *TBD* | Snapdragon 8 Gen X | | | |

## NPU Performance Benchmarks

| Metric | NPU | GPU | CPU | Target |
|--------|-----|-----|-----|--------|
| ASR Latency (ms) | | | | <500ms |
| LLM Tokens/sec | | | | >50 t/s |
| Battery drain/hr | | | | <10% |
| Memory usage (MB) | | | | <500MB |

## Nexa ASR Test Results

- [ ] Model loads successfully on NPU
- [ ] Falls back gracefully if NPU unavailable
- [ ] Real-time transcription works (<500ms latency)
- [ ] Accuracy acceptable (>90% WER on test sentences)
- [ ] Handles background noise appropriately
- [ ] Works with multiple speakers

### ASR Test Notes
*Document observations, issues, and measurements here*

## Nexa LLM Test Results

- [ ] Model loads successfully on NPU
- [ ] Enhancement pipeline produces readable output
- [ ] Latency acceptable for real-time display
- [ ] Punctuation/capitalization added correctly
- [ ] Speaker diarization works (if applicable)

### LLM Test Notes
*Document observations, issues, and measurements here*

## AR Mode Tests (XR Glasses)

- [ ] Captions render correctly in AR view
- [ ] Position tracking works
- [ ] No significant lag between audio and display
- [ ] Works in various lighting conditions

### AR Test Notes
*Document observations, issues, and measurements here*

## Battery & Thermal Testing

| Test Duration | Battery Start | Battery End | Drain % | Max Temp |
|---------------|---------------|-------------|---------|----------|
| 30 min | | | | |
| 1 hour | | | | |
| 2 hours | | | | |

## Known Issues

| Issue | Severity | Status | Notes |
|-------|----------|--------|-------|
| | | | |

## Test Environment

- **Test APK version:** 
- **Nexa SDK version:**
- **Date:**
- **Tester:**

---

*Last updated: YYYY-MM-DD*
