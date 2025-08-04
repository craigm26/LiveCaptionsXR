import 'package:flutter/material.dart';
import 'model_downloads_page.dart';

void main() {
  runApp(const ModelDownloadsApp());
}

class ModelDownloadsApp extends StatelessWidget {
  const ModelDownloadsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Model Downloads Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ModelDownloadsPage(),
    );
  }
} 