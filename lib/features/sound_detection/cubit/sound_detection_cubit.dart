// Placeholder for SoundDetectionCubit
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/sound_event.dart';

abstract class SoundDetectionState {}

class SoundDetectionInitial extends SoundDetectionState {}
class SoundDetectionLoaded extends SoundDetectionState {
  final List<SoundEvent> events;
  SoundDetectionLoaded(this.events);
}

class SoundDetectionCubit extends Cubit<SoundDetectionState> {
  SoundDetectionCubit() : super(SoundDetectionInitial());

  void detectSound(SoundEvent event) {
    final current = state is SoundDetectionLoaded
        ? (state as SoundDetectionLoaded).events
        : <SoundEvent>[];
    emit(SoundDetectionLoaded([...current, event]));
  }
} 