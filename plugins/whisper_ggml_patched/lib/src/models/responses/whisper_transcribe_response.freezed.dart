// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'whisper_transcribe_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WhisperTranscribeResponse _$WhisperTranscribeResponseFromJson(
    Map<String, dynamic> json) {
  return _WhisperTranscribeResponse.fromJson(json);
}

/// @nodoc
mixin _$WhisperTranscribeResponse {
  @JsonKey(name: '@type')
  String get type => throw _privateConstructorUsedError;
  String get text => throw _privateConstructorUsedError;
  @JsonKey(name: 'segments')
  List<WhisperTranscribeSegment>? get segments =>
      throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WhisperTranscribeResponseCopyWith<WhisperTranscribeResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WhisperTranscribeResponseCopyWith<$Res> {
  factory $WhisperTranscribeResponseCopyWith(WhisperTranscribeResponse value,
          $Res Function(WhisperTranscribeResponse) then) =
      _$WhisperTranscribeResponseCopyWithImpl<$Res, WhisperTranscribeResponse>;
  @useResult
  $Res call(
      {@JsonKey(name: '@type') String type,
      String text,
      @JsonKey(name: 'segments') List<WhisperTranscribeSegment>? segments});
}

/// @nodoc
class _$WhisperTranscribeResponseCopyWithImpl<$Res,
        $Val extends WhisperTranscribeResponse>
    implements $WhisperTranscribeResponseCopyWith<$Res> {
  _$WhisperTranscribeResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? text = null,
    Object? segments = freezed,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      segments: freezed == segments
          ? _value.segments
          : segments // ignore: cast_nullable_to_non_nullable
              as List<WhisperTranscribeSegment>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WhisperTranscribeResponseImplCopyWith<$Res>
    implements $WhisperTranscribeResponseCopyWith<$Res> {
  factory _$$WhisperTranscribeResponseImplCopyWith(
          _$WhisperTranscribeResponseImpl value,
          $Res Function(_$WhisperTranscribeResponseImpl) then) =
      __$$WhisperTranscribeResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: '@type') String type,
      String text,
      @JsonKey(name: 'segments') List<WhisperTranscribeSegment>? segments});
}

/// @nodoc
class __$$WhisperTranscribeResponseImplCopyWithImpl<$Res>
    extends _$WhisperTranscribeResponseCopyWithImpl<$Res,
        _$WhisperTranscribeResponseImpl>
    implements _$$WhisperTranscribeResponseImplCopyWith<$Res> {
  __$$WhisperTranscribeResponseImplCopyWithImpl(
      _$WhisperTranscribeResponseImpl _value,
      $Res Function(_$WhisperTranscribeResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? text = null,
    Object? segments = freezed,
  }) {
    return _then(_$WhisperTranscribeResponseImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      segments: freezed == segments
          ? _value._segments
          : segments // ignore: cast_nullable_to_non_nullable
              as List<WhisperTranscribeSegment>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WhisperTranscribeResponseImpl extends _WhisperTranscribeResponse {
  const _$WhisperTranscribeResponseImpl(
      {@JsonKey(name: '@type') required this.type,
      required this.text,
      @JsonKey(name: 'segments')
      required final List<WhisperTranscribeSegment>? segments})
      : _segments = segments,
        super._();

  factory _$WhisperTranscribeResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$WhisperTranscribeResponseImplFromJson(json);

  @override
  @JsonKey(name: '@type')
  final String type;
  @override
  final String text;
  final List<WhisperTranscribeSegment>? _segments;
  @override
  @JsonKey(name: 'segments')
  List<WhisperTranscribeSegment>? get segments {
    final value = _segments;
    if (value == null) return null;
    if (_segments is EqualUnmodifiableListView) return _segments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'WhisperTranscribeResponse(type: $type, text: $text, segments: $segments)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WhisperTranscribeResponseImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.text, text) || other.text == text) &&
            const DeepCollectionEquality().equals(other._segments, _segments));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, type, text, const DeepCollectionEquality().hash(_segments));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WhisperTranscribeResponseImplCopyWith<_$WhisperTranscribeResponseImpl>
      get copyWith => __$$WhisperTranscribeResponseImplCopyWithImpl<
          _$WhisperTranscribeResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WhisperTranscribeResponseImplToJson(
      this,
    );
  }
}

abstract class _WhisperTranscribeResponse extends WhisperTranscribeResponse {
  const factory _WhisperTranscribeResponse(
          {@JsonKey(name: '@type') required final String type,
          required final String text,
          @JsonKey(name: 'segments')
          required final List<WhisperTranscribeSegment>? segments}) =
      _$WhisperTranscribeResponseImpl;
  const _WhisperTranscribeResponse._() : super._();

  factory _WhisperTranscribeResponse.fromJson(Map<String, dynamic> json) =
      _$WhisperTranscribeResponseImpl.fromJson;

  @override
  @JsonKey(name: '@type')
  String get type;
  @override
  String get text;
  @override
  @JsonKey(name: 'segments')
  List<WhisperTranscribeSegment>? get segments;
  @override
  @JsonKey(ignore: true)
  _$$WhisperTranscribeResponseImplCopyWith<_$WhisperTranscribeResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}
