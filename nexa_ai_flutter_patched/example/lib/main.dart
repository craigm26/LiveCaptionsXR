import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nexa_ai_flutter/nexa_ai_flutter.dart';
import 'model_management_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexa AI Flutter Demo',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isInitialized = false;
  String _status = 'Not initialized';

  @override
  void initState() {
    super.initState();
    _initializeSdk();
  }

  Future<void> _initializeSdk() async {
    try {
      await NexaSdk.getInstance().init();
      setState(() {
        _isInitialized = true;
        _status = 'SDK initialized successfully';
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to initialize SDK: $e';
      });
      log('Failed to initialize SDK: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nexa AI Flutter Demo'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(_isInitialized ? Icons.check_circle : Icons.info, size: 64, color: _isInitialized ? Colors.green : Colors.orange),
            const SizedBox(height: 16),
            Text(_status, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 32),
            if (_isInitialized) ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ModelManagementPage()));
                },
                icon: const Icon(Icons.download),
                label: const Text('Download & Manage Models'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), textStyle: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 32),
              const Text('Available Model Types:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildFeatureCard(
                context,
                'LLM - Large Language Models',
                'Text generation and chat with streaming support',
                Icons.chat_bubble_outline,
                () => _showLlmExample(context),
              ),
              _buildFeatureCard(context, 'VLM - Vision-Language Models', 'Multimodal AI with image and audio understanding', Icons.image, () => _showVlmExample(context)),
              _buildFeatureCard(context, 'Embeddings', 'Generate vector embeddings for semantic search', Icons.account_tree, () => _showEmbeddingExample(context)),
              _buildFeatureCard(context, 'ASR - Speech Recognition', 'Transcribe audio to text', Icons.mic, () => _showAsrExample(context)),
              _buildFeatureCard(context, 'Reranker', 'Improve search relevance with document reranking', Icons.sort, () => _showRerankerExample(context)),
              _buildFeatureCard(context, 'Computer Vision', 'OCR, object detection, and classification', Icons.camera_alt, () => _showCvExample(context)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title, String description, IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  void _showLlmExample(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('LLM Example'),
        content: const SingleChildScrollView(
          child: Text(
            'LLM Usage:\n\n'
            '1. Create model:\n'
            'final llm = await LlmWrapper.create(\n'
            '  LlmCreateInput(\n'
            '    modelPath: "/path/to/model",\n'
            '    config: ModelConfig(maxTokens: 2048),\n'
            '    pluginId: "cpu_gpu", // or "npu"\n'
            '  ),\n'
            ');\n\n'
            '2. Generate with streaming:\n'
            'llm.generateStream(prompt, config).listen((result) {\n'
            '  if (result is LlmStreamToken) {\n'
            '    print(result.text);\n'
            '  }\n'
            '});\n\n'
            '3. Clean up:\n'
            'await llm.destroy();',
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _showVlmExample(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('VLM Example'),
        content: const SingleChildScrollView(
          child: Text(
            'VLM Usage:\n\n'
            '1. Create model:\n'
            'final vlm = await VlmWrapper.create(\n'
            '  VlmCreateInput(\n'
            '    modelPath: "/path/to/model",\n'
            '    config: ModelConfig(),\n'
            '    pluginId: "npu",\n'
            '  ),\n'
            ');\n\n'
            '2. Create multimodal message:\n'
            'final message = VlmChatMessage("user", [\n'
            '  VlmContent("image", "/path/to/image.jpg"),\n'
            '  VlmContent("text", "What is in this image?"),\n'
            ']);\n\n'
            '3. Generate response:\n'
            'final template = await vlm.applyChatTemplate([message]);\n'
            'final config = vlm.injectMediaPathsToConfig([message], baseConfig);\n'
            'vlm.generateStream(template.formattedText, config).listen(...);',
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _showEmbeddingExample(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Embeddings Example'),
        content: const SingleChildScrollView(
          child: Text(
            'Embeddings Usage:\n\n'
            '1. Create embedder:\n'
            'final embedder = await EmbedderWrapper.create(\n'
            '  EmbedderCreateInput(\n'
            '    modelPath: "/path/to/embedder",\n'
            '    config: ModelConfig(),\n'
            '    pluginId: "npu",\n'
            '  ),\n'
            ');\n\n'
            '2. Generate embeddings:\n'
            'final embeddings = await embedder.embed(\n'
            '  ["text1", "text2"],\n'
            '  EmbeddingConfig(normalize: true),\n'
            ');\n\n'
            '3. Use embeddings:\n'
            'final dimension = embeddings.length ~/ 2;\n'
            'print("Dimension: \$dimension");',
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _showAsrExample(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ASR Example'),
        content: const SingleChildScrollView(
          child: Text(
            'ASR Usage:\n\n'
            '1. Create ASR model:\n'
            'final asr = await AsrWrapper.create(\n'
            '  AsrCreateInput(\n'
            '    modelPath: "/path/to/asr",\n'
            '    config: ModelConfig(),\n'
            '    pluginId: "npu",\n'
            '  ),\n'
            ');\n\n'
            '2. Transcribe audio:\n'
            'final result = await asr.transcribe(\n'
            '  AsrTranscribeInput(\n'
            '    audioPath: "/path/to/audio.wav",\n'
            '    language: "en",\n'
            '  ),\n'
            ');\n\n'
            'print(result.result.transcript);',
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _showRerankerExample(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reranker Example'),
        content: const SingleChildScrollView(
          child: Text(
            'Reranker Usage:\n\n'
            '1. Create reranker:\n'
            'final reranker = await RerankerWrapper.create(\n'
            '  RerankerCreateInput(\n'
            '    modelPath: "/path/to/reranker",\n'
            '    config: ModelConfig(),\n'
            '    pluginId: "npu",\n'
            '  ),\n'
            ');\n\n'
            '2. Rerank documents:\n'
            'final result = await reranker.rerank(\n'
            '  "query text",\n'
            '  ["doc1", "doc2", "doc3"],\n'
            '  RerankConfig(topN: 3),\n'
            ');\n\n'
            'for (var i = 0; i < result.scores.length; i++) {\n'
            '  print("Score: \${result.scores[i]}");\n'
            '}',
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _showCvExample(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Computer Vision Example'),
        content: const SingleChildScrollView(
          child: Text(
            'CV Usage:\n\n'
            '1. Create CV model:\n'
            'final cv = await CvWrapper.create(\n'
            '  CVCreateInput(\n'
            '    modelName: "paddleocr",\n'
            '    config: CVModelConfig(\n'
            '      capabilities: CVCapability.ocr,\n'
            '      detModelPath: "/path/to/det",\n'
            '      recModelPath: "/path/to/rec",\n'
            '    ),\n'
            '    pluginId: "npu",\n'
            '  ),\n'
            ');\n\n'
            '2. Perform OCR:\n'
            'final results = await cv.infer("/path/to/image.jpg");\n'
            'for (var result in results) {\n'
            '  print("\${result.text}: \${result.confidence}");\n'
            '}',
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }
}
