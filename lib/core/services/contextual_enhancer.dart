import 'dart:async';
import 'dart:typed_data';
import 'package:live_captions_xr/core/services/gemma_3n_service.dart';
import 'package:live_captions_xr/core/services/visual_service.dart';

class ContextualEnhancer {
  final Gemma3nService _gemma3nService;
  final VisualService _visualService;

  ContextualEnhancer(this._gemma3nService, this._visualService);

  Future<String> enhanceText(String text) async {
    final imageBytes = await _visualService.captureVisualSnapshot();
    
    return await _gemma3nService.multimodalInference(
      text: text,
      image: imageBytes,
    ) ?? text;
  }
}
