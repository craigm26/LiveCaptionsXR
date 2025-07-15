# Implementation Guide: Speech-to-Text and Gemma 3n Integration

**Related PRD:** 18_speech_to_text_gemma_integration.md  
**Date:** 2025-01-08

---

## Integration Points with Existing Codebase

### 1. Modify `SpeechProcessor` Service

The existing `SpeechProcessor` service (`lib/core/services/speech_processor.dart`) needs to be updated to support both the new approach and maintain backward compatibility:

```dart
class SpeechProcessor {
  // Add configuration for speech engine selection
  final SpeechEngine _engine;
  
  enum SpeechEngine {
    native,      // Current native implementation
    speechToText, // New speech_to_text package
    gemma3n,     // Direct Gemma 3n ASR (future)
  }
  
  // New method for speech_to_text integration
  Future<void> _initializeSpeechToText() async {
    _speech = stt.SpeechToText();
    bool available = await _speech.initialize(
      onStatus: _handleStatus,
      onError: _handleError,
    );
    
    if (available) {
      _speech.listen(
        onResult: _handleSpeechResult,
        listenMode: stt.ListenMode.confirmation,
        partialResults: true,
      );
    }
  }
}
```

### 2. Create `GemmaEnhancer` Service

New service to handle Gemma 3n text enhancement:

```dart
// lib/core/services/gemma_enhancer.dart
class GemmaEnhancer {
  final ModelDownloadManager _modelManager;
  FlutterGemma? _gemmaInstance;
  
  Future<void> initialize() async {
    // Check if model exists
    if (!await _modelManager.modelIsComplete()) {
      throw Exception('Gemma 3n model not downloaded');
    }
    
    final modelPath = await _modelManager.getModelPath();
    _gemmaInstance = await FlutterGemma.create(modelPath);
  }
  
  Future<EnhancedCaption> enhance(String rawText) async {
    // Prepare prompt for enhancement
    final prompt = _buildEnhancementPrompt(rawText);
    
    // Process through Gemma
    final enhanced = await _gemmaInstance!.generateText(
      prompt,
      maxTokens: rawText.length * 2, // Allow room for punctuation
    );
    
    return EnhancedCaption(
      raw: rawText,
      enhanced: enhanced.text,
      confidence: enhanced.confidence,
    );
  }
}
```

### 3. Update `LiveCaptionsCubit`

Modify the existing cubit to support the enhancement pipeline:

```dart
class LiveCaptionsCubit extends Cubit<LiveCaptionsState> {
  final SpeechProcessor _speechProcessor;
  final GemmaEnhancer _gemmaEnhancer;
  final HybridLocalizationEngine _hybridLocalizationEngine;
  
  StreamSubscription<SpeechResult>? _speechSubscription;
  StreamSubscription<EnhancedCaption>? _enhancementSubscription;
  
  Future<void> startCaptions() async {
    // Initialize Gemma enhancer if not already done
    await _gemmaEnhancer.initialize();
    
    // Start speech processing with new engine
    await _speechProcessor.startProcessing(
      engine: SpeechEngine.speechToText,
    );
    
    // Set up enhancement pipeline
    _enhancementSubscription = _speechProcessor.speechResults
        .asyncMap((result) => _processWithGemma(result))
        .listen(_handleEnhancedCaption);
  }
  
  Future<EnhancedCaption> _processWithGemma(SpeechResult result) async {
    try {
      // Only enhance final results to reduce load
      if (result.isFinal) {
        return await _gemmaEnhancer.enhance(result.text);
      }
      // Return raw for partial results
      return EnhancedCaption.partial(result.text);
    } catch (e) {
      // Fallback to raw on error
      return EnhancedCaption.fallback(result.text);
    }
  }
}
```

### 4. Update Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  speech_to_text: ^6.6.0
  flutter_gemma: ^0.1.0  # Check for latest version
  
  # Existing dependencies...
```

### 5. Model Download Integration

The existing `ModelDownloadManager` is already set up to handle the Gemma 3n model download. The integration point is in the home screen initialization:

```dart
// Already implemented in home_screen.dart
Future<void> _checkAndPromptModelDownload() async {
  final exists = await _modelDownloadManager.modelExists();
  if (!exists && mounted) {
    _showModelDownloadDialog();
  }
}
```

### 6. AR Placement Integration

The enhanced captions will flow through the existing `HybridLocalizationEngine`:

```dart
// In _handleEnhancedCaption method
void _handleEnhancedCaption(EnhancedCaption caption) {
  if (caption.isFinal) {
    // Place enhanced caption in AR
    _hybridLocalizationEngine.placeRealtimeCaption(
      caption.enhanced ?? caption.raw,
    );
    
    // Update state for UI display
    emit(currentState.copyWith(
      captions: [..._captionHistory, caption],
      currentCaption: null,
    ));
  } else {
    // Show partial caption in UI
    emit(currentState.copyWith(
      currentCaption: caption,
    ));
  }
}
```

---

## Migration Strategy

1. **Phase 1: Feature Flag**
   - Add feature flag to toggle between native and speech_to_text
   - Default to native implementation initially

2. **Phase 2: A/B Testing**
   - Enable for 10% of users
   - Monitor performance metrics and user feedback

3. **Phase 3: Gradual Rollout**
   - Increase to 50% after fixing initial issues
   - Full rollout after confirming improvements

---

## Performance Considerations

1. **Model Loading**
   - Load Gemma 3n model lazily when first caption is needed
   - Keep model in memory during active AR session
   - Unload when AR session ends

2. **Text Processing**
   - Use debouncing to batch rapid speech segments
   - Process enhancement on background isolate
   - Cache common phrase enhancements

3. **Memory Management**
   - Monitor memory usage during AR session
   - Implement LRU cache for enhancement results
   - Clear caches when memory pressure detected

---

## Testing Strategy

1. **Unit Tests**
   - Test GemmaEnhancer with various text inputs
   - Test fallback scenarios
   - Test enhancement caching

2. **Integration Tests**
   - End-to-end flow from speech to AR placement
   - Performance benchmarks
   - Memory leak detection

3. **User Testing**
   - A/B test enhancement quality
   - Measure perceived latency
   - Collect qualitative feedback

--- 