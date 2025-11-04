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
  int get ordre =>
      throw _privateConstructorUsedError; // ✅ NOUVEAU - Catégorisation
  String? get category => throw _privateConstructorUsedError;
  String? get subcategory => throw _privateConstructorUsedError;
  @JsonKey(name: 'type_question')
  String get typeQuestion => throw _privateConstructorUsedError;
  @JsonKey(name: 'question_data')
  Map<String, dynamic> get questionData =>
      throw _privateConstructorUsedError; // ✅ NOUVEAU - Médias
  @JsonKey(name: 'media_url')
  String? get mediaUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_id')
  String? get targetId => throw _privateConstructorUsedError;
  int get points => throw _privateConstructorUsedError;
  @JsonKey(name: 'temps_limite_sec')
  int? get tempsLimiteSec => throw _privateConstructorUsedError;
  String? get hint => throw _privateConstructorUsedError;
  String? get explanation =>
      throw _privateConstructorUsedError; // ✅ NOUVEAU - Métadonnées & Stats
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_attempts')
  int? get totalAttempts => throw _privateConstructorUsedError;
  @JsonKey(name: 'correct_attempts')
  int? get correctAttempts => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  String? get updatedAt =>
      throw _privateConstructorUsedError; // ✅ CRUCIAL - Réponses incluses dans GET questions
  List<ReponseModel>? get reponses => throw _privateConstructorUsedError;

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
      String? category,
      String? subcategory,
      @JsonKey(name: 'type_question') String typeQuestion,
      @JsonKey(name: 'question_data') Map<String, dynamic> questionData,
      @JsonKey(name: 'media_url') String? mediaUrl,
      @JsonKey(name: 'target_id') String? targetId,
      int points,
      @JsonKey(name: 'temps_limite_sec') int? tempsLimiteSec,
      String? hint,
      String? explanation,
      Map<String, dynamic>? metadata,
      @JsonKey(name: 'total_attempts') int? totalAttempts,
      @JsonKey(name: 'correct_attempts') int? correctAttempts,
      @JsonKey(name: 'created_at') String? createdAt,
      @JsonKey(name: 'updated_at') String? updatedAt,
      List<ReponseModel>? reponses});
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
    Object? category = freezed,
    Object? subcategory = freezed,
    Object? typeQuestion = null,
    Object? questionData = null,
    Object? mediaUrl = freezed,
    Object? targetId = freezed,
    Object? points = null,
    Object? tempsLimiteSec = freezed,
    Object? hint = freezed,
    Object? explanation = freezed,
    Object? metadata = freezed,
    Object? totalAttempts = freezed,
    Object? correctAttempts = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? reponses = freezed,
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
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      subcategory: freezed == subcategory
          ? _value.subcategory
          : subcategory // ignore: cast_nullable_to_non_nullable
              as String?,
      typeQuestion: null == typeQuestion
          ? _value.typeQuestion
          : typeQuestion // ignore: cast_nullable_to_non_nullable
              as String,
      questionData: null == questionData
          ? _value.questionData
          : questionData // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      mediaUrl: freezed == mediaUrl
          ? _value.mediaUrl
          : mediaUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      targetId: freezed == targetId
          ? _value.targetId
          : targetId // ignore: cast_nullable_to_non_nullable
              as String?,
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
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      totalAttempts: freezed == totalAttempts
          ? _value.totalAttempts
          : totalAttempts // ignore: cast_nullable_to_non_nullable
              as int?,
      correctAttempts: freezed == correctAttempts
          ? _value.correctAttempts
          : correctAttempts // ignore: cast_nullable_to_non_nullable
              as int?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      reponses: freezed == reponses
          ? _value.reponses
          : reponses // ignore: cast_nullable_to_non_nullable
              as List<ReponseModel>?,
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
      String? category,
      String? subcategory,
      @JsonKey(name: 'type_question') String typeQuestion,
      @JsonKey(name: 'question_data') Map<String, dynamic> questionData,
      @JsonKey(name: 'media_url') String? mediaUrl,
      @JsonKey(name: 'target_id') String? targetId,
      int points,
      @JsonKey(name: 'temps_limite_sec') int? tempsLimiteSec,
      String? hint,
      String? explanation,
      Map<String, dynamic>? metadata,
      @JsonKey(name: 'total_attempts') int? totalAttempts,
      @JsonKey(name: 'correct_attempts') int? correctAttempts,
      @JsonKey(name: 'created_at') String? createdAt,
      @JsonKey(name: 'updated_at') String? updatedAt,
      List<ReponseModel>? reponses});
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
    Object? category = freezed,
    Object? subcategory = freezed,
    Object? typeQuestion = null,
    Object? questionData = null,
    Object? mediaUrl = freezed,
    Object? targetId = freezed,
    Object? points = null,
    Object? tempsLimiteSec = freezed,
    Object? hint = freezed,
    Object? explanation = freezed,
    Object? metadata = freezed,
    Object? totalAttempts = freezed,
    Object? correctAttempts = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? reponses = freezed,
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
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      subcategory: freezed == subcategory
          ? _value.subcategory
          : subcategory // ignore: cast_nullable_to_non_nullable
              as String?,
      typeQuestion: null == typeQuestion
          ? _value.typeQuestion
          : typeQuestion // ignore: cast_nullable_to_non_nullable
              as String,
      questionData: null == questionData
          ? _value._questionData
          : questionData // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      mediaUrl: freezed == mediaUrl
          ? _value.mediaUrl
          : mediaUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      targetId: freezed == targetId
          ? _value.targetId
          : targetId // ignore: cast_nullable_to_non_nullable
              as String?,
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
      metadata: freezed == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      totalAttempts: freezed == totalAttempts
          ? _value.totalAttempts
          : totalAttempts // ignore: cast_nullable_to_non_nullable
              as int?,
      correctAttempts: freezed == correctAttempts
          ? _value.correctAttempts
          : correctAttempts // ignore: cast_nullable_to_non_nullable
              as int?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      reponses: freezed == reponses
          ? _value._reponses
          : reponses // ignore: cast_nullable_to_non_nullable
              as List<ReponseModel>?,
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
      this.category,
      this.subcategory,
      @JsonKey(name: 'type_question') required this.typeQuestion,
      @JsonKey(name: 'question_data')
      required final Map<String, dynamic> questionData,
      @JsonKey(name: 'media_url') this.mediaUrl,
      @JsonKey(name: 'target_id') this.targetId,
      required this.points,
      @JsonKey(name: 'temps_limite_sec') this.tempsLimiteSec,
      this.hint,
      this.explanation,
      final Map<String, dynamic>? metadata,
      @JsonKey(name: 'total_attempts') this.totalAttempts,
      @JsonKey(name: 'correct_attempts') this.correctAttempts,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt,
      final List<ReponseModel>? reponses})
      : _questionData = questionData,
        _metadata = metadata,
        _reponses = reponses;

  factory _$QuestionModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuestionModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'quiz_id')
  final String quizId;
  @override
  final int ordre;
