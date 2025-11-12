# Predictive Captions Baseline Audit (2025-11-12)

## Streaming & Sensor Ingest
- `lib/core/services/audio_capture_service.dart` batches 16 kHz PCM via `_bufferAudioChunk`, forwarding `Uint8List` buffers to `WhisperService`, while stereo frames from `StereoAudioCapture` feed `SpatialCaptionIntegrationService.updateAudioFrame`.
- `lib/core/services/frame_capture_service.dart` abstracts platform camera capture (`ARFrameService` on iOS, `CameraService` on Android) and is invoked on-demand from Gemma enhancement; persistent RGB/depth stream abstractions are not yet present.
- `lib/core/services/hybrid_localization_engine.dart` exposes native Kalman fusion hooks (`predict`, `updateWithAudioMeasurement`, `updateWithVisualMeasurement`, `getFusedTransform`), currently triggered indirectly by spatial caption integration updates.

## Speech & Enhancement Flow
- `lib/core/services/enhanced_speech_processor.dart` orchestrates ASR backends (Whisper GGML, Apple Speech) and Gemma 3n enhancement. `_processSpeechResult` emits raw `SpeechResult`s and triggers `_enhanceWithGemma3n` to produce `EnhancedCaption`s for finals while partials call `EnhancedCaption.partial`.
- `lib/features/live_captions/cubit/live_captions_cubit.dart` consumes both raw and enhanced streams, translating them into UI state while routing final/partial results through `SpatialCaptionIntegrationService`.
- Calibration, logprob, or entropy metadata are not surfaced; only confidence doubles and `isFinal` flags propagate through the pipeline.

## Spatial Integration & UI
- `lib/core/services/spatial_caption_integration_service.dart` resolves anchor positions by combining stereo DOA, hybrid localization, and speaker metadata from `SpeakerAttributionStore`; it commits partial/final captions via `SpatialCaptionsCubit`, but lacks explicit Kalman smoothing or occlusion-aware offset handling.
- UI components (`lib/features/live_captions/widgets/live_captions_widget.dart`, `lib/shared/widgets/caption_bubble.dart`) render a single active caption plus optional history with binary styling (interim vs. final). Ghost-token visualization or confidence-driven layout have not been implemented yet.

## Integration Opportunities for Predictive Captions
- Insert deterministic next-token streaming between `EnhancedSpeechProcessor._processSpeechResult` and `LiveCaptionsCubit._handleEnhancedCaption`, exposing per-frame token, logprob, and entropy to a forthcoming `NextTokenStream` API (planned under `spatial_intel/predict/`).
- Extend `SpeechResult`/`EnhancedCaption` models to carry entropy, N-best metadata, and calibration outputs, enabling UI styling and benchmarking.
- Refactor spatial integration to consume structured policies (future `policies.yaml`) and add Kalman/EMA smoothing modules, DOA drift detection, and neutral-rail fallback logic.
- Update the UI layer to support ghost-to-commit transitions, opacity changes based on confidence, and animation diffs while preserving accessibility constraints.

