# LiveCaptionsXR on Samsung Galaxy XR: Consumer Guide

This guide explains how LiveCaptionsXR works on Samsung Galaxy XR devices and what to expect as a user. It focuses on on-device privacy, spatial caption placement, and the two-stage captioning pipeline that powers the experience.

## What makes the Galaxy XR experience special
- **On-device and private:** Speech stays on the headset. Whisper GGML runs locally for speech-to-text, while Gemma 3n refines phrasing without sending data to the cloud.
- **Spatially anchored captions:** ARCore tracks the environment so captions appear at the spot where each speaker’s voice originates.
- **Multimodal awareness:** Stereo microphones estimate who is speaking, optional camera frames add visual hints, and device motion sensors steady the placement—helping captions follow different people in the scene.
- **Responsive state machine:** A two-stage AR session tracks progress from setup through transcription and enhancement so you always know what’s happening.

## How the pipeline works (step by step)
1. **Start AR mode:** Opening the AR view initializes ARCore tracking, microphone access, and required services.
2. **Stage 1 – Speech-to-text:** The Whisper service transcribes speech locally in real time using the optimized base model.
3. **Stage 2 – Contextual enhancement:** Gemma 3n adds punctuation, fixes wording, and can use a quick camera snapshot for extra context when needed.
4. **Find the speaker:** Audio direction (RMS + GCC-PHAT) and optional camera cues feed a Hybrid Localization Engine that fuses audio, vision, and IMU orientation to estimate where the voice is coming from.
5. **Place the caption:** The fused 3D position and enhanced text are sent back to the native AR view, which anchors the caption near the speaker. Each active talker keeps their own caption bubble so conversations stay separated.

## Using LiveCaptionsXR on your Galaxy XR
- **Permissions:** Allow microphone and camera access when prompted so the app can hear speech and, when needed, grab a frame for context.
- **Good positioning:** Keep the headset oriented toward the conversation for best audio direction estimates. Move your head slowly when turning to new speakers so ARCore maintains stable tracking.
- **Reading captions:** Partial captions appear first and then update to final, enhanced text. Each speaker’s captions remain near their position instead of stacking in one spot.
- **Low-light or noisy rooms:** The system falls back to audio-only placement if camera context is unavailable. Captions still show, but placement may be less precise until tracking stabilizes.
- **Stopping or resuming:** Pausing the AR session stops capture and anchoring; resuming restarts tracking and continues captioning without losing previous anchors when possible.

## Tips for best results
- Use the included stereo mics (or supported external mics) to give the app clearer directional cues.
- Ensure there is some visual texture in the room (posters, furniture) so ARCore can keep anchors stable.
- If captions seem misaligned, briefly face the speaker to give the localization engine a clean audio sample and let the Kalman filter steady the position.

## Privacy and safety
- All processing happens on-device for speed and confidentiality; no speech or images are sent to external servers.
- You can revoke camera access anytime—captioning will continue with audio-only placement.
- Logs focus on system health (audio/AR/service status) and avoid storing transcript content by default.
