// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'answer_submission.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AnswerSubmission _$AnswerSubmissionFromJson(Map<String, dynamic> json) {
  return _AnswerSubmission.fromJson(json);
}

/// @nodoc
mixin _$AnswerSubmission {
  /// ID de la question
  @JsonKey(name: 'question_id')
  String get questionId => throw _privateConstructorUsedError;

  /// ID de la réponse (pour choix multiples pré-définis)
  @JsonKey(name: 'reponse_id')
  String? get reponseId => throw _privateConstructorUsedError;

  /// Valeur saisie par l'utilisateur (pour réponses texte)
  @JsonKey(name: 'valeur_saisie')
  String? get valeurSaisie => throw _privateConstructorUsedError;

  /// Temps de réponse en secondes
  @JsonKey(name: 'temps_reponse_sec')
  int get tempsReponseSec => throw _privateConstructorUsedError;

  /// Serializes this AnswerSubmission to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AnswerSubmission
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AnswerSubmissionCopyWith<AnswerSubmission> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AnswerSubmissionCopyWith<$Res> {
  factory $AnswerSubmissionCopyWith(
          AnswerSubmission value, $Res Function(AnswerSubmission) then) =
      _$AnswerSubmissionCopyWithImpl<$Res, AnswerSubmission>;
  @useResult
  $Res call(
      {@JsonKey(name: 'question_id') String questionId,
      @JsonKey(name: 'reponse_id') String? reponseId,
      @JsonKey(name: 'valeur_saisie') String? valeurSaisie,
      @JsonKey(name: 'temps_reponse_sec') int tempsReponseSec});
}

/// @nodoc
class _$AnswerSubmissionCopyWithImpl<$Res, $Val extends AnswerSubmission>
    implements $AnswerSubmissionCopyWith<$Res> {
  _$AnswerSubmissionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AnswerSubmission
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? questionId = null,
    Object? reponseId = freezed,
    Object? valeurSaisie = freezed,
    Object? tempsReponseSec = null,
  }) {
    return _then(_value.copyWith(
      questionId: null == questionId
          ? _value.questionId
          : questionId // ignore: cast_nullable_to_non_nullable
              as String,
      reponseId: freezed == reponseId
          ? _value.reponseId
          : reponseId // ignore: cast_nullable_to_non_nullable
              as String?,
      valeurSaisie: freezed == valeurSaisie
          ? _value.valeurSaisie
          : valeurSaisie // ignore: cast_nullable_to_non_nullable
              as String?,
      tempsReponseSec: null == tempsReponseSec
          ? _value.tempsReponseSec
          : tempsReponseSec // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AnswerSubmissionImplCopyWith<$Res>
    implements $AnswerSubmissionCopyWith<$Res> {
  factory _$$AnswerSubmissionImplCopyWith(_$AnswerSubmissionImpl value,
          $Res Function(_$AnswerSubmissionImpl) then) =
      __$$AnswerSubmissionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'question_id') String questionId,
      @JsonKey(name: 'reponse_id') String? reponseId,
      @JsonKey(name: 'valeur_saisie') String? valeurSaisie,
      @JsonKey(name: 'temps_reponse_sec') int tempsReponseSec});
}

