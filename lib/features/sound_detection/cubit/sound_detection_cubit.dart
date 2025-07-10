import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/sound_event.dart';
import '../../../core/services/debug_capturing_logger.dart';

abstract class SoundDetectionState {}

class SoundDetectionInitial extends SoundDetectionState {}
class SoundDetectionLoaded extends SoundDetectionState {
  final List<SoundEvent> events;
  SoundDetectionLoaded(this.events);
}

class SoundDetectionCubit extends Cubit<SoundDetectionState> {
  static final DebugCapturingLogger _logger = DebugCapturingLogger();
  bool _isActive = false;

  SoundDetectionCubit() : super(SoundDetectionInitial());

  bool get isActive => _isActive;

  Future<void> start() async {
    if (_isActive) return;
    _logger.i('🔊 Starting Sound Detection...');
    // In a real app, you would initialize the native sound detection here.
    _isActive = true;
    _logger.i('✅ Sound Detection started.');
  }

  Future<void> stop() async {
    if (!_isActive) return;
    _logger.i('🔊 Stopping Sound Detection...');
    // In a real app, you would stop the native sound detection here.
    _isActive = false;
    _logger.i('✅ Sound Detection stopped.');
  }

  void detectSound(SoundEvent event) {
    if (!_isActive) return;
    final current = state is SoundDetectionLoaded
        ? (state as SoundDetectionLoaded).events
        : <SoundEvent>[];
    emit(SoundDetectionLoaded([...current, event]));
  }
}