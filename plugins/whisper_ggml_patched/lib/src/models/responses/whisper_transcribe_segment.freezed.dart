// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'whisper_transcribe_segment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WhisperTranscribeSegment _$WhisperTranscribeSegmentFromJson(
    Map<String, dynamic> json) {
  return _WhisperTranscribeSegment.fromJson(json);
}

/// @nodoc
mixin _$WhisperTranscribeSegment {
  @JsonKey(name: 'from_ts', fromJson: WhisperTranscribeSegment._durationFromInt)
  Duration get fromTs => throw _privateConstructorUsedError;
  @JsonKey(name: 'to_ts', fromJson: WhisperTranscribeSegment._durationFromInt)
  Duration get toTs => throw _privateConstructorUsedError;
  String get text => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WhisperTranscribeSegmentCopyWith<WhisperTranscribeSegment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WhisperTranscribeSegmentCopyWith<$Res> {
  factory $WhisperTranscribeSegmentCopyWith(WhisperTranscribeSegment value,
          $Res Function(WhisperTranscribeSegment) then) =
      _$WhisperTranscribeSegmentCopyWithImpl<$Res, WhisperTranscribeSegment>;
  @useResult
  $Res call(
      {@JsonKey(
          name: 'from_ts', fromJson: WhisperTranscribeSegment._durationFromInt)
      Duration fromTs,
      @JsonKey(
          name: 'to_ts', fromJson: WhisperTranscribeSegment._durationFromInt)
      Duration toTs,
      String text});
}

/// @nodoc
class _$WhisperTranscribeSegmentCopyWithImpl<$Res,
        $Val extends WhisperTranscribeSegment>
    implements $WhisperTranscribeSegmentCopyWith<$Res> {
  _$WhisperTranscribeSegmentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fromTs = null,
    Object? toTs = null,
    Object? text = null,
  }) {
    return _then(_value.copyWith(
      fromTs: null == fromTs
          ? _value.fromTs
          : fromTs // ignore: cast_nullable_to_non_nullable
              as Duration,
      toTs: null == toTs
          ? _value.toTs
          : toTs // ignore: cast_nullable_to_non_nullable
              as Duration,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WhisperTranscribeSegmentImplCopyWith<$Res>
    implements $WhisperTranscribeSegmentCopyWith<$Res> {
  factory _$$WhisperTranscribeSegmentImplCopyWith(
          _$WhisperTranscribeSegmentImpl value,
          $Res Function(_$WhisperTranscribeSegmentImpl) then) =
      __$$WhisperTranscribeSegmentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(
          name: 'from_ts', fromJson: WhisperTranscribeSegment._durationFromInt)
      Duration fromTs,
      @JsonKey(
          name: 'to_ts', fromJson: WhisperTranscribeSegment._durationFromInt)
      Duration toTs,
      String text});
}

/// @nodoc
class __$$WhisperTranscribeSegmentImplCopyWithImpl<$Res>
    extends _$WhisperTranscribeSegmentCopyWithImpl<$Res,
        _$WhisperTranscribeSegmentImpl>
    implements _$$WhisperTranscribeSegmentImplCopyWith<$Res> {
  __$$WhisperTranscribeSegmentImplCopyWithImpl(
      _$WhisperTranscribeSegmentImpl _value,
      $Res Function(_$WhisperTranscribeSegmentImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fromTs = null,
    Object? toTs = null,
    Object? text = null,
  }) {
    return _then(_$WhisperTranscribeSegmentImpl(
      fromTs: null == fromTs
          ? _value.fromTs
          : fromTs // ignore: cast_nullable_to_non_nullable
              as Duration,
      toTs: null == toTs
          ? _value.toTs
          : toTs // ignore: cast_nullable_to_non_nullable
              as Duration,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WhisperTranscribeSegmentImpl implements _WhisperTranscribeSegment {
  const _$WhisperTranscribeSegmentImpl(
      {@JsonKey(
          name: 'from_ts', fromJson: WhisperTranscribeSegment._durationFromInt)
      required this.fromTs,
      @JsonKey(
          name: 'to_ts', fromJson: WhisperTranscribeSegment._durationFromInt)
      required this.toTs,
      required this.text});

  factory _$WhisperTranscribeSegmentImpl.fromJson(Map<String, dynamic> json) =>
      _$$WhisperTranscribeSegmentImplFromJson(json);

  @override
  @JsonKey(name: 'from_ts', fromJson: WhisperTranscribeSegment._durationFromInt)
  final Duration fromTs;
  @override
  @JsonKey(name: 'to_ts', fromJson: WhisperTranscribeSegment._durationFromInt)
  final Duration toTs;
  @override
  final String text;

  @override
  String toString() {
    return 'WhisperTranscribeSegment(fromTs: $fromTs, toTs: $toTs, text: $text)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WhisperTranscribeSegmentImpl &&
            (identical(other.fromTs, fromTs) || other.fromTs == fromTs) &&
            (identical(other.toTs, toTs) || other.toTs == toTs) &&
            (identical(other.text, text) || other.text == text));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, fromTs, toTs, text);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WhisperTranscribeSegmentImplCopyWith<_$WhisperTranscribeSegmentImpl>
      get copyWith => __$$WhisperTranscribeSegmentImplCopyWithImpl<
          _$WhisperTranscribeSegmentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WhisperTranscribeSegmentImplToJson(
      this,
    );
  }
}

abstract class _WhisperTranscribeSegment implements WhisperTranscribeSegment {
  const factory _WhisperTranscribeSegment(
      {@JsonKey(
          name: 'from_ts', fromJson: WhisperTranscribeSegment._durationFromInt)
      required final Duration fromTs,
      @JsonKey(
          name: 'to_ts', fromJson: WhisperTranscribeSegment._durationFromInt)
      required final Duration toTs,
      required final String text}) = _$WhisperTranscribeSegmentImpl;

  factory _WhisperTranscribeSegment.fromJson(Map<String, dynamic> json) =
      _$WhisperTranscribeSegmentImpl.fromJson;

  @override
  @JsonKey(name: 'from_ts', fromJson: WhisperTranscribeSegment._durationFromInt)
  Duration get fromTs;
  @override
  @JsonKey(name: 'to_ts', fromJson: WhisperTranscribeSegment._durationFromInt)
  Duration get toTs;
  @override
  String get text;
  @override
  @JsonKey(ignore: true)
  _$$WhisperTranscribeSegmentImplCopyWith<_$WhisperTranscribeSegmentImpl>
      get copyWith => throw _privateConstructorUsedError;
}
