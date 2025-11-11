## Speaker Identification & Spatial Attribution RPD

### 1. Research

- **Current inputs**: mono Whisper audio chunks + optional stereo frames (`StereoAudioCapture`) and on-device camera frames. Confirm timestamp alignment across services.
- **Existing tooling**: evaluate Flutter/Dart packages for face detection (MediaPipe, Google ML Kit) and lightweight stereo localization algorithms (ITD/ILD).
- **Constraints**: must run on-device (XR headset) with limited CPU/GPU; ensure models fit within on-device deployment constraints and respect privacy (no cloud round trips).
- **Benchmarks**: gather latency/accuracy targets for speaker identification; define acceptable error range for azimuth estimation and minimum voice-to-caption latency (< 1.5 s ideal).

### 2. Plan

- **Milestone A - Visual speaker tagging**
  - Implement face detection pipeline on captured frames.
  - Track detected faces across frames and expose their 2D positions + IDs.
  - Align Whisper chunk timestamps with frame timestamps to map speech to the active face; highlight the face in the UI when speech is detected.
- **Milestone B - Audio localization for off-screen speakers**
  - Process stereo audio frames to estimate azimuth (ITD/ILD or GCC-PHAT).
  - Create a bearing indicator for voices without an in-frame face; display in HUD.
  - Fuse visual and audio cues to determine confidence and avoid conflicting overlays.
- **Milestone C - Speaker identity persistence**
  - Optional voice embedding (e.g. small speaker verification model) to assign consistent labels across sessions even when leaving/re-entering frame.
  - Cache per-speaker metadata (direction preferences, last seen time) for UX polish.
- **Infrastructure**
  - Add service abstractions for face detection and spatial audio analysis.
  - Extend logging/telemetry to measure false positives, latency, and CPU usage.

### 3. Design

- **Architecture**
  - `VisualSpeakerService`: subscribes to frame stream, detects faces, emits `DetectedSpeaker` objects with bounding boxes and IDs.
  - `SpatialAudioAnalyzer`: consumes stereo frames, outputs azimuth + confidence per chunk; exposes smoothing filters.
  - `SpeakerFusionEngine`: merges Whisper transcript events with visual/audio cues to decide final caption placement (in-frame bubble vs. off-screen direction indicator).
- **Data Flow**
  1. Audio chunk triggers Whisper transcript event.
  2. Fusion engine queries latest `DetectedSpeaker` and azimuth estimates around the chunk timestamp.
  3. Decide caption anchor (face ID, bearing, or default HUD) and update UI.
  - Ensure all services share a synchronized clock reference (e.g. `DateTime.now()` monotonic or custom ticker) for alignment.
- **UI/UX**
  - In-frame: card anchored to speaker's head, with subtle outline to show active talker.
  - Off-screen: radial compass indicator with textual arrow "Speaker @ 30 deg right".
  - Multi-speaker handling: queue captions, fade oldest, manage overlapping bubbles.
- **Performance**
  - Run face detection at reduced resolution and cadence (e.g. every 5-8 frames) with tracking interpolation in-between.
  - Offload heavy computation to isolates or native plugins where needed.
  - Gate advanced features behind capability flags so older hardware can fall back to basic captions.

### 4. Milestone A - Visual speaker tagging PRD

**Goal**: Ship an on-device visual speaker tagging loop that highlights the active face inside the headset viewport and hands a stable anchor to the spatial caption renderer, without regressing current Whisper latency or AR placement quality.

#### 4.1 Success metrics & guardrails
- >=90% precision when mapping a caption to the correct in-frame face in 3-speaker test clips (lab capture set).
- <200 ms added median latency between `AudioCaptureService` chunk ( `lib/core/services/audio_capture_service.dart:9` ) and the resulting caption bubble highlight.
- Face detection loop sustains >=15 FPS on Quest-class XR hardware with <35% average CPU utilization while `LiveCaptionsCubit` ( `lib/features/live_captions/cubit/live_captions_cubit.dart` ) is streaming.
- System fails safe: if no confident face exists, captions fall back to the existing HUD anchor with no UI shimmer.

#### 4.2 Existing assets to reuse
- `CameraService` frame stream (`lib/core/services/camera_service.dart:12`) already exposes periodic YUV420 buffers via `_frameStreamController`. We will reuse the permission/init logic and add a throttled `Stream<CameraFrame>` API with timestamps and intrinsics metadata.
- `VisualIdentificationCubit` (`lib/features/visual_identification/cubit/visual_identification_cubit.dart:16`) already listens to visual detections over a method channel. We will evolve it into the main delivery path for tracked faces (`DetectedSpeakerFace`) and reuse the wiring to `HybridLocalizationEngine`.
- `HybridLocalizationEngine` (`lib/core/services/hybrid_localization_engine.dart:6`) already pushes visual transforms into the native Kalman filter. We only need to extend `updateWithVisualMeasurement` calls with per-face IDs so captions can follow a consistent anchor.
- `SpatialCaptionIntegrationService` and the spatial_captions plugin already own AR placement. Milestone A confines changes to adding a notion of `activeFaceId` when `processPartialResult` / `processFinalResult` are called so UI can bind to either a face anchor or the fallback HUD.
- Logging/telemetry (`AppLogger`) is established across services; add new categories rather than inventing another logging utility.

#### 4.3 Scope, user stories, acceptance

