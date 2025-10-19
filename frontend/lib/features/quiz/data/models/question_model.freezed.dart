// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'question_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

QuestionModel _$QuestionModelFromJson(Map<String, dynamic> json) {
  return _QuestionModel.fromJson(json);
}

/// @nodoc
mixin _$QuestionModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'quiz_id')
  String get quizId => throw _privateConstructorUsedError;
  int get ordre => throw _privateConstructorUsedError;
  @JsonKey(name: 'type_question')
  String get typeQuestion => throw _privateConstructorUsedError;
  @JsonKey(name: 'question_data')
  Map<String, dynamic> get questionData => throw _privateConstructorUsedError;
  int get points => throw _privateConstructorUsedError;
  @JsonKey(name: 'temps_limite_sec')
  int? get tempsLimiteSec => throw _privateConstructorUsedError;
  String? get hint => throw _privateConstructorUsedError;
  String? get explanation => throw _privateConstructorUsedError;

  /// Serializes this QuestionModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of QuestionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QuestionModelCopyWith<QuestionModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuestionModelCopyWith<$Res> {
  factory $QuestionModelCopyWith(
          QuestionModel value, $Res Function(QuestionModel) then) =
      _$QuestionModelCopyWithImpl<$Res, QuestionModel>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'quiz_id') String quizId,
      int ordre,
      @JsonKey(name: 'type_question') String typeQuestion,
      @JsonKey(name: 'question_data') Map<String, dynamic> questionData,
      int points,
      @JsonKey(name: 'temps_limite_sec') int? tempsLimiteSec,
      String? hint,
      String? explanation});
}

/// @nodoc
class _$QuestionModelCopyWithImpl<$Res, $Val extends QuestionModel>
    implements $QuestionModelCopyWith<$Res> {
  _$QuestionModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QuestionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? quizId = null,
    Object? ordre = null,
    Object? typeQuestion = null,
    Object? questionData = null,
    Object? points = null,
    Object? tempsLimiteSec = freezed,
    Object? hint = freezed,
    Object? explanation = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      quizId: null == quizId
          ? _value.quizId
          : quizId // ignore: cast_nullable_to_non_nullable
              as String,
      ordre: null == ordre
          ? _value.ordre
          : ordre // ignore: cast_nullable_to_non_nullable
              as int,
      typeQuestion: null == typeQuestion
          ? _value.typeQuestion
          : typeQuestion // ignore: cast_nullable_to_non_nullable
              as String,
      questionData: null == questionData
          ? _value.questionData
          : questionData // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      points: null == points
          ? _value.points
          : points // ignore: cast_nullable_to_non_nullable
              as int,
      tempsLimiteSec: freezed == tempsLimiteSec
          ? _value.tempsLimiteSec
          : tempsLimiteSec // ignore: cast_nullable_to_non_nullable
              as int?,
      hint: freezed == hint
          ? _value.hint
          : hint // ignore: cast_nullable_to_non_nullable
              as String?,
      explanation: freezed == explanation
          ? _value.explanation
          : explanation // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QuestionModelImplCopyWith<$Res>
    implements $QuestionModelCopyWith<$Res> {
  factory _$$QuestionModelImplCopyWith(
          _$QuestionModelImpl value, $Res Function(_$QuestionModelImpl) then) =
      __$$QuestionModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'quiz_id') String quizId,
      int ordre,
      @JsonKey(name: 'type_question') String typeQuestion,
      @JsonKey(name: 'question_data') Map<String, dynamic> questionData,
      int points,
      @JsonKey(name: 'temps_limite_sec') int? tempsLimiteSec,
      String? hint,
      String? explanation});
}

