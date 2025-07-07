import 'dart:typed_data';
import 'package:gemma3n_multimodal/gemma3n_multimodal.dart';

/// Example demonstrating the enhanced ASR functionality
///
/// This example shows how to use the hybrid ASR implementation that combines
/// native platform speech recognition with Gemma 3n enhancement.
class ASRExample {
  final Gemma3nMultimodal _plugin = Gemma3nMultimodal();
  bool _isInitialized = false;

  /// Initialize the ASR system with hybrid configuration
  Future<void> initializeASR() async {
    try {
      print('🚀 Initializing ASR with hybrid approach...');

      // Load the Gemma 3n model for enhancement
      try {
        await _plugin.loadModel(
          'assets/models/gemma-3n-E2B-it-int4.task',
          useGPU: false, // Use CPU for better compatibility
        );
        print('✅ Gemma 3n model loaded successfully');
        _isInitialized = true;
      } catch (e) {
        print('⚠️ Gemma 3n model loading failed: $e');
        print('⚠️ ASR will use native-only mode');
        _isInitialized = true; // Still usable with native ASR
      }

      print('🎤 ASR system ready with:');
      print('  - Native iOS Speech Framework / Android SpeechRecognizer');
      print('  - Gemma 3n enhancement (if model loaded)');
      print('  - Fallback bridge implementation');
    } catch (e) {
      print('❌ ASR initialization failed: $e');
      throw Exception('Failed to initialize ASR: $e');
    }
  }

  /// Transcribe audio using the hybrid ASR approach
  Future<String> transcribeAudio(
    Uint8List audioBytes, {
    bool isFinal = false,
    String language = 'en',
  }) async {
    if (!_isInitialized) {
      throw StateError('ASR not initialized. Call initializeASR() first.');
    }

    try {
      print(
          '🎙️ Transcribing audio (${audioBytes.length} bytes, ${isFinal ? 'final' : 'interim'})');

      // Call the native ASR implementation
      final result = await _plugin.transcribeAudio(
        audio: audioBytes,
        isFinal: isFinal,
        language: language,
        useNativeSpeechRecognition: true,
        enableRealTimeEnhancement: true,
      );

      if (result.isNotEmpty && result != '[No speech detected]') {
        print('📝 Transcription result: "$result"');
      } else {
        print('🔇 No speech detected in audio buffer');
      }

      return result;
    } catch (e) {
      print('❌ Transcription failed: $e');
      rethrow;
    }
  }

  /// Example: Process a simulated audio stream
  Future<void> processAudioStream() async {
    await initializeASR();

    print('\n🎵 Simulating audio stream processing...\n');

    // Simulate audio chunks (in a real app, these would come from microphone)
    final audioChunks = [
      _generateSimulatedAudio(800, 'short'), // 0.05 seconds
      _generateSimulatedAudio(1600, 'medium'), // 0.1 seconds
      _generateSimulatedAudio(3200, 'speech'), // 0.2 seconds
      _generateSimulatedAudio(8000, 'sentence'), // 0.5 seconds
    ];

    for (int i = 0; i < audioChunks.length; i++) {
      final isLast = i == audioChunks.length - 1;

      print('📊 Processing chunk ${i + 1}/${audioChunks.length}');

      try {
        final result = await transcribeAudio(
          audioChunks[i],
          isFinal: isLast,
          language: 'en',
        );

        if (isLast) {
          print('🎯 Final transcription: "$result"');
        } else {
          print('⏳ Interim result: "$result"');
        }
      } catch (e) {
        print('❌ Error processing chunk ${i + 1}: $e');
      }

      // Simulate processing delay
      await Future.delayed(Duration(milliseconds: 100));
    }
  }

  /// Example: Test different languages
  Future<void> testMultiLanguageSupport() async {
    await initializeASR();

    print('\n🌍 Testing multi-language support...\n');

    final languages = [
      {'code': 'en', 'name': 'English'},
      {'code': 'es', 'name': 'Spanish'},
      {'code': 'fr', 'name': 'French'},
      {'code': 'de', 'name': 'German'},
    ];

    final testAudio = _generateSimulatedAudio(3200, 'speech');

    for (final lang in languages) {
      print('🗣️ Testing ${lang['name']} (${lang['code']})...');

      try {
        final result = await transcribeAudio(
          testAudio,
          isFinal: true,
          language: lang['code']!,
        );

        print('📝 ${lang['name']} result: "$result"');
      } catch (e) {
        print('❌ Error with ${lang['name']}: $e');
      }

      await Future.delayed(Duration(milliseconds: 200));
    }
  }