| Priority | Story | Acceptance criteria |
| --- | --- | --- |
| **P0** | As a deaf/HoH wearer, I want the caption bubble to lock onto the mouth of the person currently speaking in my field of view. | When Whisper reports an utterance, the face with the highest speaking confidence within +/-250 ms is highlighted; bounding box jitter <10 px @ 1080p; fallback bubble shown if no face crosses confidence threshold. |
| **P0** | As an engineer, I need a face-tracking API that emits stable IDs so I can fuse with spatial anchors. | New `VisualSpeakerService` exposes `Stream<DetectedSpeaker>` objects containing `faceId`, `boundingBox`, `landmarks`, and `timestamp`. IDs persist for >=2 s of occlusion and are recycled safely. |
| **P1** | As a PM, I need to know when visual tagging degrades so we can adjust cadence or disable it. | Telemetry event `visual_speaker_tagging_status` fires per session with FPS, CPU, dropped-frame %, and disabled reason; surfaced in AppLogger + analytics sink. |

Out of scope for A: audio-only azimuth estimation (Milestone B), persistent identity labels, or off-screen HUD direction arrows.

#### 4.4 Technical approach
1. **Frame ingestion & scheduling**
   - Extend `CameraService` to publish a `CameraFrame` object that bundles `Uint8List yPlane`, width/height, `DateTime timestamp`, exposure metadata, and an optional projection matrix (Quest/OpenXR). We will downsample frames to 640 px width and run detection every 4th frame (configurable) to respect CPU budgets.
   - Expose `startVisualFeed()` / `stopVisualFeed()` so the detection isolate can be paused when captions are idle.
2. **Face detection & landmark extraction**
   - On Android: integrate `google_mlkit_face_detection` with contour mode; on iOS: use `Vision` via an FFI plugin (there is already native scaffolding under `plugins/`). Implement a Dart-facing `VisualSpeakerPlatform` interface with method-channel implementations that receive `CameraFrame` bytes and return face rectangles + mouth landmarks.
   - Ensure detectors output pixel coordinates normalized to the downsampled frame to simplify UI math.
3. **Tracking & active-speaker scoring**
   - Add a new Dart class `FaceTrackRepository` to keep a map of `faceId -> FaceTrack`. Use IoU-based association plus optical flow-lite (center velocity) for short-term prediction. Each track stores lip aperture delta, timestamp of last speech, and a world transform if provided by AR (Vision/ARKit blend).
   - Compute speaking confidence by combining (a) mouth-aspect-ratio delta between consecutive frames, (b) RMS energy window from `AudioCaptureService` (exposed via a lightweight `SpeechActivityBus`), and (c) whether Whisper produced tokens within +/-250 ms. Apply hysteresis to avoid flicker.
4. **UI & integration**
   - `VisualIdentificationCubit.detectObjects()` evolves to emit a richer `DetectedSpeaker` domain model (with `faceId` + `speakerState`). The cubit forwards the highest-confidence active track to `SpatialCaptionIntegrationService`, which in turn adds `faceId` to the payload it hands to the spatial_captions plugin.
   - Update the Flutter overlay (LiveCaptions widget) to draw a subtle outline around the active face using `CustomPainter`, keyed by `faceId`, and to hide the highlight when there is no confident track.
5. **Telemetry & fallback**
   - Add periodic `AppLogger` entries for detector FPS, dropped frames, and association misses. Log once when we auto-disable (thermal, FPS <8 for 3 s, or camera service failure) and expose that status to settings UI.

#### 4.5 Implementation backlog (2-week target)

| ID | Work item | Owners / dependencies | Definition of done |
| --- | --- | --- | --- |
| A1 | `CameraService` frame metadata refactor | Flutter core | Timestamped `CameraFrame` stream behind feature flag, unit test verifying downsample math, hot path stays <1.2 ms average. |
| A2 | Native detector bindings | Platform team | Method-channel/FFI wrappers for ML Kit + Vision that accept NV21/YUV buffers, return faces in normalized coords; smoke test app prints detection count. |
| A3 | `VisualSpeakerService` + tracking | Core XR | Service merges detector outputs + audio activity, surfaces `Stream<DetectedSpeaker>`; includes configurable cadence + hysteresis constants and golden tests with recorded frame fixtures. |
| A4 | `LiveCaptionsCubit` & spatial integration updates | Captions team | `processPartialResult`/`processFinalResult` accept optional `faceId`; UI highlight renders in headset mock scene; manual QA shows captions stick to correct faces. |
| A5 | Telemetry & feature flag plumbing | Infra | Settings toggle, AppLogger counters, analytics event + Crashlytics breadcrumb when disabled. |

#### 4.6 Validation & tooling
- **Datasets**: Reuse headset capture clips stored under `assets/sample_sessions/tri-speaker_*` plus record two new sequences (bright + low light) to validate detection robustness.
- **Automated tests**: Add golden tests for the tracker (feed recorded rectangles + audio RMS traces, assert chosen active face), widget test to ensure highlight hides when `confidence < 0.6`.
- **Manual QA checklist**: multi-speaker conversation, occlusion recovery, camera permission denied, CPU stress test with captions + detector.

#### 4.7 Risks & mitigations
- **Thermal budget**: running detectors continuously could throttle the headset. Mitigate via adaptive cadence (drop to every 8th frame when FPS <12) and allow quick disable from settings.
- **Timestamp drift**: camera timestamps may not align with Whisper chunk times. All services must use the same monotonic clock (see TODO to expose a `TimestampProvider` in both `CameraService` and `AudioCaptureService`); block launch until <20 ms skew verified.
- **Model bias**: ML Kit struggles with masks or non-frontal faces. Provide UX fallback (HUD bubble), and capture diverse QA footage before GA.

#### 4.8 Open questions
- Should we reuse the existing native Hybrid Localization plugin to also perform head-pose estimation for each face to improve anchor stability, or defer to Milestone C?
- What is the acceptable battery hit for continuous face tagging on XR headsets? Need PM + hardware input.
