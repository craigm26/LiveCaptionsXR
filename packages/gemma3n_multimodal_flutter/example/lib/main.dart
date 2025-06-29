import 'dart:io' show Platform;
import 'package:flutter/services.dart' show rootBundle, Uint8List, ByteData;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:gemma3n_multimodal_flutter/gemma3n_multimodal_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _response = 'No response yet.';
  GemmaTaskModel? _model;
  Session? _session;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _runInference() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      setState(() {
        _response = 'This plugin is not supported on the current platform.';
      });
      return;
    }

    try {
      _model = await GemmaTaskModel.create('assets/models/gemma-3n-E4B-it-int4.task');
      _session = await _model!.createSession();

      // Load image from assets
      final ByteData imageData = await rootBundle.load('assets/images/placeholder.png');
      final Uint8List imageBytes = imageData.buffer.asUint8List();

      await _session!.addQueryChunk(Message.text(text: 'Describe this image:', isUser: true));
      await _session!.addQueryChunk(Message.imageOnly(imageBytes: imageBytes, isUser: true));
      final response = await _session!.getResponse();
      setState(() {
        _response = response;
      });
    } catch (e) {
      setState(() {
        _response = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Gemma3n Multimodal Example'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_response),
              ),
              ElevatedButton(
                onPressed: _runInference,
                child: const Text('Run Inference'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _session?.close();
    _model?.close();
    super.dispose();
  }
}
