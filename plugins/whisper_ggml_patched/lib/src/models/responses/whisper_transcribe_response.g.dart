// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'whisper_transcribe_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WhisperTranscribeResponseImpl _$$WhisperTranscribeResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$WhisperTranscribeResponseImpl(
      type: json['@type'] as String,
      text: json['text'] as String,
      segments: (json['segments'] as List<dynamic>?)
          ?.map((e) =>
              WhisperTranscribeSegment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$WhisperTranscribeResponseImplToJson(
        _$WhisperTranscribeResponseImpl instance) =>
    <String, dynamic>{
      '@type': instance.type,
      'text': instance.text,
      'segments': instance.segments,
    };
