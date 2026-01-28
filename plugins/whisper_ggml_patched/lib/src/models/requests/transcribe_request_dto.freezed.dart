// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transcribe_request_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TranscribeRequestDto _$TranscribeRequestDtoFromJson(Map<String, dynamic> json) {
  return _TranscribeRequestDto.fromJson(json);
}

/// @nodoc
mixin _$TranscribeRequestDto {
  String get audio => throw _privateConstructorUsedError;
  String get model => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_translate')
  bool get isTranslate => throw _privateConstructorUsedError;
  int get threads => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_verbose')
  bool get isVerbose => throw _privateConstructorUsedError;
  String get language => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_special_tokens')
  bool get isSpecialTokens => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_no_timestamps')
  bool get isNoTimestamps => throw _privateConstructorUsedError;
  @JsonKey(name: 'n_processors')
  int get nProcessors => throw _privateConstructorUsedError;
  @JsonKey(name: 'split_on_word')
  bool get splitOnWord => throw _privateConstructorUsedError;
  @JsonKey(name: 'no_fallback')
  bool get noFallback => throw _privateConstructorUsedError;
  bool get diarize => throw _privateConstructorUsedError;
  @JsonKey(name: 'speed_up')
  bool get speedUp => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TranscribeRequestDtoCopyWith<TranscribeRequestDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TranscribeRequestDtoCopyWith<$Res> {
  factory $TranscribeRequestDtoCopyWith(TranscribeRequestDto value,
          $Res Function(TranscribeRequestDto) then) =
      _$TranscribeRequestDtoCopyWithImpl<$Res, TranscribeRequestDto>;
  @useResult
  $Res call(
      {String audio,
      String model,
      @JsonKey(name: 'is_translate') bool isTranslate,
      int threads,
      @JsonKey(name: 'is_verbose') bool isVerbose,
      String language,
      @JsonKey(name: 'is_special_tokens') bool isSpecialTokens,
      @JsonKey(name: 'is_no_timestamps') bool isNoTimestamps,
      @JsonKey(name: 'n_processors') int nProcessors,
      @JsonKey(name: 'split_on_word') bool splitOnWord,
      @JsonKey(name: 'no_fallback') bool noFallback,
      bool diarize,
      @JsonKey(name: 'speed_up') bool speedUp});
}

/// @nodoc
class _$TranscribeRequestDtoCopyWithImpl<$Res,
        $Val extends TranscribeRequestDto>
    implements $TranscribeRequestDtoCopyWith<$Res> {
  _$TranscribeRequestDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? audio = null,
    Object? model = null,
    Object? isTranslate = null,
    Object? threads = null,
    Object? isVerbose = null,
    Object? language = null,
    Object? isSpecialTokens = null,
    Object? isNoTimestamps = null,
    Object? nProcessors = null,
    Object? splitOnWord = null,
    Object? noFallback = null,
    Object? diarize = null,
    Object? speedUp = null,
  }) {
    return _then(_value.copyWith(
      audio: null == audio
          ? _value.audio
          : audio // ignore: cast_nullable_to_non_nullable
              as String,
      model: null == model
          ? _value.model
          : model // ignore: cast_nullable_to_non_nullable
              as String,
      isTranslate: null == isTranslate
          ? _value.isTranslate
          : isTranslate // ignore: cast_nullable_to_non_nullable
              as bool,
      threads: null == threads
          ? _value.threads
          : threads // ignore: cast_nullable_to_non_nullable
              as int,
      isVerbose: null == isVerbose
          ? _value.isVerbose
          : isVerbose // ignore: cast_nullable_to_non_nullable
              as bool,
      language: null == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      isSpecialTokens: null == isSpecialTokens
          ? _value.isSpecialTokens
          : isSpecialTokens // ignore: cast_nullable_to_non_nullable
              as bool,
      isNoTimestamps: null == isNoTimestamps
          ? _value.isNoTimestamps
          : isNoTimestamps // ignore: cast_nullable_to_non_nullable
              as bool,
      nProcessors: null == nProcessors
          ? _value.nProcessors
          : nProcessors // ignore: cast_nullable_to_non_nullable
              as int,
      splitOnWord: null == splitOnWord
          ? _value.splitOnWord
          : splitOnWord // ignore: cast_nullable_to_non_nullable
              as bool,
      noFallback: null == noFallback
          ? _value.noFallback
          : noFallback // ignore: cast_nullable_to_non_nullable
              as bool,
      diarize: null == diarize
          ? _value.diarize
          : diarize // ignore: cast_nullable_to_non_nullable
              as bool,
      speedUp: null == speedUp
          ? _value.speedUp
          : speedUp // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TranscribeRequestDtoImplCopyWith<$Res>
    implements $TranscribeRequestDtoCopyWith<$Res> {
  factory _$$TranscribeRequestDtoImplCopyWith(_$TranscribeRequestDtoImpl value,
          $Res Function(_$TranscribeRequestDtoImpl) then) =
      __$$TranscribeRequestDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String audio,
      String model,
      @JsonKey(name: 'is_translate') bool isTranslate,
      int threads,
      @JsonKey(name: 'is_verbose') bool isVerbose,
      String language,
      @JsonKey(name: 'is_special_tokens') bool isSpecialTokens,
      @JsonKey(name: 'is_no_timestamps') bool isNoTimestamps,
      @JsonKey(name: 'n_processors') int nProcessors,
      @JsonKey(name: 'split_on_word') bool splitOnWord,
      @JsonKey(name: 'no_fallback') bool noFallback,
      bool diarize,
      @JsonKey(name: 'speed_up') bool speedUp});
}

/// @nodoc
class __$$TranscribeRequestDtoImplCopyWithImpl<$Res>
    extends _$TranscribeRequestDtoCopyWithImpl<$Res, _$TranscribeRequestDtoImpl>
    implements _$$TranscribeRequestDtoImplCopyWith<$Res> {
  __$$TranscribeRequestDtoImplCopyWithImpl(_$TranscribeRequestDtoImpl _value,
      $Res Function(_$TranscribeRequestDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? audio = null,
    Object? model = null,
    Object? isTranslate = null,
    Object? threads = null,
    Object? isVerbose = null,
    Object? language = null,
    Object? isSpecialTokens = null,
    Object? isNoTimestamps = null,
    Object? nProcessors = null,
    Object? splitOnWord = null,
    Object? noFallback = null,
    Object? diarize = null,
    Object? speedUp = null,
  }) {
    return _then(_$TranscribeRequestDtoImpl(
      audio: null == audio
          ? _value.audio
          : audio // ignore: cast_nullable_to_non_nullable
              as String,
      model: null == model
          ? _value.model
          : model // ignore: cast_nullable_to_non_nullable
              as String,
      isTranslate: null == isTranslate
          ? _value.isTranslate
          : isTranslate // ignore: cast_nullable_to_non_nullable
              as bool,
      threads: null == threads
          ? _value.threads
          : threads // ignore: cast_nullable_to_non_nullable
              as int,
      isVerbose: null == isVerbose
          ? _value.isVerbose
          : isVerbose // ignore: cast_nullable_to_non_nullable
              as bool,
      language: null == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      isSpecialTokens: null == isSpecialTokens
          ? _value.isSpecialTokens
          : isSpecialTokens // ignore: cast_nullable_to_non_nullable
              as bool,
      isNoTimestamps: null == isNoTimestamps
          ? _value.isNoTimestamps
          : isNoTimestamps // ignore: cast_nullable_to_non_nullable
              as bool,
      nProcessors: null == nProcessors
          ? _value.nProcessors
          : nProcessors // ignore: cast_nullable_to_non_nullable
              as int,
      splitOnWord: null == splitOnWord
          ? _value.splitOnWord
          : splitOnWord // ignore: cast_nullable_to_non_nullable
              as bool,
      noFallback: null == noFallback
          ? _value.noFallback
          : noFallback // ignore: cast_nullable_to_non_nullable
              as bool,
      diarize: null == diarize
          ? _value.diarize
          : diarize // ignore: cast_nullable_to_non_nullable
              as bool,
      speedUp: null == speedUp
          ? _value.speedUp
          : speedUp // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TranscribeRequestDtoImpl extends _TranscribeRequestDto {
  const _$TranscribeRequestDtoImpl(
      {required this.audio,
      required this.model,
      @JsonKey(name: 'is_translate') required this.isTranslate,
      required this.threads,
      @JsonKey(name: 'is_verbose') required this.isVerbose,
      required this.language,
      @JsonKey(name: 'is_special_tokens') required this.isSpecialTokens,
      @JsonKey(name: 'is_no_timestamps') required this.isNoTimestamps,
      @JsonKey(name: 'n_processors') required this.nProcessors,
      @JsonKey(name: 'split_on_word') required this.splitOnWord,
      @JsonKey(name: 'no_fallback') required this.noFallback,
      required this.diarize,
      @JsonKey(name: 'speed_up') required this.speedUp})
      : super._();

  factory _$TranscribeRequestDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$TranscribeRequestDtoImplFromJson(json);

  @override
  final String audio;
  @override
  final String model;
  @override
  @JsonKey(name: 'is_translate')
  final bool isTranslate;
  @override
  final int threads;
  @override
  @JsonKey(name: 'is_verbose')
  final bool isVerbose;
  @override
  final String language;
  @override
  @JsonKey(name: 'is_special_tokens')
  final bool isSpecialTokens;
  @override
  @JsonKey(name: 'is_no_timestamps')
  final bool isNoTimestamps;
  @override
  @JsonKey(name: 'n_processors')
  final int nProcessors;
  @override
  @JsonKey(name: 'split_on_word')
  final bool splitOnWord;
  @override
  @JsonKey(name: 'no_fallback')
  final bool noFallback;
  @override
  final bool diarize;
  @override
  @JsonKey(name: 'speed_up')
  final bool speedUp;

  @override
  String toString() {
    return 'TranscribeRequestDto(audio: $audio, model: $model, isTranslate: $isTranslate, threads: $threads, isVerbose: $isVerbose, language: $language, isSpecialTokens: $isSpecialTokens, isNoTimestamps: $isNoTimestamps, nProcessors: $nProcessors, splitOnWord: $splitOnWord, noFallback: $noFallback, diarize: $diarize, speedUp: $speedUp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TranscribeRequestDtoImpl &&
            (identical(other.audio, audio) || other.audio == audio) &&
            (identical(other.model, model) || other.model == model) &&
            (identical(other.isTranslate, isTranslate) ||
                other.isTranslate == isTranslate) &&
            (identical(other.threads, threads) || other.threads == threads) &&
            (identical(other.isVerbose, isVerbose) ||
                other.isVerbose == isVerbose) &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.isSpecialTokens, isSpecialTokens) ||
                other.isSpecialTokens == isSpecialTokens) &&
            (identical(other.isNoTimestamps, isNoTimestamps) ||
                other.isNoTimestamps == isNoTimestamps) &&
            (identical(other.nProcessors, nProcessors) ||
                other.nProcessors == nProcessors) &&
            (identical(other.splitOnWord, splitOnWord) ||
                other.splitOnWord == splitOnWord) &&
            (identical(other.noFallback, noFallback) ||
                other.noFallback == noFallback) &&
            (identical(other.diarize, diarize) || other.diarize == diarize) &&
            (identical(other.speedUp, speedUp) || other.speedUp == speedUp));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      audio,
      model,
      isTranslate,
      threads,
      isVerbose,
      language,
      isSpecialTokens,
      isNoTimestamps,
      nProcessors,
      splitOnWord,
      noFallback,
      diarize,
      speedUp);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TranscribeRequestDtoImplCopyWith<_$TranscribeRequestDtoImpl>
      get copyWith =>
          __$$TranscribeRequestDtoImplCopyWithImpl<_$TranscribeRequestDtoImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TranscribeRequestDtoImplToJson(
      this,
    );
  }
}

