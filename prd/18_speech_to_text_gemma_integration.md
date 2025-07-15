# Product Requirements Document: Speech-to-Text and Gemma 3n Integration for Enhanced AR Live Captioning

**Author:** LiveCaptionsXR Team
**Date Created:** 2025-01-08
**Last Updated:** 2025-01-08
**Status:** Draft
**Version:** 1.0

---

## 1. Overview & Background

*   **What is this product/feature?**
    *   This feature integrates the `speech_to_text` Flutter package for real-time speech recognition with the `flutter_gemma` package and the downloaded Gemma 3n model to provide enhanced, context-aware live captions in AR mode. The system will capture speech, transcribe it using `speech_to_text`, enhance/process the text using Gemma 3n, and then place the refined captions in the AR session.
    
*   **Why are we building this?**
    *   While basic speech-to-text provides functional captions, integrating Gemma 3n allows us to:
        - Improve caption accuracy and contextual understanding
        - Add punctuation and formatting to raw transcriptions
        - Provide semantic summaries for lengthy speech segments
        - Enhance readability with better sentence structure
        - Potentially translate or simplify complex terminology
    
*   **Business Objectives & Key Results (OKRs):**
    *   **Objective:** Deliver superior quality live captions that are more readable and contextually accurate than raw transcriptions
        *   **Key Result 1:** Improve caption readability score by 30% compared to raw speech-to-text output
        *   **Key Result 2:** Reduce user-reported caption errors by 40% within the first quarter
        *   **Key Result 3:** Achieve sub-1 second end-to-end latency from speech to enhanced caption display in AR

---

## 2. Target Audience & User Personas

*   **Who is this for?**
    *   Primary users are individuals who rely on live captions for accessibility, including deaf and hard-of-hearing users, as well as users in noisy environments or non-native speakers.
    
*   **User Personas:**
    *   **Persona 1: Sarah the Student**
        *   **Demographics:** 22 years old, university student, deaf since birth
        *   **Goals:** Follow lectures and participate in group discussions without missing information
        *   **Frustrations:** Raw captions often lack punctuation and context, making them hard to follow
        
    *   **Persona 2: Marcus the Professional**
        *   **Demographics:** 35 years old, business analyst, works in open office
        *   **Goals:** Understand conversations in noisy environments and technical meetings
        *   **Frustrations:** Technical jargon is often mistranscribed; captions lack structure

---

## 3. User Stories & Requirements

| Priority | User Story | Acceptance Criteria |
| :------- | :--------- | :------------------ |
| **P0** | As Sarah, I want captions to include proper punctuation so that I can understand sentence boundaries and tone. | - Gemma 3n adds periods, commas, and question marks to transcribed text<br>- Punctuation is contextually appropriate<br>- Processing adds <500ms latency |
| **P0** | As Marcus, I want technical terms to be correctly transcribed and formatted so that I can follow technical discussions. | - Gemma 3n corrects common mistranscriptions<br>- Technical terms are properly capitalized<br>- Acronyms are recognized and formatted correctly |
| **P0** | As a user, I want captions to appear in AR space quickly so that I don't miss the conversation flow. | - End-to-end latency from speech to AR caption <1 second<br>- Partial results show while processing<br>- Smooth transition from partial to final captions |
| **P1** | As Sarah, I want longer speech segments to be summarized when appropriate so that I can keep up with fast speakers. | - Gemma 3n provides concise summaries for segments >30 words<br>- Original full text remains accessible<br>- User can toggle between full/summary view |
| **P2** | As Marcus, I want captions to be semantically grouped so that related ideas stay together visually. | - Gemma 3n identifies semantic boundaries<br>- Related sentences are grouped in AR space<br>- Visual hierarchy reflects content structure |

---

## 4. Scope & Features

*   **In-Scope Features (Must-Haves):**
    *   Integration of `speech_to_text` package for real-time transcription
    *   Integration of `flutter_gemma` package with the downloaded Gemma 3n model
    *   Real-time caption enhancement pipeline:
        - Raw transcription → Gemma 3n processing → AR placement
    *   Punctuation and formatting enhancement
    *   Error correction for common mistranscriptions
    *   Streaming support with partial results
    *   Caption placement in AR using existing `HybridLocalizationEngine`
    
