// Placeholder for VisualIdentificationCubit
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/visual_object.dart';

abstract class VisualIdentificationState {}

class VisualIdentificationInitial extends VisualIdentificationState {}
class VisualIdentificationLoaded extends VisualIdentificationState {
  final List<VisualObject> objects;
  VisualIdentificationLoaded(this.objects);
}

class VisualIdentificationCubit extends Cubit<VisualIdentificationState> {
  VisualIdentificationCubit() : super(VisualIdentificationInitial());

  void detectObjects(List<VisualObject> objects) {
    emit(VisualIdentificationLoaded(objects));
  }
} 