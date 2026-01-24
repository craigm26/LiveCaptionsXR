# Nexa SDK Integration Analysis for LiveCaptionsXR
## Qualcomm x Nexa On-Device AI Bounty Program

**Date:** January 24, 2026
**Deadline:** Phase 1 - February 15, 2026 (11:59 PM PT)

---

## Executive Summary

LiveCaptionsXR is an **ideal candidate** for the Nexa SDK bounty program. The app already:
- Runs 100% on-device (privacy-first)
- Uses speech recognition (ASR)
- Uses multimodal AI (Gemma 3n for text enhancement)
- Targets accessibility (466 million people with hearing loss)
- Has production-grade architecture

Integrating Nexa SDK would replace the current Whisper GGML + Gemma 3n stack with Nexa's NPU-optimized inference, potentially achieving **2x faster inference** and **9x better energy efficiency**.

---

## Bounty Program Alignment

### Categories the App Fits

| Category | How LiveCaptionsXR Fits |
|----------|------------------------|
| ✅ **Accessibility tools** | Primary purpose - assists people with hearing loss |
| ✅ **Multimodal apps** | Combines audio (STT) + vision (face detection) + AR |
| ✅ **Offline translator** | Could add translation with Nexa LLM capabilities |
| ✅ **Privacy-focused** | 100% on-device, zero data leaves the phone |

### Judging Criteria Alignment (from bounty page)

Based on the bounty description, key evaluation points include:
1. **Real on-device Android AI app** - ✅ Already on-device
2. **Runs on Qualcomm Hexagon NPU** - 🔄 Integration needed
3. **Uses NexaSDK** - 🔄 Integration needed
4. **Privacy-focused, local-first, budget-friendly** - ✅ Already achieved

---

## Current LiveCaptionsXR Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     CURRENT STACK                           │
├─────────────────────────────────────────────────────────────┤
│  Audio Capture (16kHz stereo)                               │
│         ↓                                                   │
│  Whisper GGML (~141 MB) → Speech-to-Text                   │
│         ↓                                                   │
│  Gemma 3n (4.11 GB int4) → Text Enhancement                │
│         ↓                                                   │
│  Hybrid Localization (Kalman Filter + GCC-PHAT)            │
│         ↓                                                   │
│  ARCore/ARKit → 3D Caption Placement                       │
└─────────────────────────────────────────────────────────────┘
```

### Key Services to Replace/Enhance

| Current Service | File | Lines | Nexa Replacement |
|----------------|------|-------|------------------|
| WhisperService | `lib/core/services/whisper_service.dart` | ~350 | Nexa ASR API |
| Gemma3nService | `lib/core/services/gemma_3n_service.dart` | ~604 | Nexa LLM/VLM API |
| AppleSpeechService | `lib/core/services/apple_speech_service.dart` | ~200 | Keep for iOS fallback |

---

## Proposed Nexa SDK Integration

### Integration Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  NEXA SDK INTEGRATION                       │
├─────────────────────────────────────────────────────────────┤
│  Audio Capture (16kHz stereo)                               │
│         ↓                                                   │
│  ┌─────────────────────────────────────┐                   │
│  │  NexaSDK ASR (Hexagon NPU)          │                   │
│  │  - Whisper-compatible model         │                   │
│  │  - 2x faster, 9x energy efficient   │                   │
│  └─────────────────────────────────────┘                   │
│         ↓                                                   │
│  ┌─────────────────────────────────────┐                   │
│  │  NexaSDK LLM (Hexagon NPU)          │                   │
│  │  - Granite-4.0-h-350M-NPU           │                   │
│  │  - or OmniNeural-4B for multimodal  │                   │
│  └─────────────────────────────────────┘                   │
│         ↓                                                   │
│  Hybrid Localization (unchanged)                           │
│         ↓                                                   │
│  ARCore → 3D Caption Placement                             │
└─────────────────────────────────────────────────────────────┘
```

### Nexa SDK Models to Consider

| Model | Size | Purpose | Performance |
|-------|------|---------|-------------|
| **Granite-4.0-h-350M-NPU** | ~350 MB | Text enhancement | 92 tokens/s on NPU |
| **OmniNeural-4B** | ~4 GB | Multimodal (vision+text) | NPU optimized |
| **Nexa ASR model** | TBD | Speech-to-text | NPU accelerated |

---

## Implementation Strategy

### Phase 1: Core ASR Integration (Week 1-2)

**Goal:** Replace Whisper with Nexa ASR

1. **Create NexaAsrService** (`lib/core/services/nexa_asr_service.dart`)
   ```dart
   // Proposed interface (maintains compatibility with existing code)
   class NexaAsrService {
     Stream<WhisperSTTEvent> get eventStream;
     Future<void> initialize();
     Future<SpeechResult> transcribe(Float32List audioData);
     Future<void> dispose();
   }
   ```

2. **Android Native Integration** (`android/app/src/main/kotlin/`)
   ```kotlin
   // Add Nexa SDK dependency
   implementation("ai.nexa:core:0.0.19")

   // Initialize
   NexaSdk.getInstance().init(context)

   // ASR inference
   val asr = AsrWrapper.builder()
       .setPlugin(PluginType.NPU)
       .build()
   ```

3. **Update EnhancedSpeechProcessor**
   - Add `NexaAsrService` as primary engine on Android
   - Keep `WhisperService` as fallback for non-Snapdragon devices

### Phase 2: LLM Enhancement Integration (Week 2-3)

**Goal:** Replace Gemma 3n with Nexa LLM for text enhancement