*   **Out-of-Scope Features (Won't Be Included in this Version):**
    *   Multi-language translation
    *   Voice synthesis/TTS features
    *   Custom vocabulary training
    *   Offline model fine-tuning
    *   Speaker emotion detection

---

## 5. Design & User Experience (UX)

*   **Processing Pipeline Flow:**
    ```
    Audio Input → speech_to_text → Raw Transcript → flutter_gemma/Gemma3n → Enhanced Caption → AR Placement
    ```

*   **Caption Display States:**
    1. **Listening**: Visual indicator showing audio is being captured
    2. **Processing**: Partial transcript shown with processing indicator
    3. **Enhanced**: Final enhanced caption displayed in AR space
    4. **Historical**: Previous captions fade but remain accessible

*   **Key UX Principles:**
    *   **Low Latency**: Users see partial results immediately
    *   **Progressive Enhancement**: Raw captions upgrade to enhanced seamlessly
    *   **Non-Blocking**: Enhancement doesn't delay initial caption display
    *   **Graceful Degradation**: Falls back to raw captions if enhancement fails

---

## 6. Technical Requirements & Constraints

*   **Platform(s):** iOS (14.0+), Android (API 24+)
*   **Technology Stack:**
    *   Flutter/Dart
    *   `speech_to_text` package (^6.0.0)
    *   `flutter_gemma` package (latest)
    *   Gemma 3n model (4GB .task file)
    *   Existing AR/Localization infrastructure
    
*   **Performance Requirements:**
    *   Raw transcription latency: <200ms
    *   Gemma 3n enhancement: <500ms
    *   Total end-to-end latency: <1000ms
    *   Memory usage: <2GB additional RAM
    *   Battery impact: <10% increase in consumption
    
*   **Model Requirements:**
    *   Gemma 3n model file: `gemma-3n-E4B-it-int4.task`
    *   Model location: Application documents directory
    *   Model size: ~4.1GB
    *   One-time download with progress tracking
    
*   **Dependencies & Integrations:**
    *   Depends on existing `ModelDownloadManager` for model acquisition
    *   Integrates with `HybridLocalizationEngine` for AR placement
    *   Uses `ContextualEnhancer` patterns for text processing

---

## 7. Analytics & Success Metrics

*   **Key Performance Indicators (KPIs):**
    *   **Caption Quality Score:** Automated readability metrics (Flesch score improvement)
    *   **Processing Latency:** P50, P90, P99 latencies for enhancement pipeline
    *   **Enhancement Success Rate:** % of captions successfully enhanced vs fallback
    *   **User Satisfaction:** In-app rating specifically for caption quality
    *   **Error Reduction Rate:** Comparison of WER before/after enhancement
    
*   **Analytics Events:**
    *   `speech_recognition_started`
    *   `raw_caption_generated` (with word count, duration)
    *   `gemma_enhancement_started`
    *   `gemma_enhancement_completed` (with processing time)
    *   `gemma_enhancement_failed` (with error reason)
    *   `caption_placed_in_ar` (with final text length)
    *   `user_caption_feedback` (positive/negative rating)

---

## 8. Go-to-Market & Launch Plan

*   **Launch Tiers:**
    *   **Alpha Testing:** Internal team testing with controlled speech scenarios
    *   **Beta Release:** Limited release to 100 beta users with feedback collection
    *   **Staged Rollout:** 10% → 50% → 100% over 2 weeks
    *   **General Availability:** Full release with feature flag for easy rollback
    
*   **Feature Introduction:**
    *   In-app tutorial highlighting enhanced caption benefits
    *   Comparison mode showing raw vs enhanced captions
    *   Settings to adjust enhancement aggressiveness

---

## 9. Open Questions & Assumptions

*   **Open Questions:**
    *   What is the optimal context window size for Gemma 3n processing?
    *   Should we implement a cache for common phrase enhancements?
    *   How do we handle domain-specific vocabulary (medical, legal, technical)?
    *   What's the battery impact of continuous Gemma 3n inference?
    
*   **Assumptions:**
    *   Users have sufficient storage (4GB+) for the Gemma 3n model
    *   Devices have adequate RAM (6GB+) for model loading
    *   Network connectivity is available for initial model download
    *   `flutter_gemma` can handle streaming text input efficiently

---

## 10. Implementation Architecture

### Core Components:

1. **SpeechToTextManager**
   - Wraps `speech_to_text` package
   - Handles microphone permissions
   - Streams raw transcriptions
   
2. **GemmaEnhancer**
   - Manages `flutter_gemma` instance
   - Loads/unloads Gemma 3n model
   - Processes text enhancement requests
   - Implements caching for performance
   
3. **CaptionPipeline**
   - Orchestrates flow from speech to AR
   - Manages partial/final result states
   - Handles fallback scenarios
   - Integrates with existing AR services

### Data Flow:
```dart
// Pseudo-code for the enhancement pipeline
Stream<EnhancedCaption> captionStream = speechToText.stream
    .debounce(Duration(milliseconds: 300))
    .asyncMap((rawText) async {
        try {
            final enhanced = await gemmaEnhancer.enhance(rawText);
            return EnhancedCaption(
                raw: rawText,
                enhanced: enhanced,
                confidence: enhanced.confidence,
            );
        } catch (e) {
            return EnhancedCaption.fallback(rawText);
        }
    })
    .map((caption) => arPlacementService.place(caption));
```

---

## 11. Sign-off

| Stakeholder       | Role                | Date Approved |
| :---------------- | :------------------ | :------------ |
| Product Manager   | Product Lead        |               |
| Engineering Lead  | Technical Lead      |               |
| UX Designer       | Design Lead         |               |
| QA Lead           | Quality Assurance   |               |

--- 