import 'package:equatable/equatable.dart';

enum NativeEngineEventType { speaker, caption }

abstract class NativeEngineEvent extends Equatable {
  const NativeEngineEvent({
    required this.timestampUs,
    required this.type,
  });

  final int? timestampUs;
  final NativeEngineEventType type;

  factory NativeEngineEvent.fromMap(Map<dynamic, dynamic> payload) {
    final type = payload['type'] as String? ?? '';
    switch (type) {
      case 'speaker':
        return NativeSpeakerUpdateEvent(
          speakerId: payload['speakerId'] as String? ?? 'unknown',
          text: payload['text'] as String? ?? '',
          isSpeaking: payload['isSpeaking'] as bool? ?? true,
          timestampUs: (payload['timestampUs'] as num?)?.toInt(),
          direction: payload['direction'] is Map
              ? NativeSpeakerDirection.fromMap(
                  payload['direction'] as Map<dynamic, dynamic>,
                )
              : null,
        );
      case 'caption':
        return NativeCaptionUpdateEvent(
          speakerId: payload['speakerId'] as String?,
          text: payload['text'] as String? ?? '',
          isFinal: payload['isFinal'] as bool? ?? false,
          timestampUs: (payload['timestampUs'] as num?)?.toInt(),
        );
      default:
        return NativeCaptionUpdateEvent(
          text: payload['text']?.toString() ?? '',
          timestampUs: (payload['timestampUs'] as num?)?.toInt(),
          isFinal: false,
          speakerId: payload['speakerId'] as String?,
        );
    }
  }

  DateTime? get timestamp => timestampUs == null
      ? null
      : DateTime.fromMicrosecondsSinceEpoch(timestampUs!);

  @override
  List<Object?> get props => [timestampUs, type];
}

class NativeSpeakerUpdateEvent extends NativeEngineEvent {
  const NativeSpeakerUpdateEvent({
    required this.speakerId,
    required this.text,
    required this.isSpeaking,
    required int? timestampUs,
    this.direction,
  }) : super(
          timestampUs: timestampUs,
          type: NativeEngineEventType.speaker,
        );

  final String speakerId;
  final String text;
  final bool isSpeaking;
  final NativeSpeakerDirection? direction;

  @override
  List<Object?> get props =>
      [...super.props, speakerId, text, isSpeaking, direction];
}

class NativeCaptionUpdateEvent extends NativeEngineEvent {
  const NativeCaptionUpdateEvent({
    required this.text,
    required this.isFinal,
    required int? timestampUs,
    this.speakerId,
  }) : super(
          timestampUs: timestampUs,
          type: NativeEngineEventType.caption,
        );

  final String? speakerId;
  final String text;
  final bool isFinal;

  @override
  List<Object?> get props => [...super.props, speakerId, text, isFinal];
}

class NativeSpeakerDirection extends Equatable {
  const NativeSpeakerDirection({
    required this.azimuthDeg,
    required this.elevationDeg,
    required this.confidence,
  });

  factory NativeSpeakerDirection.fromMap(Map<dynamic, dynamic> map) {
    double _toDouble(dynamic value) => value is num ? value.toDouble() : 0.0;

    return NativeSpeakerDirection(
      azimuthDeg: _toDouble(map['azimuth']),
      elevationDeg: _toDouble(map['elevation']),
      confidence: _toDouble(map['confidence']),
    );
  }

  final double azimuthDeg;
  final double elevationDeg;
  final double confidence;

  @override
  List<Object?> get props => [azimuthDeg, elevationDeg, confidence];
}