/// @nodoc
class __$$QuestionModelImplCopyWithImpl<$Res>
    extends _$QuestionModelCopyWithImpl<$Res, _$QuestionModelImpl>
    implements _$$QuestionModelImplCopyWith<$Res> {
  __$$QuestionModelImplCopyWithImpl(
      _$QuestionModelImpl _value, $Res Function(_$QuestionModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of QuestionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? quizId = null,
    Object? ordre = null,
    Object? typeQuestion = null,
    Object? questionData = null,
    Object? points = null,
    Object? tempsLimiteSec = freezed,
    Object? hint = freezed,
    Object? explanation = freezed,
  }) {
    return _then(_$QuestionModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      quizId: null == quizId
          ? _value.quizId
          : quizId // ignore: cast_nullable_to_non_nullable
              as String,
      ordre: null == ordre
          ? _value.ordre
          : ordre // ignore: cast_nullable_to_non_nullable
              as int,
      typeQuestion: null == typeQuestion
          ? _value.typeQuestion
          : typeQuestion // ignore: cast_nullable_to_non_nullable
              as String,
      questionData: null == questionData
          ? _value._questionData
          : questionData // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      points: null == points
          ? _value.points
          : points // ignore: cast_nullable_to_non_nullable
              as int,
      tempsLimiteSec: freezed == tempsLimiteSec
          ? _value.tempsLimiteSec
          : tempsLimiteSec // ignore: cast_nullable_to_non_nullable
              as int?,
      hint: freezed == hint
          ? _value.hint
          : hint // ignore: cast_nullable_to_non_nullable
              as String?,
      explanation: freezed == explanation
          ? _value.explanation
          : explanation // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QuestionModelImpl implements _QuestionModel {
  const _$QuestionModelImpl(
      {required this.id,
      @JsonKey(name: 'quiz_id') required this.quizId,
      required this.ordre,
      @JsonKey(name: 'type_question') required this.typeQuestion,
      @JsonKey(name: 'question_data')
      required final Map<String, dynamic> questionData,
      required this.points,
      @JsonKey(name: 'temps_limite_sec') this.tempsLimiteSec,
      this.hint,
      this.explanation})
      : _questionData = questionData;

  factory _$QuestionModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuestionModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'quiz_id')
  final String quizId;
  @override
  final int ordre;
  @override
  @JsonKey(name: 'type_question')
  final String typeQuestion;
  final Map<String, dynamic> _questionData;
  @override
  @JsonKey(name: 'question_data')
  Map<String, dynamic> get questionData {
    if (_questionData is EqualUnmodifiableMapView) return _questionData;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_questionData);
  }

  @override
  final int points;
  @override
  @JsonKey(name: 'temps_limite_sec')
  final int? tempsLimiteSec;
  @override
  final String? hint;
  @override
  final String? explanation;

  @override
  String toString() {
    return 'QuestionModel(id: $id, quizId: $quizId, ordre: $ordre, typeQuestion: $typeQuestion, questionData: $questionData, points: $points, tempsLimiteSec: $tempsLimiteSec, hint: $hint, explanation: $explanation)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuestionModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.quizId, quizId) || other.quizId == quizId) &&
            (identical(other.ordre, ordre) || other.ordre == ordre) &&
            (identical(other.typeQuestion, typeQuestion) ||
                other.typeQuestion == typeQuestion) &&
            const DeepCollectionEquality()
                .equals(other._questionData, _questionData) &&
            (identical(other.points, points) || other.points == points) &&
            (identical(other.tempsLimiteSec, tempsLimiteSec) ||
                other.tempsLimiteSec == tempsLimiteSec) &&
            (identical(other.hint, hint) || other.hint == hint) &&
            (identical(other.explanation, explanation) ||
                other.explanation == explanation));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      quizId,
      ordre,
      typeQuestion,
      const DeepCollectionEquality().hash(_questionData),
      points,
      tempsLimiteSec,
      hint,
      explanation);

  /// Create a copy of QuestionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QuestionModelImplCopyWith<_$QuestionModelImpl> get copyWith =>
      __$$QuestionModelImplCopyWithImpl<_$QuestionModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QuestionModelImplToJson(
      this,
    );
  }
}

abstract class _QuestionModel implements QuestionModel {
  const factory _QuestionModel(
      {required final String id,
      @JsonKey(name: 'quiz_id') required final String quizId,
      required final int ordre,
      @JsonKey(name: 'type_question') required final String typeQuestion,
      @JsonKey(name: 'question_data')
      required final Map<String, dynamic> questionData,
      required final int points,
      @JsonKey(name: 'temps_limite_sec') final int? tempsLimiteSec,
      final String? hint,
      final String? explanation}) = _$QuestionModelImpl;

  factory _QuestionModel.fromJson(Map<String, dynamic> json) =
      _$QuestionModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'quiz_id')
  String get quizId;
  @override
  int get ordre;
  @override
  @JsonKey(name: 'type_question')
  String get typeQuestion;
  @override
  @JsonKey(name: 'question_data')
  Map<String, dynamic> get questionData;
  @override
  int get points;
  @override
  @JsonKey(name: 'temps_limite_sec')
  int? get tempsLimiteSec;
  @override
  String? get hint;
  @override
  String? get explanation;

  /// Create a copy of QuestionModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QuestionModelImplCopyWith<_$QuestionModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
