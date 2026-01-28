// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'whisper_transcribe_segment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WhisperTranscribeSegmentImpl _$$WhisperTranscribeSegmentImplFromJson(
        Map<String, dynamic> json) =>
    _$WhisperTranscribeSegmentImpl(
      fromTs: WhisperTranscribeSegment._durationFromInt(
          (json['from_ts'] as num).toInt()),
      toTs: WhisperTranscribeSegment._durationFromInt(
          (json['to_ts'] as num).toInt()),
      text: json['text'] as String,
    );

Map<String, dynamic> _$$WhisperTranscribeSegmentImplToJson(
        _$WhisperTranscribeSegmentImpl instance) =>
    <String, dynamic>{
      'from_ts': instance.fromTs.inMicroseconds,
      'to_ts': instance.toTs.inMicroseconds,
      'text': instance.text,
    };
