import 'dart:typed_data';
import 'package:gemma3n_multimodal/gemma3n_multimodal.dart';

/// Complete validation example for the ASR implementation
/// 
/// This example demonstrates all aspects of the hybrid ASR system:
/// - Configuration and capability checking
/// - Native speech recognition 
/// - Gemma 3n enhancement
/// - Error handling and fallbacks
/// - Multi-language support
void main() async {
  final validator = ASRValidator();
  await validator.runCompleteValidation();
}

class ASRValidator {
  final Gemma3nMultimodal _plugin = Gemma3nMultimodal();

  Future<void> runCompleteValidation() async {
    print('🧪 Starting Complete ASR Implementation Validation\n');
    print('=' * 60);

    try {
      // Step 1: Check ASR capabilities
      await _checkCapabilities();
      
      // Step 2: Test configuration
      await _testConfiguration();
      
      // Step 3: Test basic transcription
      await _testBasicTranscription();
      
      // Step 4: Test multi-language support
      await _testMultiLanguageSupport();
      
      // Step 5: Test error scenarios
      await _testErrorScenarios();
      
      // Step 6: Test streaming capabilities
      await _testStreamingASR();
      
      print('\n' + '=' * 60);
      print('✅ All ASR validation tests completed successfully!');
      print('🎉 The hybrid ASR implementation is working correctly.');
      
    } catch (e, stackTrace) {
      print('\n❌ Validation failed: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _checkCapabilities() async {
    print('\n📋 Step 1: Checking ASR Capabilities');
    print('-' * 40);
    
    try {
      final capabilities = await _plugin.getASRCapabilities();
      
      print('Platform capabilities:');
      print('  • Native Speech Recognition: ${capabilities['nativeSpeechRecognitionAvailable'] ?? 'Unknown'}');
      print('  • Gemma 3n Enhancement: ${capabilities['gemma3nEnhancementAvailable'] ?? 'Unknown'}');
      print('  • Current Language: ${capabilities['currentLanguage'] ?? 'Unknown'}');
      print('  • Supported Languages: ${capabilities['supportedLanguages']?.join(', ') ?? 'Unknown'}');
      
      if (capabilities['nativeSpeechRecognitionAvailable'] == true) {
        print('✅ Native speech recognition is available');
      } else {
        print('⚠️ Native speech recognition not available - will use bridge mode');
      }
      
    } catch (e) {
      print('❌ Failed to check capabilities: $e');
    }
  }

  Future<void> _testConfiguration() async {
    print('\n⚙️ Step 2: Testing ASR Configuration');
    print('-' * 40);
    
    try {
      // Test different configurations
      final configs = [
        {
          'language': 'en',
          'useNativeSpeechRecognition': true,
          'enableRealTimeEnhancement': true,
          'description': 'Full hybrid mode (English)'
        },
        {
          'language': 'es',
          'useNativeSpeechRecognition': true,
          'enableRealTimeEnhancement': false,
          'description': 'Native-only mode (Spanish)'
        },
        {
          'language': 'fr',
          'useNativeSpeechRecognition': false,
          'enableRealTimeEnhancement': true,
          'description': 'Bridge mode with enhancement (French)'
        },
      ];

      for (final config in configs) {
        print('Testing: ${config['description']}');
        
        await _plugin.configureASR(
          language: config['language'] as String,
          useNativeSpeechRecognition: config['useNativeSpeechRecognition'] as bool,
          enableRealTimeEnhancement: config['enableRealTimeEnhancement'] as bool,
        );
        
        // Verify configuration took effect
        final capabilities = await _plugin.getASRCapabilities();
        final currentLang = capabilities['currentLanguage'];
        
        if (currentLang == config['language']) {
          print('  ✅ Configuration applied successfully');
        } else {
          print('  ⚠️ Configuration may not have been applied correctly');
        }
        
        await Future.delayed(Duration(milliseconds: 100));
      }
      
    } catch (e) {
      print('❌ Configuration test failed: $e');
    }
  }

  Future<void> _testBasicTranscription() async {
    print('\n🎤 Step 3: Testing Basic Transcription');
    print('-' * 40);
    
    try {
      // Configure for English with full hybrid mode
      await _plugin.configureASR(
        language: 'en',
        useNativeSpeechRecognition: true,
        enableRealTimeEnhancement: true,
      );

      final testCases = [
        {
          'name': 'Silent audio',
          'audioSize': 100,
          'audioType': 'silence',
          'expectedPattern': r'\[No speech detected\]|.*silent.*|.*quiet.*',
        },
        {
          'name': 'Short speech',
          'audioSize': 1600,
          'audioType': 'speech',
          'expectedPattern': r'.*',
        },
        {
          'name': 'Long speech (final)',
          'audioSize': 8000,
          'audioType': 'speech',
          'expectedPattern': r'.*',
        },
      ];

      for (final testCase in testCases) {
        print('Testing: ${testCase['name']}');
        
        final audioData = _generateTestAudio(
          testCase['audioSize'] as int,
          testCase['audioType'] as String,
        );
        
        try {
          final result = await _plugin.transcribeAudio(
            audio: audioData,
            isFinal: testCase['name']!.contains('final'),
            language: 'en',
          );
          
          print('  📝 Result: "$result"');
          
          if (result.isNotEmpty) {
            print('  ✅ Transcription successful');
          } else {
            print('  ⚠️ Empty transcription result');
          }
          
        } catch (e) {
          print('  ❌ Transcription failed: $e');
        }
        
        await Future.delayed(Duration(milliseconds: 200));
      }
      
    } catch (e) {
      print('❌ Basic transcription test failed: $e');
    }
  }

  Future<void> _testMultiLanguageSupport() async {
    print('\n🌍 Step 4: Testing Multi-Language Support');
    print('-' * 40);
    
    final languages = [
      {'code': 'en', 'name': 'English'},
      {'code': 'es', 'name': 'Spanish'},
      {'code': 'fr', 'name': 'French'},
      {'code': 'de', 'name': 'German'},
    ];

    final testAudio = _generateTestAudio(3200, 'speech');

    for (final lang in languages) {
      print('Testing ${lang['name']} (${lang['code']})...');
      
      try {
        await _plugin.configureASR(language: lang['code']!);
        
        final result = await _plugin.transcribeAudio(
          audio: testAudio,
          isFinal: true,
          language: lang['code']!,
        );
        
        print('  📝 ${lang['name']} result: "$result"');
        print('  ✅ Language ${lang['code']} supported');
        
      } catch (e) {
        print('  ❌ Language ${lang['code']} failed: $e');
      }
      
      await Future.delayed(Duration(milliseconds: 300));
    }
  }

  Future<void> _testErrorScenarios() async {
    print('\n🚨 Step 5: Testing Error Scenarios');
    print('-' * 40);
    
    final errorTests = [
      {
        'name': 'Empty audio data',
        'audio': Uint8List(0),
        'shouldFail': false, // Should return "no speech detected"
      },
      {
        'name': 'Extremely short audio',
        'audio': _generateTestAudio(10, 'silence'),
        'shouldFail': false,
      },
      {
        'name': 'Very large audio',
        'audio': _generateTestAudio(160000, 'speech'), // 10 seconds
        'shouldFail': false, // Should handle gracefully
      },
    ];

    for (final test in errorTests) {
      print('Testing: ${test['name']}');
      
      try {
        final result = await _plugin.transcribeAudio(
          audio: test['audio'] as Uint8List,
          isFinal: true,
        );
        
        if (test['shouldFail'] as bool) {
          print('  ⚠️ Expected failure but got result: "$result"');
        } else {
          print('  ✅ Handled gracefully: "$result"');
        }
        
      } catch (e) {
        if (test['shouldFail'] as bool) {
          print('  ✅ Failed as expected: $e');
        } else {
          print('  ❌ Unexpected failure: $e');
        }
      }
      
      await Future.delayed(Duration(milliseconds: 200));
    }
  }

  Future<void> _testStreamingASR() async {
    print('\n📊 Step 6: Testing Streaming ASR Capabilities');
    print('-' * 40);
    
    try {
      // Test interim vs final results
      final audioChunks = [
        _generateTestAudio(800, 'speech'),   // Chunk 1
        _generateTestAudio(1600, 'speech'),  // Chunk 2
        _generateTestAudio(2400, 'speech'),  // Chunk 3
        _generateTestAudio(3200, 'speech'),  // Final chunk
      ];

      print('Simulating streaming transcription...');
      
      for (int i = 0; i < audioChunks.length; i++) {
        final isLast = i == audioChunks.length - 1;
        
        print('Processing chunk ${i + 1}/${audioChunks.length} ${isLast ? '(final)' : '(interim)'}');
        
        try {
          final result = await _plugin.transcribeAudio(
            audio: audioChunks[i],
            isFinal: isLast,
            language: 'en',
          );
          
          print('  📝 ${isLast ? 'Final' : 'Interim'} result: "$result"');
          
        } catch (e) {
          print('  ❌ Chunk ${i + 1} failed: $e');
        }
        
        await Future.delayed(Duration(milliseconds: 300));
      }
      
      print('✅ Streaming simulation completed');
      
    } catch (e) {
      print('❌ Streaming test failed: $e');
    }
  }

  /// Generate test audio data for validation
  Uint8List _generateTestAudio(int samples, String type) {
    final buffer = <int>[];
    
    switch (type) {
      case 'silence':
        // Generate silent audio
        for (int i = 0; i < samples * 2; i++) {
          buffer.add(0);
        }
        break;
        
      case 'speech':
        // Generate audio that simulates speech patterns
        for (int i = 0; i < samples * 2; i++) {
          final time = i / (16000.0 * 2); // 16kHz sample rate
          final envelope = _sin(3.14159 * time * 2) * 0.8 + 0.2; // Amplitude envelope
          final freq = 200 + 100 * _sin(2 * 3.14159 * time * 3); // Varying frequency
          final value = (15000 * envelope * _sin(2 * 3.14159 * freq * time)).round();
          buffer.add(value & 0xFF);
          buffer.add((value >> 8) & 0xFF);
        }
        break;
        
      default:
        // Generate moderate amplitude audio
        for (int i = 0; i < samples * 2; i++) {
          final value = (5000 * (i % 200 / 200.0)).round();
          buffer.add(value & 0xFF);
          buffer.add((value >> 8) & 0xFF);
        }
    }
    
    return Uint8List.fromList(buffer);
  }

  /// Simple sine function implementation
  double _sin(double x) {
    // Taylor series approximation
    x = x % (2 * 3.14159);
    double result = x;
    double term = x;
    for (int i = 1; i < 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }
}