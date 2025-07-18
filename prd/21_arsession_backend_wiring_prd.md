# PRD: Wiring Up AR Session State to Real Backend Logic

## Objective
Enable the AR session status system to reflect the *actual* progress and backend selection of the Speech-to-Text (STT) and Gemma 3n contextual enhancement pipeline, using real service events and user settings.

---

## 1. User Story
- As a user, I want to see accurate, real-time feedback in the AR session status UI about:
  - Which STT backend is being used (cloud or on-device)
  - The progress of speech-to-text and contextual enhancement
  - Any errors or delays in the pipeline
- As a developer, I want the AR session state machine to be driven by real service events, not simulation.

---

## 2. Requirements

### A. Settings Integration
- The user’s STT backend choice (Whisper, Google, Azure, etc.) and online/offline status must be passed to the AR session pipeline.
- The pipeline should adapt to network changes (e.g., fallback to on-device if offline).

### B. State Emission from Real Services
- The STT service (Whisper, Google, etc.) must emit events for:
  - Start of transcription
  - Progress (if available)
  - Completion
  - Errors
- The Gemma 3n enhancement service must emit events for:
  - Start of enhancement
  - Progress (if available)
  - Completion
  - Errors

### C. ARSessionCubit/Bloc Wiring
- The ARSessionCubit must listen to these events and emit:
  - `ARSessionSTTProcessing` with backend, online/offline, progress, and message
  - `ARSessionContextualEnhancement` with progress and message
  - `ARSessionError` on failure

### D. UI Feedback
- The ARSessionStatusWidget must display the real backend, progress, and error states as they occur.

### E. Error Handling
- If a service fails, the error must be surfaced in the status widget and allow the user to retry or exit AR mode.

---

## 3. Implementation Steps

1. **Settings → ARSessionCubit**
   - Fetch the selected STT backend and online/offline status from `SettingsCubit` in `home_screen.dart`.
   - Pass these to `startAllARServices`.

2. **STT Service Integration**
   - In the STT service (e.g., WhisperService, GoogleSTTService), add callbacks/streams for start, progress, complete, and error.
   - In the cubit, subscribe to these and emit the corresponding AR session states.

3. **Gemma 3n Service Integration**
   - In the Gemma service, add callbacks/streams for start, progress, complete, and error.
   - In the cubit, subscribe to these and emit the corresponding AR session states.

4. **UI Update**
   - Ensure the status widget displays the backend, progress, and error info from the real states.

5. **Testing**
   - Test with all combinations: cloud STT, on-device STT, network loss, Gemma enhancement, and error cases.

---

## 4. Out of Scope
- Changing the actual STT or Gemma model implementations.
- UI redesign beyond the status widget.

---

## 5. Acceptance Criteria
- The AR session status widget always reflects the real backend and progress.
- Errors in STT or Gemma are shown in the status widget.
- The user can see which backend is being used and whether it’s cloud or on-device.
- The system gracefully handles network changes and service errors. 