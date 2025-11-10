## Speaker Identification & Spatial Attribution RPD

### 1. Research
- **Current inputs**: mono Whisper audio chunks + optional stereo frames (`StereoAudioCapture`) and on-device camera frames. Confirm timestamp alignment across services.
- **Existing tooling**: evaluate Flutter/Dart packages for face detection (MediaPipe, Google ML Kit) and lightweight stereo localization algorithms (ITD/ILD).
- **Constraints**: must run on-device (XR headset) with limited CPU/GPU; ensure models fit within on-device deployment constraints and respect privacy (no cloud round trips).
- **Benchmarks**: gather latency/accuracy targets for speaker identification; define acceptable error range for azimuth estimation and minimum voice-to-caption latency (< 1.5 s ideal).

### 2. Plan
- **Milestone A – Visual speaker tagging**
  - Implement face detection pipeline on captured frames.
  - Track detected faces across frames and expose their 2D positions + IDs.
  - Align Whisper chunk timestamps with frame timestamps to map speech to the active face; highlight the face in the UI when speech is detected.
- **Milestone B – Audio localization for off-screen speakers**
  - Process stereo audio frames to estimate azimuth (ITD/ILD or GCC-PHAT).
  - Create a bearing indicator for voices without an in-frame face; display in HUD.
  - Fuse visual and audio cues to determine confidence and avoid conflicting overlays.
- **Milestone C – Speaker identity persistence**
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
  - In-frame: card anchored to speaker’s head, with subtle outline to show active talker.
  - Off-screen: radial compass indicator with textual arrow "Speaker @ 30° right".
  - Multi-speaker handling: queue captions, fade oldest, manage overlapping bubbles.
- **Performance**
  - Run face detection at reduced resolution and cadence (e.g. every 5–8 frames) with tracking interpolation in-between.
  - Offload heavy computation to isolates or native plugins where needed.
  - Gate advanced features behind capability flags so older hardware can fall back to basic captions.