/// @nodoc
class __$$AnswerSubmissionImplCopyWithImpl<$Res>
    extends _$AnswerSubmissionCopyWithImpl<$Res, _$AnswerSubmissionImpl>
    implements _$$AnswerSubmissionImplCopyWith<$Res> {
  __$$AnswerSubmissionImplCopyWithImpl(_$AnswerSubmissionImpl _value,
      $Res Function(_$AnswerSubmissionImpl) _then)
      : super(_value, _then);

  /// Create a copy of AnswerSubmission
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? questionId = null,
    Object? reponseId = freezed,
    Object? valeurSaisie = freezed,
    Object? tempsReponseSec = null,
  }) {
    return _then(_$AnswerSubmissionImpl(
      questionId: null == questionId
          ? _value.questionId
          : questionId // ignore: cast_nullable_to_non_nullable
              as String,
      reponseId: freezed == reponseId
          ? _value.reponseId
          : reponseId // ignore: cast_nullable_to_non_nullable
              as String?,
      valeurSaisie: freezed == valeurSaisie
          ? _value.valeurSaisie
          : valeurSaisie // ignore: cast_nullable_to_non_nullable
              as String?,
      tempsReponseSec: null == tempsReponseSec
          ? _value.tempsReponseSec
          : tempsReponseSec // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AnswerSubmissionImpl implements _AnswerSubmission {
  const _$AnswerSubmissionImpl(
      {@JsonKey(name: 'question_id') required this.questionId,
      @JsonKey(name: 'reponse_id') this.reponseId,
      @JsonKey(name: 'valeur_saisie') this.valeurSaisie,
      @JsonKey(name: 'temps_reponse_sec') required this.tempsReponseSec});

  factory _$AnswerSubmissionImpl.fromJson(Map<String, dynamic> json) =>
      _$$AnswerSubmissionImplFromJson(json);

  /// ID de la question
  @override
  @JsonKey(name: 'question_id')
  final String questionId;

  /// ID de la réponse (pour choix multiples pré-définis)
  @override
  @JsonKey(name: 'reponse_id')
  final String? reponseId;

  /// Valeur saisie par l'utilisateur (pour réponses texte)
  @override
  @JsonKey(name: 'valeur_saisie')
  final String? valeurSaisie;

  /// Temps de réponse en secondes
  @override
  @JsonKey(name: 'temps_reponse_sec')
  final int tempsReponseSec;

  @override
  String toString() {
    return 'AnswerSubmission(questionId: $questionId, reponseId: $reponseId, valeurSaisie: $valeurSaisie, tempsReponseSec: $tempsReponseSec)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AnswerSubmissionImpl &&
            (identical(other.questionId, questionId) ||
                other.questionId == questionId) &&
            (identical(other.reponseId, reponseId) ||
                other.reponseId == reponseId) &&
            (identical(other.valeurSaisie, valeurSaisie) ||
                other.valeurSaisie == valeurSaisie) &&
            (identical(other.tempsReponseSec, tempsReponseSec) ||
                other.tempsReponseSec == tempsReponseSec));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, questionId, reponseId, valeurSaisie, tempsReponseSec);

  /// Create a copy of AnswerSubmission
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AnswerSubmissionImplCopyWith<_$AnswerSubmissionImpl> get copyWith =>
      __$$AnswerSubmissionImplCopyWithImpl<_$AnswerSubmissionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AnswerSubmissionImplToJson(
      this,
    );
  }
}

abstract class _AnswerSubmission implements AnswerSubmission {
  const factory _AnswerSubmission(
      {@JsonKey(name: 'question_id') required final String questionId,
      @JsonKey(name: 'reponse_id') final String? reponseId,
      @JsonKey(name: 'valeur_saisie') final String? valeurSaisie,
      @JsonKey(name: 'temps_reponse_sec')
      required final int tempsReponseSec}) = _$AnswerSubmissionImpl;

  factory _AnswerSubmission.fromJson(Map<String, dynamic> json) =
      _$AnswerSubmissionImpl.fromJson;

  /// ID de la question
  @override
  @JsonKey(name: 'question_id')
  String get questionId;

  /// ID de la réponse (pour choix multiples pré-définis)
  @override
  @JsonKey(name: 'reponse_id')
  String? get reponseId;

  /// Valeur saisie par l'utilisateur (pour réponses texte)
  @override
  @JsonKey(name: 'valeur_saisie')
  String? get valeurSaisie;

  /// Temps de réponse en secondes
  @override
  @JsonKey(name: 'temps_reponse_sec')
  int get tempsReponseSec;

