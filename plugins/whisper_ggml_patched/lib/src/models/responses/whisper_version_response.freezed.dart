// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'whisper_version_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WhisperVersionResponse _$WhisperVersionResponseFromJson(
    Map<String, dynamic> json) {
  return _WhisperVersionResponse.fromJson(json);
}

/// @nodoc
mixin _$WhisperVersionResponse {
  @JsonKey(name: '@type')
  String get type => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WhisperVersionResponseCopyWith<WhisperVersionResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WhisperVersionResponseCopyWith<$Res> {
  factory $WhisperVersionResponseCopyWith(WhisperVersionResponse value,
          $Res Function(WhisperVersionResponse) then) =
      _$WhisperVersionResponseCopyWithImpl<$Res, WhisperVersionResponse>;
  @useResult
  $Res call({@JsonKey(name: '@type') String type, String message});
}

/// @nodoc
class _$WhisperVersionResponseCopyWithImpl<$Res,
        $Val extends WhisperVersionResponse>
    implements $WhisperVersionResponseCopyWith<$Res> {
  _$WhisperVersionResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? message = null,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WhisperVersionResponseImplCopyWith<$Res>
    implements $WhisperVersionResponseCopyWith<$Res> {
  factory _$$WhisperVersionResponseImplCopyWith(
          _$WhisperVersionResponseImpl value,
          $Res Function(_$WhisperVersionResponseImpl) then) =
      __$$WhisperVersionResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: '@type') String type, String message});
}

/// @nodoc
class __$$WhisperVersionResponseImplCopyWithImpl<$Res>
    extends _$WhisperVersionResponseCopyWithImpl<$Res,
        _$WhisperVersionResponseImpl>
    implements _$$WhisperVersionResponseImplCopyWith<$Res> {
  __$$WhisperVersionResponseImplCopyWithImpl(
      _$WhisperVersionResponseImpl _value,
      $Res Function(_$WhisperVersionResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? message = null,
  }) {
    return _then(_$WhisperVersionResponseImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WhisperVersionResponseImpl extends _WhisperVersionResponse {
  const _$WhisperVersionResponseImpl(
      {@JsonKey(name: '@type') required this.type, required this.message})
      : super._();

  factory _$WhisperVersionResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$WhisperVersionResponseImplFromJson(json);

  @override
  @JsonKey(name: '@type')
  final String type;
  @override
  final String message;

  @override
  String toString() {
    return 'WhisperVersionResponse(type: $type, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WhisperVersionResponseImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.message, message) || other.message == message));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, type, message);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WhisperVersionResponseImplCopyWith<_$WhisperVersionResponseImpl>
      get copyWith => __$$WhisperVersionResponseImplCopyWithImpl<
          _$WhisperVersionResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WhisperVersionResponseImplToJson(
      this,
    );
  }
}

abstract class _WhisperVersionResponse extends WhisperVersionResponse {
  const factory _WhisperVersionResponse(
      {@JsonKey(name: '@type') required final String type,
      required final String message}) = _$WhisperVersionResponseImpl;
  const _WhisperVersionResponse._() : super._();

  factory _WhisperVersionResponse.fromJson(Map<String, dynamic> json) =
      _$WhisperVersionResponseImpl.fromJson;

  @override
  @JsonKey(name: '@type')
  String get type;
  @override
  String get message;
  @override
  @JsonKey(ignore: true)
  _$$WhisperVersionResponseImplCopyWith<_$WhisperVersionResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}