  /// Example: Test error handling
  Future<void> testErrorHandling() async {
    await initializeASR();

    print('\n🧪 Testing error handling...\n');

    // Test with empty audio
    try {
      print('Testing empty audio...');
      final result = await transcribeAudio(Uint8List(0));
      print('Result: "$result"');
    } catch (e) {
      print('Expected error: $e');
    }

    // Test with very short audio
    try {
      print('Testing very short audio...');
      final result =
          await transcribeAudio(_generateSimulatedAudio(10, 'silence'));
      print('Result: "$result"');
    } catch (e) {
      print('Unexpected error: $e');
    }

    // Test with invalid format
    try {
      print('Testing invalid audio format...');
      final result = await transcribeAudio(Uint8List.fromList([255, 255, 255]));
      print('Result: "$result"');
    } catch (e) {
      print('Expected error: $e');
    }
  }

  /// Generate simulated audio data for testing
  Uint8List _generateSimulatedAudio(int samples, String type) {
    final buffer = <int>[];

    switch (type) {
      case 'silence':
        // Generate silent audio
        for (int i = 0; i < samples * 2; i++) {
          buffer.add(0);
        }
        break;

      case 'short':
        // Generate very brief audio with low amplitude
        for (int i = 0; i < samples * 2; i++) {
          final value = (1000 * (i % 100 / 100.0)).round();
          buffer.add(value & 0xFF);
          buffer.add((value >> 8) & 0xFF);
        }
        break;

      case 'medium':
        // Generate medium-length audio with moderate amplitude
        for (int i = 0; i < samples * 2; i++) {
          final value = (5000 * (i % 200 / 200.0)).round();
          buffer.add(value & 0xFF);
          buffer.add((value >> 8) & 0xFF);
        }
        break;

      case 'speech':
        // Generate audio that simulates speech patterns
        for (int i = 0; i < samples * 2; i++) {
          final freq1 = 440.0; // A4 note
          final freq2 = 880.0; // A5 note
          final time = i / (16000.0 * 2); // Assuming 16kHz sample rate
          final value = (10000 *
                  (0.6 * Math.sin(2 * Math.pi * freq1 * time) +
                      0.4 * Math.sin(2 * Math.pi * freq2 * time)))
              .round();
          buffer.add(value & 0xFF);
          buffer.add((value >> 8) & 0xFF);
        }
        break;

      case 'sentence':
        // Generate longer audio with speech-like characteristics
        for (int i = 0; i < samples * 2; i++) {
          final time = i / (16000.0 * 2);
          final envelope =
              Math.sin(Math.pi * time * 2) * 0.8 + 0.2; // Amplitude envelope
          final freq =
              200 + 100 * Math.sin(2 * Math.pi * time * 3); // Varying frequency
          final value =
              (15000 * envelope * Math.sin(2 * Math.pi * freq * time)).round();
          buffer.add(value & 0xFF);
          buffer.add((value >> 8) & 0xFF);
        }
        break;
    }

    return Uint8List.fromList(buffer);
  }

  /// Clean up resources
  Future<void> dispose() async {
    print('🧹 Cleaning up ASR resources...');
    // Note: In a real implementation, you might want to add cleanup methods
    // to the plugin to properly dispose of speech recognition resources
    _isInitialized = false;
  }
}

/// Helper class for Math operations (since dart:math import might not be available)
class Math {
  static double sin(double x) => _sin(x);
  static double cos(double x) => _cos(x);
  static const double pi = 3.141592653589793;

  // Simplified sine implementation using Taylor series
  static double _sin(double x) {
    x = x % (2 * pi);
    double result = x;
    double term = x;
    for (int i = 1; i < 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  static double _cos(double x) => _sin(pi / 2 - x);
}

/// Main function to run the ASR examples
Future<void> main() async {
  final asrExample = ASRExample();

  try {
    print('🎤 ASR Implementation Example\n');
    print('=' * 50);

    // Run audio stream processing example
    await asrExample.processAudioStream();

    print('\n' + '=' * 50);

    // Test multi-language support
    await asrExample.testMultiLanguageSupport();

    print('\n' + '=' * 50);

    // Test error handling
    await asrExample.testErrorHandling();

    print('\n' + '=' * 50);
    print('✅ All ASR examples completed successfully!');
  } catch (e) {
    print('❌ Example failed: $e');
  } finally {
    await asrExample.dispose();
  }
}
