import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import '../../../core/models/visual_object.dart';
import '../../../core/services/hybrid_localization_engine.dart';
import '../../../core/services/debug_capturing_logger.dart';

abstract class VisualIdentificationState {}

class VisualIdentificationInitial extends VisualIdentificationState {}

class VisualIdentificationLoaded extends VisualIdentificationState {
  final List<VisualObject> objects;
  VisualIdentificationLoaded(this.objects);
}

class VisualIdentificationCubit extends Cubit<VisualIdentificationState> {
  static final DebugCapturingLogger _logger = DebugCapturingLogger();
  static const MethodChannel _channel =
      MethodChannel('live_captions_xr/visual_object_methods');
  final HybridLocalizationEngine hybridLocalizationEngine;
  bool _isActive = false;

  VisualIdentificationCubit({required this.hybridLocalizationEngine})
      : super(VisualIdentificationInitial());

  bool get isActive => _isActive;

  Future<void> start() async {
    if (_isActive) return;
    _logger.i('👁️ Starting Visual Identification...');
    _channel.setMethodCallHandler(_handleMethodCall);
    _isActive = true;
    _logger.i('✅ Visual Identification started.');
  }

  Future<void> stop() async {
    if (!_isActive) return;
    _logger.i('👁️ Stopping Visual Identification...');
    _channel.setMethodCallHandler(null);
    _isActive = false;
    _logger.i('✅ Visual Identification stopped.');
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onVisualObjectDetected') {
      final args = Map<String, dynamic>.from(call.arguments);
      final bbox = args['boundingBox'] as List<dynamic>;
      final worldTransform = (args['worldTransform'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList();
      final obj = VisualObject(
        label: args['label'] as String,
        confidence: (args['confidence'] as num).toDouble(),
        boundingBox: Rect.fromLTRB(
          (bbox[0] as num).toDouble(),
          (bbox[1] as num).toDouble(),
          (bbox[2] as num).toDouble(),
          (bbox[3] as num).toDouble(),
        ),
        worldTransform: worldTransform,
      );
      detectObjects([obj]);
    }
  }

  void detectObjects(List<VisualObject> objects) {
    if (!_isActive) return;
    emit(VisualIdentificationLoaded(objects));
    // AUTOMATED: Update hybrid localization engine after every visual detection
    for (final obj in objects) {
      if (obj.worldTransform != null && obj.worldTransform!.length == 16) {
        hybridLocalizationEngine.updateWithVisualMeasurement(
          transform: obj.worldTransform!,
          confidence: obj.confidence,
        );
      }
    }
  }
}