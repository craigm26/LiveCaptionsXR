// Placeholder for VisualIdentificationCubit
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import '../../../core/models/visual_object.dart';
import '../../home/cubit/home_cubit.dart';

abstract class VisualIdentificationState {}

class VisualIdentificationInitial extends VisualIdentificationState {}
class VisualIdentificationLoaded extends VisualIdentificationState {
  final List<VisualObject> objects;
  VisualIdentificationLoaded(this.objects);
}

class VisualIdentificationCubit extends Cubit<VisualIdentificationState> {
  VisualIdentificationCubit() : super(VisualIdentificationInitial()) {
    // Register native visual object handler
    const MethodChannel _channel = MethodChannel('live_captions_xr/visual_object_methods');
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onVisualObjectDetected') {
        final args = Map<String, dynamic>.from(call.arguments);
        final bbox = args['boundingBox'] as List<dynamic>;
        final worldTransform = (args['worldTransform'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList();
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
    });
  }

  void detectObjects(List<VisualObject> objects) {
    emit(VisualIdentificationLoaded(objects));
    // AUTOMATED: Update hybrid localization engine after every visual detection
    final homeCubit = HomeCubit(); // In production, use Provider/Bloc context
    for (final obj in objects) {
      if (obj.worldTransform != null && obj.worldTransform!.length == 16) {
        homeCubit.updateWithVisualMeasurement(
          transform: obj.worldTransform!,
          confidence: obj.confidence,
        );
      }
    }
  }
} 