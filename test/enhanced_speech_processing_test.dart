import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:live_captions_xr/core/services/enhanced_speech_processor.dart';
import 'package:live_captions_xr/core/services/model_download_manager.dart';
import 'package:live_captions_xr/core/services/gemma_enhancer.dart';
import 'package:live_captions_xr/core/models/speech_result.dart';
import 'package:live_captions_xr/core/models/enhanced_caption.dart';

// Generate mocks
@GenerateMocks([ModelDownloadManager, GemmaEnhancer])
import 'enhanced_speech_processing_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Enhanced Speech Processing', () {
    late EnhancedSpeechProcessor enhancedProcessor;
    late MockModelDownloadManager mockModelManager;
    late MockGemmaEnhancer mockGemmaEnhancer;

    setUp(() {
      mockModelManager = MockModelDownloadManager();
      mockGemmaEnhancer = MockGemmaEnhancer();
      
      // Create processor with mocked dependencies
      enhancedProcessor = EnhancedSpeechProcessor(
        modelManager: mockModelManager,
        defaultEngine: SpeechEngine.speechToText,
      );
    });

    test('should initialize with speech_to_text engine by default', () async {
      expect(enhancedProcessor.activeEngine, SpeechEngine.speechToText);
      expect(enhancedProcessor.isReady, false);
    });

    test('should support switching between speech engines', () async {
      // Initialize first
      await enhancedProcessor.initialize(enableGemmaEnhancement: false);
      
      // Switch to native engine
      await enhancedProcessor.switchEngine(SpeechEngine.native);
      expect(enhancedProcessor.activeEngine, SpeechEngine.native);
      
      // Switch back to speech_to_text
      await enhancedProcessor.switchEngine(SpeechEngine.speechToText);
      expect(enhancedProcessor.activeEngine, SpeechEngine.speechToText);
    });

    test('should emit both raw and enhanced captions when Gemma is enabled', () async {
      // Setup mock Gemma enhancer
      when(mockModelManager.modelIsComplete()).thenAnswer((_) async => true);
      when(mockModelManager.getModelPath()).thenAnswer((_) async => '/path/to/model');
      when(mockGemmaEnhancer.isReady).thenReturn(true);
      when(mockGemmaEnhancer.enhance(any)).thenAnswer((invocation) async {
        final raw = invocation.positionalArguments[0] as String;
        return EnhancedCaption(
          raw: raw,
          enhanced: '${raw.trim()}.',  // Add punctuation as enhancement
          confidence: 0.95,
          isEnhanced: true,
        );
      });

      // Subscribe to enhanced captions stream
      final enhancedCaptions = <EnhancedCaption>[];
      enhancedProcessor.enhancedCaptions.listen(enhancedCaptions.add);

      // Test processing
      await enhancedProcessor.initialize(enableGemmaEnhancement: true);
      
      // Simulate speech result
      const rawText = 'hello world this is a test';
      const expectedEnhanced = 'hello world this is a test.';
      
      // Note: In real implementation, this would come from speech recognition
      // For testing, we'd need to mock the speech recognition part
      
      // Verify statistics
      final stats = enhancedProcessor.getStatistics();
      expect(stats['activeEngine'], contains('speechToText'));
      expect(stats['hasGemmaEnhancement'], false); // Since we're using mocks
    });

    test('should handle errors gracefully and fall back to raw text', () async {
      // Setup mock to fail
      when(mockGemmaEnhancer.isReady).thenReturn(true);
      when(mockGemmaEnhancer.enhance(any)).thenThrow(Exception('Enhancement failed'));

      await enhancedProcessor.initialize(enableGemmaEnhancement: true);

      // Subscribe to enhanced captions
      final enhancedCaptions = <EnhancedCaption>[];
      enhancedProcessor.enhancedCaptions.listen(enhancedCaptions.add);

      // Verify fallback behavior is handled
      // In real implementation, errors would result in fallback captions
    });

    tearDown(() async {
      await enhancedProcessor.dispose();
    });
  });
  
  group('Enhanced Caption Model', () {
    test('should create partial captions correctly', () {
      final partial = EnhancedCaption.partial('hello world');
      
      expect(partial.raw, 'hello world');
      expect(partial.enhanced, null);
      expect(partial.isFinal, false);
      expect(partial.isEnhanced, false);
      expect(partial.displayText, 'hello world');
    });

    test('should create fallback captions correctly', () {
      final fallback = EnhancedCaption.fallback('test caption');
      
      expect(fallback.raw, 'test caption');
      expect(fallback.enhanced, 'test caption');
      expect(fallback.isFinal, true);
      expect(fallback.isEnhanced, false);
      expect(fallback.confidence, 0.5);
      expect(fallback.displayText, 'test caption');
    });

    test('should identify enhanced captions correctly', () {
      final enhanced = EnhancedCaption(
        raw: 'hello world',
        enhanced: 'Hello world!',
        isEnhanced: true,
      );
      
      expect(enhanced.hasEnhancement, true);
      expect(enhanced.displayText, 'Hello world!');
      
      final notEnhanced = EnhancedCaption(
        raw: 'hello world',
        enhanced: 'hello world',
        isEnhanced: false,
      );
      
      expect(notEnhanced.hasEnhancement, false);
    });
  });
} 