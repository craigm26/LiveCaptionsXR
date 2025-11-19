import 'package:equatable/equatable.dart';
import '../../../core/models/native_engine_event.dart';

enum NativeEngineStatus {
  unsupported,
  idle,
  starting,
  streaming,
  error,
}

class NativeEngineState extends Equatable {
  const NativeEngineState({
    required this.status,
    this.lastCaption,
    this.speakers = const <String, NativeSpeakerUpdateEvent>{},
    this.errorMessage,
  });

  const NativeEngineState.unsupported()
      : this(status: NativeEngineStatus.unsupported);

  final NativeEngineStatus status;
  final NativeCaptionUpdateEvent? lastCaption;
  final Map<String, NativeSpeakerUpdateEvent> speakers;
  final String? errorMessage;

  bool get isRunning =>
      status == NativeEngineStatus.streaming ||
      status == NativeEngineStatus.starting;
  bool get isSupported => status != NativeEngineStatus.unsupported;

  NativeEngineState copyWith({
    NativeEngineStatus? status,
    NativeCaptionUpdateEvent? lastCaption,
    Map<String, NativeSpeakerUpdateEvent>? speakers,
    String? errorMessage,
  }) {
    return NativeEngineState(
      status: status ?? this.status,
      lastCaption: lastCaption ?? this.lastCaption,
      speakers: speakers ?? this.speakers,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, lastCaption, speakers, errorMessage];
}
