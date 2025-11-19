import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/native_engine_event.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/services/native_caption_engine_bridge.dart';
import 'native_engine_state.dart';

class NativeEngineCubit extends Cubit<NativeEngineState> {
  NativeEngineCubit(this._bridge)
      : super(_bridge.isSupported
            ? const NativeEngineState(status: NativeEngineStatus.idle)
            : const NativeEngineState.unsupported());

  final NativeCaptionEngineBridge _bridge;
  final AppLogger _logger = AppLogger.instance;
  StreamSubscription<NativeEngineEvent>? _subscription;

  Future<void> ensureStarted() async {
    if (!_bridge.isSupported) {
      emit(const NativeEngineState.unsupported());
      return;
    }
    if (state.status == NativeEngineStatus.streaming ||
        state.status == NativeEngineStatus.starting) {
      return;
    }
    emit(state.copyWith(status: NativeEngineStatus.starting));
    try {
      await _bridge.ensureStarted();
      _listenToEvents();
      emit(state.copyWith(
          status: NativeEngineStatus.streaming, errorMessage: null));
    } catch (e, stackTrace) {
      _logger.e('Failed to start native caption engine bridge',
          category: LogCategory.system, error: e, stackTrace: stackTrace);
      emit(state.copyWith(
        status: NativeEngineStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _listenToEvents() {
    _subscription ??= _bridge.events.listen((event) {
      if (event is NativeSpeakerUpdateEvent) {
        final updatedSpeakers =
            Map<String, NativeSpeakerUpdateEvent>.from(state.speakers)
              ..[event.speakerId] = event;
        emit(state.copyWith(
          status: NativeEngineStatus.streaming,
          speakers: updatedSpeakers,
        ));
      } else if (event is NativeCaptionUpdateEvent) {
        emit(state.copyWith(
          status: NativeEngineStatus.streaming,
          lastCaption: event,
        ));
      }
    }, onError: (error, stackTrace) {
      _logger.e('Native engine stream error',
          category: LogCategory.system, error: error, stackTrace: stackTrace);
      emit(state.copyWith(
        status: NativeEngineStatus.error,
        errorMessage: error.toString(),
      ));
    });
  }

  Future<void> stopEngine() async {
    await _subscription?.cancel();
    _subscription = null;
    await _bridge.stop();
    if (_bridge.isSupported) {
      emit(const NativeEngineState(status: NativeEngineStatus.idle));
    } else {
      emit(const NativeEngineState.unsupported());
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