1. **Create NexaLlmService** (`lib/core/services/nexa_llm_service.dart`)
   ```dart
   class NexaLlmService {
     Stream<Gemma3nEnhancementEvent> get eventStream;
     Future<String> enhanceText(String rawText);
     Future<String> multimodalInference(String text, Uint8List image);
   }
   ```

2. **Model Selection Strategy**
   - **Granite-4.0-h-350M-NPU**: Smaller, faster for text-only enhancement
   - **OmniNeural-4B**: Full multimodal for visual context awareness

### Phase 3: Performance Optimization (Week 3-4)

1. **NPU Pipeline Optimization**
   - Batch audio chunks for efficient NPU utilization
   - Implement async inference with cancellation support
   - Add NPU availability detection with CPU/GPU fallback

2. **Energy Profiling**
   - Measure battery impact vs current Whisper/Gemma stack
   - Document 9x energy efficiency gains for submission

---

## Code Integration Points

### Key Files to Modify

| File | Changes |
|------|---------|
| `android/app/build.gradle` | Add Nexa SDK dependency |
| `android/app/src/main/AndroidManifest.xml` | Add `extractNativeLibs="true"` |
| `lib/core/di/service_locator.dart` | Register Nexa services |
| `lib/core/services/enhanced_speech_processor.dart` | Integrate Nexa ASR |
| `lib/features/ar_session/cubit/ar_session_cubit.dart` | Handle Nexa events |

### New Files to Create

```
lib/core/services/
├── nexa_asr_service.dart          # Nexa ASR wrapper
├── nexa_llm_service.dart          # Nexa LLM wrapper
└── nexa_model_manager.dart        # Model download/management

android/app/src/main/kotlin/com/livecaptionsxr/app/
├── NexaAsrPlugin.kt               # Method channel for ASR
├── NexaLlmPlugin.kt               # Method channel for LLM
└── NexaModelManager.kt            # Native model management
```

### Maintaining Compatibility

```dart
// In EnhancedSpeechProcessor
ISpeechService _selectSpeechEngine() {
  if (Platform.isAndroid && _isSnapdragonDevice()) {
    return _nexaAsrService;  // Primary: Nexa on NPU
  } else if (Platform.isAndroid) {
    return _whisperService;  // Fallback: Whisper GGML
  } else if (Platform.isIOS) {
    return _appleSpeechService;  // iOS: Apple Speech
  }
  return _demoService;  // Web: Demo mode
}
```

---

## Submission Strategy

### Phase 1 Submission (Feb 15)

**Working App Demonstrating:**
1. ✅ On-device ASR using Nexa SDK on Qualcomm Hexagon NPU
2. ✅ On-device LLM for caption enhancement
3. ✅ Real-time spatial AR captions
4. ✅ Complete privacy (no cloud)

### Winning Differentiators

1. **Accessibility Focus** - 466 million potential users, clear social impact
2. **Production Quality** - Already has 21 PRDs, comprehensive architecture
3. **Technical Sophistication** - Kalman filter sensor fusion, multimodal AI
4. **Novel Use Case** - Only spatial captioning app with this architecture
5. **NPU Optimization** - Direct Hexagon NPU utilization

### Demo Video Script (2-3 minutes)

1. **Problem Statement** (30s) - Show hearing loss statistics, current solution gaps
2. **Live Demo** (90s) - Real-time captioning in AR, show NPU metrics
3. **Technical Deep-dive** (30s) - Show Nexa SDK integration, NPU utilization
4. **Impact Statement** (30s) - Privacy benefits, battery efficiency

---

## Device Requirements

### For Development/Testing

- **Recommended:** Qualcomm Snapdragon 8 Gen 4 device
- **Minimum:** Android API 27+ (Android 8.1), ARM64-v8a
- **RAM:** 4GB+ (for OmniNeural-4B model)
- **Storage:** 500MB - 5GB (depending on models)

### Note from Bounty

> *If you don't have a compatible device, you can start on standard Android devices - the Nexa team will help you bring it onto the Qualcomm Hexagon NPU for submission.*

---

## Timeline

| Week | Tasks |
|------|-------|
| **Week 1** (Jan 24-31) | Setup Nexa SDK, create NexaAsrService skeleton |
| **Week 2** (Feb 1-7) | Complete ASR integration, begin LLM integration |
| **Week 3** (Feb 8-14) | Complete LLM integration, performance testing |
| **Feb 15** | **Phase 1 Submission** |
| **Feb 16 - Mar 24** | Phase 2: Polish for Google Play release |
| **Mar 24** | **Phase 2 Submission** (if finalist) |

---

## Resources

- [Nexa SDK GitHub](https://github.com/NexaAI/nexa-sdk)
- [Nexa SDK Documentation](https://docs.nexa.ai/)
- [Nexa Model Hub](https://sdk.nexa.ai/model)
- [Qualcomm Blog on NexaSDK](https://www.qualcomm.com/developer/blog/2025/11/nexa-ai-for-android-simple-way-to-bring-on-device-ai-to-smartphones-with-snapdragon)
- [Bounty Program](https://sdk.nexa.ai/bounty)

---

## Next Steps

1. **Get Nexa SDK License Key** - Sign up at sdk.nexa.ai for personal use license
2. **Download Demo App** - Clone nexa-sdk repo, run Android demo
3. **Test ASR Performance** - Benchmark Nexa ASR vs current Whisper
4. **Begin Integration** - Start with NexaAsrService implementation

---

## Questions to Ask Nexa Team

1. Which ASR model is recommended for real-time captioning?
2. Is there a Flutter/Dart binding or is MethodChannel required?
3. Can we use OmniNeural-4B for both ASR and text enhancement?
4. What's the minimum Snapdragon chip for NPU acceleration?
5. Is there early access to the NPU-optimized Whisper model?
