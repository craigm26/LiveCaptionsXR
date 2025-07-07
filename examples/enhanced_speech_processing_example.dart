// Example: Using the Enhanced Speech Processing System
// This demonstrates the new configurable thresholds, language detection,
// and real-time text enhancement capabilities.

import 'package:flutter/material.dart';
import 'package:live_captions_xr/core/services/speech_processor.dart';
import 'package:live_captions_xr/core/models/speech_config.dart';
import 'package:live_captions_xr/core/models/speech_result.dart';

class EnhancedSpeechExample extends StatefulWidget {
  @override
  _EnhancedSpeechExampleState createState() => _EnhancedSpeechExampleState();
}

class _EnhancedSpeechExampleState extends State<EnhancedSpeechExample> {
  late SpeechProcessor speechProcessor;
  String currentText = '';
  String currentLanguage = 'en';
  double voiceThreshold = 0.01;
  bool isProcessing = false;
  List<SpeechResult> recentResults = [];

  @override
  void initState() {
    super.initState();
    speechProcessor = SpeechProcessor();
    _initializeSpeechProcessor();
  }

  Future<void> _initializeSpeechProcessor() async {
    // Initialize with multilingual configuration
    final success = await speechProcessor.initialize(
      config: SpeechConfig.multilingual.copyWith(
        voiceActivityThreshold: voiceThreshold,
      ),
    );

    if (success) {
      // Listen for speech results
      speechProcessor.speechResults.listen((result) {
        setState(() {
          recentResults.insert(0, result);
          if (recentResults.length > 10) recentResults.removeLast();

          if (result.isLanguageDetection) {
            currentLanguage = result.detectedLanguage ?? currentLanguage;
            currentText = 'Language detected: $currentLanguage';
          } else if (result.hasActualSpeech) {
            currentText = result.text;
          }
        });
      });
    }
  }

  Future<void> _startProcessing() async {
    final success = await speechProcessor.startProcessing();
    setState(() {
      isProcessing = success;
    });
  }

  Future<void> _stopProcessing() async {
    await speechProcessor.stopProcessing();
    setState(() {
      isProcessing = false;
    });
  }

  Future<void> _updateThreshold(double newThreshold) async {
    final newConfig = speechProcessor.config.copyWith(
      voiceActivityThreshold: newThreshold,
    );
    
    await speechProcessor.updateConfig(newConfig);
    setState(() {
      voiceThreshold = newThreshold;
    });
  }

  Future<void> _enhanceText() async {
    if (currentText.isNotEmpty) {
      final enhanced = await speechProcessor.enhanceText(
        currentText,
        context: 'Live captioning session',
      );
      
      setState(() {
        currentText = enhanced;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enhanced Speech Processing Demo'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Controls
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: ${isProcessing ? 'Processing' : 'Stopped'}'),
                    Text('Language: $currentLanguage'),
                    Text('Threshold: ${voiceThreshold.toStringAsFixed(3)}'),
                    SizedBox(height: 10),
                    
                    // Voice Activity Threshold Slider
                    Text('Voice Activity Threshold'),
                    Slider(
                      value: voiceThreshold,
                      min: 0.005,
                      max: 0.05,
                      divisions: 45,
                      label: voiceThreshold.toStringAsFixed(3),
                      onChanged: _updateThreshold,
                    ),
                    
                    // Control Buttons
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: isProcessing ? _stopProcessing : _startProcessing,
                          child: Text(isProcessing ? 'Stop' : 'Start'),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _enhanceText,
                          child: Text('Enhance Text'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Current Text Display
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Text:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        currentText.isEmpty ? 'No speech detected yet...' : currentText,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Recent Results
            Expanded(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recent Results:', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: recentResults.length,
                          itemBuilder: (context, index) {
                            final result = recentResults[index];
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                result.isLanguageDetection 
                                  ? Icons.language 
                                  : result.isFinal 
                                    ? Icons.check_circle 
                                    : Icons.radio_button_unchecked,
                                color: result.isLanguageDetection 
                                  ? Colors.blue 
                                  : result.isFinal 
                                    ? Colors.green 
                                    : Colors.orange,
                                size: 16,
                              ),
                              title: Text(
                                result.text,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: result.isLanguageDetection ? FontStyle.italic : FontStyle.normal,
                                ),
                              ),
                              subtitle: Text(
                                'Confidence: ${result.confidence.toStringAsFixed(2)} | '
                                '${result.timestamp.toString().substring(11, 19)}',
                                style: TextStyle(fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Quick Configuration Presets
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick Presets:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: [
                        ElevatedButton(
                          onPressed: () => speechProcessor.updateConfig(SpeechConfig.lowLatency),
                          child: Text('Low Latency'),
                        ),
                        ElevatedButton(
                          onPressed: () => speechProcessor.updateConfig(SpeechConfig.highAccuracy),
                          child: Text('High Accuracy'),
                        ),
                        ElevatedButton(
                          onPressed: () => speechProcessor.updateConfig(SpeechConfig.multilingual),
                          child: Text('Multilingual'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    speechProcessor.dispose();
    super.dispose();
  }
}

// Example usage patterns for different scenarios
class SpeechProcessingExamples {
  
  // Example 1: High-accuracy conference transcription
  static Future<void> conferenceTranscription() async {
    final processor = SpeechProcessor();
    
    await processor.initialize(
      config: SpeechConfig.highAccuracy.copyWith(
        language: 'en',
        enableRealTimeEnhancement: true,
      ),
    );
    
    await processor.startProcessing();
    
    processor.speechResults.listen((result) {
      if (result.isFinal && result.hasActualSpeech) {
        print('Conference transcript: ${result.text}');
      }
    });
  }
  
  // Example 2: Low-latency gaming/VR scenario
  static Future<void> gamingCommands() async {
    final processor = SpeechProcessor();
    
    await processor.initialize(
      config: SpeechConfig.lowLatency.copyWith(
        voiceActivityThreshold: 0.02, // Higher threshold for noisy environments
        enableRealTimeEnhancement: false, // Skip enhancement for speed
      ),
    );
    
    await processor.startProcessing();
    
    processor.speechResults.listen((result) {
      if (!result.isFinal && result.hasActualSpeech) {
        // Process commands immediately on interim results
        print('Game command: ${result.text}');
      }
    });
  }
  
  // Example 3: Multilingual customer support
  static Future<void> customerSupport() async {
    final processor = SpeechProcessor();
    
    await processor.initialize(
      config: SpeechConfig.multilingual.copyWith(
        supportedLanguages: ['en', 'es', 'fr', 'de', 'zh'],
        enableLanguageDetection: true,
        enableRealTimeEnhancement: true,
      ),
    );
    
    await processor.startProcessing();
    
    String currentLanguage = 'en';
    
    processor.speechResults.listen((result) {
      if (result.isLanguageDetection) {
        currentLanguage = result.detectedLanguage ?? currentLanguage;
        print('Customer switched to: $currentLanguage');
      } else if (result.isFinal && result.hasActualSpeech) {
        print('Customer [$currentLanguage]: ${result.text}');
      }
    });
  }
}