// ✅ NOUVEAU - Catégorisation
  @override
  final String? category;
  @override
  final String? subcategory;
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

// ✅ NOUVEAU - Médias
  @override
  @JsonKey(name: 'media_url')
  final String? mediaUrl;
  @override
  @JsonKey(name: 'target_id')
  final String? targetId;
  @override
  final int points;
  @override
  @JsonKey(name: 'temps_limite_sec')
  final int? tempsLimiteSec;
  @override
  final String? hint;
  @override
  final String? explanation;
// ✅ NOUVEAU - Métadonnées & Stats
  final Map<String, dynamic>? _metadata;
// ✅ NOUVEAU - Métadonnées & Stats
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey(name: 'total_attempts')
  final int? totalAttempts;
  @override
  @JsonKey(name: 'correct_attempts')
  final int? correctAttempts;
  @override
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
// ✅ CRUCIAL - Réponses incluses dans GET questions
  final List<ReponseModel>? _reponses;
// ✅ CRUCIAL - Réponses incluses dans GET questions
  @override
  List<ReponseModel>? get reponses {
    final value = _reponses;
    if (value == null) return null;
    if (_reponses is EqualUnmodifiableListView) return _reponses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'QuestionModel(id: $id, quizId: $quizId, ordre: $ordre, category: $category, subcategory: $subcategory, typeQuestion: $typeQuestion, questionData: $questionData, mediaUrl: $mediaUrl, targetId: $targetId, points: $points, tempsLimiteSec: $tempsLimiteSec, hint: $hint, explanation: $explanation, metadata: $metadata, totalAttempts: $totalAttempts, correctAttempts: $correctAttempts, createdAt: $createdAt, updatedAt: $updatedAt, reponses: $reponses)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuestionModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.quizId, quizId) || other.quizId == quizId) &&
            (identical(other.ordre, ordre) || other.ordre == ordre) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.subcategory, subcategory) ||
                other.subcategory == subcategory) &&
            (identical(other.typeQuestion, typeQuestion) ||
                other.typeQuestion == typeQuestion) &&
            const DeepCollectionEquality()
                .equals(other._questionData, _questionData) &&
            (identical(other.mediaUrl, mediaUrl) ||
                other.mediaUrl == mediaUrl) &&
            (identical(other.targetId, targetId) ||
                other.targetId == targetId) &&
            (identical(other.points, points) || other.points == points) &&
            (identical(other.tempsLimiteSec, tempsLimiteSec) ||
                other.tempsLimiteSec == tempsLimiteSec) &&
            (identical(other.hint, hint) || other.hint == hint) &&
            (identical(other.explanation, explanation) ||
                other.explanation == explanation) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            (identical(other.totalAttempts, totalAttempts) ||
                other.totalAttempts == totalAttempts) &&
            (identical(other.correctAttempts, correctAttempts) ||
                other.correctAttempts == correctAttempts) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality().equals(other._reponses, _reponses));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        quizId,
        ordre,
        category,
        subcategory,
        typeQuestion,
        const DeepCollectionEquality().hash(_questionData),
        mediaUrl,
        targetId,
        points,
        tempsLimiteSec,
        hint,
        explanation,
        const DeepCollectionEquality().hash(_metadata),
        totalAttempts,
        correctAttempts,
        createdAt,
        updatedAt,
        const DeepCollectionEquality().hash(_reponses)
      ]);

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
      final String? category,
      final String? subcategory,
      @JsonKey(name: 'type_question') required final String typeQuestion,
      @JsonKey(name: 'question_data')
      required final Map<String, dynamic> questionData,
      @JsonKey(name: 'media_url') final String? mediaUrl,
      @JsonKey(name: 'target_id') final String? targetId,
      required final int points,
      @JsonKey(name: 'temps_limite_sec') final int? tempsLimiteSec,
      final String? hint,
      final String? explanation,
      final Map<String, dynamic>? metadata,
      @JsonKey(name: 'total_attempts') final int? totalAttempts,
      @JsonKey(name: 'correct_attempts') final int? correctAttempts,
      @JsonKey(name: 'created_at') final String? createdAt,
      @JsonKey(name: 'updated_at') final String? updatedAt,
      final List<ReponseModel>? reponses}) = _$QuestionModelImpl;

  factory _QuestionModel.fromJson(Map<String, dynamic> json) =
      _$QuestionModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'quiz_id')
  String get quizId;
  @override
  int get ordre; // ✅ NOUVEAU - Catégorisation
  @override
  String? get category;
  @override
  String? get subcategory;
  @override
  @JsonKey(name: 'type_question')
  String get typeQuestion;
  @override
  @JsonKey(name: 'question_data')
  Map<String, dynamic> get questionData; // ✅ NOUVEAU - Médias
  @override
  @JsonKey(name: 'media_url')
  String? get mediaUrl;
  @override
  @JsonKey(name: 'target_id')
  String? get targetId;
  @override
  int get points;
  @override
  @JsonKey(name: 'temps_limite_sec')
  int? get tempsLimiteSec;
  @override
  String? get hint;
  @override
  String? get explanation; // ✅ NOUVEAU - Métadonnées & Stats
  @override
  Map<String, dynamic>? get metadata;
  @override
  @JsonKey(name: 'total_attempts')
  int? get totalAttempts;
  @override
  @JsonKey(name: 'correct_attempts')
  int? get correctAttempts;
  @override
  @JsonKey(name: 'created_at')
  String? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  String? get updatedAt; // ✅ CRUCIAL - Réponses incluses dans GET questions
  @override
  List<ReponseModel>? get reponses;

  /// Create a copy of QuestionModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QuestionModelImplCopyWith<_$QuestionModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
