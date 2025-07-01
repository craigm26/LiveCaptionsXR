# Video Demo Script (2025 Update)

This document provides a recommended outline for creating a short (three-minute) video demonstrating the **Live Captions XR** project. The goal is to tell a clear story about the problem, how the app solves it with Gemma 3n, and the impact on users.

## Script Outline (0–3 minutes)

1. **0:00 – 0:10: Hook & Problem Intro**
   - Show a busy social environment where someone struggles to follow conversation.
   - Narration or on-screen text: *"For the deaf and hard-of-hearing community, following conversations in noisy places is a challenge."*
2. **0:10 – 0:20: Present the Solution**
   - Cut to upbeat visuals of the app in action.
   - Narration: *"Our project uses Google's Gemma 3n multimodal AI to deliver real-time, spatially aware captions."*
3. **0:20 – 1:00: How It Works**
   - Display the device's camera view capturing the scene with captions appearing near the speaker.
   - Emphasize on-device processing, privacy, and low latency.
4. **1:00 – 1:40: User Story**
   - Show a user wearing a headset or holding a phone as captions follow the conversation around them.
   - Include reaction shots highlighting better engagement.
5. **1:40 – 2:20: Unique Features & Technical Highlights**
   - Quick overlays for key points: *"MediaPipe + Gemma 3n," "On-device audio and visual fusion," "Low-latency spatial localization."*
   - Optionally show code snippets or architecture diagrams.
6. **2:20 – 2:50: Impact & Vision**
   - Montage of settings like classrooms, offices, and social gatherings.
   - Narration describing how Live Captions XR improves accessibility in various situations.
7. **2:50 – 3:00: Call to Action**
   - Finish with a strong statement, the app's logo, and a link or QR code so viewers can learn more or try the demo.

## Style Notes

- Keep clips short with smooth transitions and upbeat music.
- Mix screen recordings of the app with real-life footage for context.
- Use clear, large text overlays that follow accessibility best practices.
- Add subtle animations to show spatial movement (captions from left or right).
- End with a direct URL to the project so judges can view it without logging in.

1. User launches the app and enters AR mode (via AR navigation MethodChannel).
2. User speaks; the system captures audio and vision in real time.
3. The hybrid localization engine fuses audio, vision, and IMU to estimate the speaker's 3D position.
4. The system transcribes speech in real time.
5. When a final transcript is available, the caption is anchored in AR at the speaker's position (via caption placement MethodChannel).
6. The caption follows the speaker as they move, demonstrating robust, privacy-preserving AR accessibility.