abstract class _TranscribeRequestDto extends TranscribeRequestDto {
  const factory _TranscribeRequestDto(
      {required final String audio,
      required final String model,
      @JsonKey(name: 'is_translate') required final bool isTranslate,
      required final int threads,
      @JsonKey(name: 'is_verbose') required final bool isVerbose,
      required final String language,
      @JsonKey(name: 'is_special_tokens') required final bool isSpecialTokens,
      @JsonKey(name: 'is_no_timestamps') required final bool isNoTimestamps,
      @JsonKey(name: 'n_processors') required final int nProcessors,
      @JsonKey(name: 'split_on_word') required final bool splitOnWord,
      @JsonKey(name: 'no_fallback') required final bool noFallback,
      required final bool diarize,
      @JsonKey(name: 'speed_up')
      required final bool speedUp}) = _$TranscribeRequestDtoImpl;
  const _TranscribeRequestDto._() : super._();

  factory _TranscribeRequestDto.fromJson(Map<String, dynamic> json) =
      _$TranscribeRequestDtoImpl.fromJson;

  @override
  String get audio;
  @override
  String get model;
  @override
  @JsonKey(name: 'is_translate')
  bool get isTranslate;
  @override
  int get threads;
  @override
  @JsonKey(name: 'is_verbose')
  bool get isVerbose;
  @override
  String get language;
  @override
  @JsonKey(name: 'is_special_tokens')
  bool get isSpecialTokens;
  @override
  @JsonKey(name: 'is_no_timestamps')
  bool get isNoTimestamps;
  @override
  @JsonKey(name: 'n_processors')
  int get nProcessors;
  @override
  @JsonKey(name: 'split_on_word')
  bool get splitOnWord;
  @override
  @JsonKey(name: 'no_fallback')
  bool get noFallback;
  @override
  bool get diarize;
  @override
  @JsonKey(name: 'speed_up')
  bool get speedUp;
  @override
  @JsonKey(ignore: true)
  _$$TranscribeRequestDtoImplCopyWith<_$TranscribeRequestDtoImpl>
      get copyWith => throw _privateConstructorUsedError;
}