  /// Create a copy of AnswerSubmission
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AnswerSubmissionImplCopyWith<_$AnswerSubmissionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserAnswerModel _$UserAnswerModelFromJson(Map<String, dynamic> json) {
  return _UserAnswerModel.fromJson(json);
}

/// @nodoc
mixin _$UserAnswerModel {
  /// ID unique de la réponse utilisateur
  String get id => throw _privateConstructorUsedError;

  /// ID de la session
  @JsonKey(name: 'session_id')
  String get sessionId => throw _privateConstructorUsedError;

  /// ID de la question
  @JsonKey(name: 'question_id')
  String get questionId => throw _privateConstructorUsedError;

  /// ID de la réponse choisie (si applicable)
  @JsonKey(name: 'reponse_id')
  String? get reponseId => throw _privateConstructorUsedError;

  /// Valeur saisie (si réponse texte)
  @JsonKey(name: 'valeur_saisie')
  String? get valeurSaisie => throw _privateConstructorUsedError;

  /// La réponse est-elle correcte ?
  @JsonKey(name: 'is_correct')
  bool get isCorrect => throw _privateConstructorUsedError;

  /// Points obtenus pour cette réponse
  @JsonKey(name: 'points_obtenus')
  int get pointsObtenus => throw _privateConstructorUsedError;

  /// Temps de réponse en secondes
  @JsonKey(name: 'temps_reponse_sec')
  int get tempsReponseSec => throw _privateConstructorUsedError;

  /// Métadonnées supplémentaires
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;

  /// Date de création
  @JsonKey(name: 'created_at')
  String? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this UserAnswerModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserAnswerModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserAnswerModelCopyWith<UserAnswerModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserAnswerModelCopyWith<$Res> {
  factory $UserAnswerModelCopyWith(
          UserAnswerModel value, $Res Function(UserAnswerModel) then) =
      _$UserAnswerModelCopyWithImpl<$Res, UserAnswerModel>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'session_id') String sessionId,
      @JsonKey(name: 'question_id') String questionId,
      @JsonKey(name: 'reponse_id') String? reponseId,
      @JsonKey(name: 'valeur_saisie') String? valeurSaisie,
      @JsonKey(name: 'is_correct') bool isCorrect,
      @JsonKey(name: 'points_obtenus') int pointsObtenus,
      @JsonKey(name: 'temps_reponse_sec') int tempsReponseSec,
      Map<String, dynamic>? metadata,
      @JsonKey(name: 'created_at') String? createdAt});
}

/// @nodoc
class _$UserAnswerModelCopyWithImpl<$Res, $Val extends UserAnswerModel>
    implements $UserAnswerModelCopyWith<$Res> {
  _$UserAnswerModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserAnswerModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sessionId = null,
    Object? questionId = null,
    Object? reponseId = freezed,
    Object? valeurSaisie = freezed,
    Object? isCorrect = null,
    Object? pointsObtenus = null,
    Object? tempsReponseSec = null,
    Object? metadata = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      questionId: null == questionId
          ? _value.questionId
          : questionId // ignore: cast_nullable_to_non_nullable
              as String,
      reponseId: freezed == reponseId
          ? _value.reponseId
          : reponseId // ignore: cast_nullable_to_non_nullable
              as String?,
      valeurSaisie: freezed == valeurSaisie
          ? _value.valeurSaisie
          : valeurSaisie // ignore: cast_nullable_to_non_nullable
              as String?,
      isCorrect: null == isCorrect
          ? _value.isCorrect
          : isCorrect // ignore: cast_nullable_to_non_nullable
              as bool,
      pointsObtenus: null == pointsObtenus
          ? _value.pointsObtenus
          : pointsObtenus // ignore: cast_nullable_to_non_nullable
              as int,
      tempsReponseSec: null == tempsReponseSec
          ? _value.tempsReponseSec
          : tempsReponseSec // ignore: cast_nullable_to_non_nullable
              as int,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserAnswerModelImplCopyWith<$Res>
    implements $UserAnswerModelCopyWith<$Res> {
  factory _$$UserAnswerModelImplCopyWith(_$UserAnswerModelImpl value,
          $Res Function(_$UserAnswerModelImpl) then) =
      __$$UserAnswerModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'session_id') String sessionId,
      @JsonKey(name: 'question_id') String questionId,
      @JsonKey(name: 'reponse_id') String? reponseId,
      @JsonKey(name: 'valeur_saisie') String? valeurSaisie,
      @JsonKey(name: 'is_correct') bool isCorrect,
      @JsonKey(name: 'points_obtenus') int pointsObtenus,
      @JsonKey(name: 'temps_reponse_sec') int tempsReponseSec,
      Map<String, dynamic>? metadata,
      @JsonKey(name: 'created_at') String? createdAt});
}

