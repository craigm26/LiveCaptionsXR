import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Legacy model status page — redirects to the unified AI Models page.
class ModelStatusPage extends StatefulWidget {
  const ModelStatusPage({super.key});

  @override
  State<ModelStatusPage> createState() => _ModelStatusPageState();
}

class _ModelStatusPageState extends State<ModelStatusPage> {
  @override
  void initState() {
    super.initState();
    // Redirect to the unified model management page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/models');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