/// @nodoc
class __$$UserAnswerModelImplCopyWithImpl<$Res>
    extends _$UserAnswerModelCopyWithImpl<$Res, _$UserAnswerModelImpl>
    implements _$$UserAnswerModelImplCopyWith<$Res> {
  __$$UserAnswerModelImplCopyWithImpl(
      _$UserAnswerModelImpl _value, $Res Function(_$UserAnswerModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserAnswerModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sessionId = null,
    Object? questionId = null,
    Object? reponseId = freezed,
    Object? valeurSaisie = freezed,
    Object? isCorrect = null,
    Object? pointsObtenus = null,
    Object? tempsReponseSec = null,
    Object? metadata = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$UserAnswerModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      questionId: null == questionId
          ? _value.questionId
          : questionId // ignore: cast_nullable_to_non_nullable
              as String,
      reponseId: freezed == reponseId
          ? _value.reponseId
          : reponseId // ignore: cast_nullable_to_non_nullable
              as String?,
      valeurSaisie: freezed == valeurSaisie
          ? _value.valeurSaisie
          : valeurSaisie // ignore: cast_nullable_to_non_nullable
              as String?,
      isCorrect: null == isCorrect
          ? _value.isCorrect
          : isCorrect // ignore: cast_nullable_to_non_nullable
              as bool,
      pointsObtenus: null == pointsObtenus
          ? _value.pointsObtenus
          : pointsObtenus // ignore: cast_nullable_to_non_nullable
              as int,
      tempsReponseSec: null == tempsReponseSec
          ? _value.tempsReponseSec
          : tempsReponseSec // ignore: cast_nullable_to_non_nullable
              as int,
      metadata: freezed == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserAnswerModelImpl extends _UserAnswerModel {
  const _$UserAnswerModelImpl(
      {required this.id,
      @JsonKey(name: 'session_id') required this.sessionId,
      @JsonKey(name: 'question_id') required this.questionId,
      @JsonKey(name: 'reponse_id') this.reponseId,
      @JsonKey(name: 'valeur_saisie') this.valeurSaisie,
      @JsonKey(name: 'is_correct') required this.isCorrect,
      @JsonKey(name: 'points_obtenus') required this.pointsObtenus,
      @JsonKey(name: 'temps_reponse_sec') required this.tempsReponseSec,
      final Map<String, dynamic>? metadata,
      @JsonKey(name: 'created_at') this.createdAt})
      : _metadata = metadata,
        super._();

  factory _$UserAnswerModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserAnswerModelImplFromJson(json);

  /// ID unique de la réponse utilisateur
  @override
  final String id;

  /// ID de la session
  @override
  @JsonKey(name: 'session_id')
  final String sessionId;

  /// ID de la question
  @override
  @JsonKey(name: 'question_id')
  final String questionId;

  /// ID de la réponse choisie (si applicable)
  @override
  @JsonKey(name: 'reponse_id')
  final String? reponseId;

  /// Valeur saisie (si réponse texte)
  @override
  @JsonKey(name: 'valeur_saisie')
  final String? valeurSaisie;

  /// La réponse est-elle correcte ?
  @override
  @JsonKey(name: 'is_correct')
  final bool isCorrect;

  /// Points obtenus pour cette réponse
  @override
  @JsonKey(name: 'points_obtenus')
  final int pointsObtenus;

  /// Temps de réponse en secondes
  @override
  @JsonKey(name: 'temps_reponse_sec')
  final int tempsReponseSec;

  /// Métadonnées supplémentaires
  final Map<String, dynamic>? _metadata;

  /// Métadonnées supplémentaires
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  /// Date de création
  @override
  @JsonKey(name: 'created_at')
  final String? createdAt;

  @override
  String toString() {
    return 'UserAnswerModel(id: $id, sessionId: $sessionId, questionId: $questionId, reponseId: $reponseId, valeurSaisie: $valeurSaisie, isCorrect: $isCorrect, pointsObtenus: $pointsObtenus, tempsReponseSec: $tempsReponseSec, metadata: $metadata, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserAnswerModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.questionId, questionId) ||
                other.questionId == questionId) &&
            (identical(other.reponseId, reponseId) ||
                other.reponseId == reponseId) &&
            (identical(other.valeurSaisie, valeurSaisie) ||
                other.valeurSaisie == valeurSaisie) &&
            (identical(other.isCorrect, isCorrect) ||
                other.isCorrect == isCorrect) &&
            (identical(other.pointsObtenus, pointsObtenus) ||
                other.pointsObtenus == pointsObtenus) &&
            (identical(other.tempsReponseSec, tempsReponseSec) ||
                other.tempsReponseSec == tempsReponseSec) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      sessionId,
      questionId,
      reponseId,
      valeurSaisie,
      isCorrect,
      pointsObtenus,
      tempsReponseSec,
      const DeepCollectionEquality().hash(_metadata),
      createdAt);

  /// Create a copy of UserAnswerModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserAnswerModelImplCopyWith<_$UserAnswerModelImpl> get copyWith =>
      __$$UserAnswerModelImplCopyWithImpl<_$UserAnswerModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserAnswerModelImplToJson(
      this,
    );
  }
}

abstract class _UserAnswerModel extends UserAnswerModel {
  const factory _UserAnswerModel(
      {required final String id,
      @JsonKey(name: 'session_id') required final String sessionId,
      @JsonKey(name: 'question_id') required final String questionId,
      @JsonKey(name: 'reponse_id') final String? reponseId,
      @JsonKey(name: 'valeur_saisie') final String? valeurSaisie,
      @JsonKey(name: 'is_correct') required final bool isCorrect,
      @JsonKey(name: 'points_obtenus') required final int pointsObtenus,
      @JsonKey(name: 'temps_reponse_sec') required final int tempsReponseSec,
      final Map<String, dynamic>? metadata,
      @JsonKey(name: 'created_at')
      final String? createdAt}) = _$UserAnswerModelImpl;
  const _UserAnswerModel._() : super._();

  factory _UserAnswerModel.fromJson(Map<String, dynamic> json) =
      _$UserAnswerModelImpl.fromJson;

  /// ID unique de la réponse utilisateur
  @override
  String get id;

  /// ID de la session
  @override
  @JsonKey(name: 'session_id')
  String get sessionId;

  /// ID de la question
  @override
  @JsonKey(name: 'question_id')
  String get questionId;

  /// ID de la réponse choisie (si applicable)
  @override
  @JsonKey(name: 'reponse_id')
  String? get reponseId;

  /// Valeur saisie (si réponse texte)
  @override
  @JsonKey(name: 'valeur_saisie')
  String? get valeurSaisie;

  /// La réponse est-elle correcte ?
  @override
  @JsonKey(name: 'is_correct')
  bool get isCorrect;

  /// Points obtenus pour cette réponse
  @override
  @JsonKey(name: 'points_obtenus')
  int get pointsObtenus;

  /// Temps de réponse en secondes
  @override
  @JsonKey(name: 'temps_reponse_sec')
  int get tempsReponseSec;

  /// Métadonnées supplémentaires
  @override
  Map<String, dynamic>? get metadata;

  /// Date de création
  @override
  @JsonKey(name: 'created_at')
  String? get createdAt;

  /// Create a copy of UserAnswerModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserAnswerModelImplCopyWith<_$UserAnswerModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
