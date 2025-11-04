// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quiz_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

QuizModel _$QuizModelFromJson(Map<String, dynamic> json) {
  return _QuizModel.fromJson(json);
}

/// @nodoc
mixin _$QuizModel {
  /// ID unique du quiz
  String get id => throw _privateConstructorUsedError;

  /// ✅ NOUVEAU - Domaine du quiz (geography, code_route, etc.)
  /// Utilisé pour sélectionner le bon plugin côté backend
  @JsonKey(name: 'domain')
  String get domain => throw _privateConstructorUsedError;

  /// Titre du quiz
  String get titre => throw _privateConstructorUsedError;

  /// Description (optionnel)
  String? get description => throw _privateConstructorUsedError;

  /// Niveau de difficulté: 'facile', 'moyen', 'difficile'
  @JsonKey(name: 'niveau_difficulte')
  String get niveauDifficulte => throw _privateConstructorUsedError;

  /// Version de l'application
  @JsonKey(name: 'version_app')
  String get versionApp => throw _privateConstructorUsedError;

  /// ✅ MODIFIÉ - Portée du quiz (france, europe, monde, etc.)
  /// Avant: region_scope → Maintenant: scope
  @JsonKey(name: 'scope')
  String get scope => throw _privateConstructorUsedError;

  /// Mode de quiz: 'decouverte', 'entrainement', 'examen', 'competition'
  String get mode => throw _privateConstructorUsedError;

  /// ✅ NOUVEAU - ID de collection (optionnel)
  /// Pour regrouper plusieurs quiz ensemble
  @JsonKey(name: 'collection_id')
  String? get collectionId => throw _privateConstructorUsedError;

  /// Nombre de questions dans le quiz
  @JsonKey(name: 'nb_questions')
  int get nbQuestions => throw _privateConstructorUsedError;

  /// Temps limite global du quiz en secondes (optionnel)
  @JsonKey(name: 'temps_limite_sec')
  int? get tempsLimiteSec => throw _privateConstructorUsedError;

  /// ✅ NOUVEAU - Score minimum pour réussir (en %)
  @JsonKey(name: 'score_minimum_success')
  int? get scoreMinimumSuccess => throw _privateConstructorUsedError;

  /// Quiz actif ?
  @JsonKey(name: 'is_active')
  bool get isActive => throw _privateConstructorUsedError;

  /// ✅ NOUVEAU - Quiz public ?
  @JsonKey(name: 'is_public')
  bool? get isPublic => throw _privateConstructorUsedError;

  /// ✅ NOUVEAU - Nombre total de tentatives
  @JsonKey(name: 'total_attempts')
  int? get totalAttempts => throw _privateConstructorUsedError;

  /// ✅ NOUVEAU - Score moyen des joueurs
  @JsonKey(name: 'average_score')
  double? get averageScore => throw _privateConstructorUsedError;

  /// Date de création
  @JsonKey(name: 'created_at')
  String get createdAt => throw _privateConstructorUsedError;

  /// ✅ NOUVEAU - Date de mise à jour
  @JsonKey(name: 'updated_at')
  String? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this QuizModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of QuizModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QuizModelCopyWith<QuizModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuizModelCopyWith<$Res> {
  factory $QuizModelCopyWith(QuizModel value, $Res Function(QuizModel) then) =
      _$QuizModelCopyWithImpl<$Res, QuizModel>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'domain') String domain,
      String titre,
      String? description,
      @JsonKey(name: 'niveau_difficulte') String niveauDifficulte,
      @JsonKey(name: 'version_app') String versionApp,
      @JsonKey(name: 'scope') String scope,
      String mode,
      @JsonKey(name: 'collection_id') String? collectionId,
      @JsonKey(name: 'nb_questions') int nbQuestions,
      @JsonKey(name: 'temps_limite_sec') int? tempsLimiteSec,
      @JsonKey(name: 'score_minimum_success') int? scoreMinimumSuccess,
      @JsonKey(name: 'is_active') bool isActive,
      @JsonKey(name: 'is_public') bool? isPublic,
      @JsonKey(name: 'total_attempts') int? totalAttempts,
      @JsonKey(name: 'average_score') double? averageScore,
      @JsonKey(name: 'created_at') String createdAt,
      @JsonKey(name: 'updated_at') String? updatedAt});
}

/// @nodoc
class _$QuizModelCopyWithImpl<$Res, $Val extends QuizModel>
    implements $QuizModelCopyWith<$Res> {
  _$QuizModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QuizModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? domain = null,
    Object? titre = null,
    Object? description = freezed,
    Object? niveauDifficulte = null,
    Object? versionApp = null,
    Object? scope = null,
    Object? mode = null,
    Object? collectionId = freezed,
    Object? nbQuestions = null,
    Object? tempsLimiteSec = freezed,
    Object? scoreMinimumSuccess = freezed,
    Object? isActive = null,
    Object? isPublic = freezed,
    Object? totalAttempts = freezed,
    Object? averageScore = freezed,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      domain: null == domain
          ? _value.domain
          : domain // ignore: cast_nullable_to_non_nullable
              as String,
      titre: null == titre
          ? _value.titre
          : titre // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      niveauDifficulte: null == niveauDifficulte
          ? _value.niveauDifficulte
          : niveauDifficulte // ignore: cast_nullable_to_non_nullable
              as String,
      versionApp: null == versionApp
          ? _value.versionApp
          : versionApp // ignore: cast_nullable_to_non_nullable
              as String,
      scope: null == scope
          ? _value.scope
          : scope // ignore: cast_nullable_to_non_nullable
              as String,
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as String,
      collectionId: freezed == collectionId
          ? _value.collectionId
          : collectionId // ignore: cast_nullable_to_non_nullable
              as String?,
      nbQuestions: null == nbQuestions
          ? _value.nbQuestions
          : nbQuestions // ignore: cast_nullable_to_non_nullable
              as int,
      tempsLimiteSec: freezed == tempsLimiteSec
          ? _value.tempsLimiteSec
          : tempsLimiteSec // ignore: cast_nullable_to_non_nullable
              as int?,
      scoreMinimumSuccess: freezed == scoreMinimumSuccess
          ? _value.scoreMinimumSuccess
          : scoreMinimumSuccess // ignore: cast_nullable_to_non_nullable
              as int?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      isPublic: freezed == isPublic
          ? _value.isPublic
          : isPublic // ignore: cast_nullable_to_non_nullable
              as bool?,
      totalAttempts: freezed == totalAttempts
          ? _value.totalAttempts
          : totalAttempts // ignore: cast_nullable_to_non_nullable
              as int?,
      averageScore: freezed == averageScore
          ? _value.averageScore
          : averageScore // ignore: cast_nullable_to_non_nullable
              as double?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QuizModelImplCopyWith<$Res>
    implements $QuizModelCopyWith<$Res> {
  factory _$$QuizModelImplCopyWith(
          _$QuizModelImpl value, $Res Function(_$QuizModelImpl) then) =
      __$$QuizModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'domain') String domain,
      String titre,
      String? description,
      @JsonKey(name: 'niveau_difficulte') String niveauDifficulte,
      @JsonKey(name: 'version_app') String versionApp,
      @JsonKey(name: 'scope') String scope,
      String mode,
      @JsonKey(name: 'collection_id') String? collectionId,
      @JsonKey(name: 'nb_questions') int nbQuestions,
      @JsonKey(name: 'temps_limite_sec') int? tempsLimiteSec,
      @JsonKey(name: 'score_minimum_success') int? scoreMinimumSuccess,
      @JsonKey(name: 'is_active') bool isActive,
      @JsonKey(name: 'is_public') bool? isPublic,
      @JsonKey(name: 'total_attempts') int? totalAttempts,
      @JsonKey(name: 'average_score') double? averageScore,
      @JsonKey(name: 'created_at') String createdAt,
      @JsonKey(name: 'updated_at') String? updatedAt});
}

/// @nodoc
class __$$QuizModelImplCopyWithImpl<$Res>
    extends _$QuizModelCopyWithImpl<$Res, _$QuizModelImpl>
    implements _$$QuizModelImplCopyWith<$Res> {
  __$$QuizModelImplCopyWithImpl(
      _$QuizModelImpl _value, $Res Function(_$QuizModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of QuizModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? domain = null,
    Object? titre = null,
    Object? description = freezed,
    Object? niveauDifficulte = null,
    Object? versionApp = null,
    Object? scope = null,
    Object? mode = null,
    Object? collectionId = freezed,
    Object? nbQuestions = null,
    Object? tempsLimiteSec = freezed,
    Object? scoreMinimumSuccess = freezed,
    Object? isActive = null,
    Object? isPublic = freezed,
    Object? totalAttempts = freezed,
    Object? averageScore = freezed,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(_$QuizModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      domain: null == domain
          ? _value.domain
          : domain // ignore: cast_nullable_to_non_nullable
              as String,
      titre: null == titre
          ? _value.titre
          : titre // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      niveauDifficulte: null == niveauDifficulte
          ? _value.niveauDifficulte
          : niveauDifficulte // ignore: cast_nullable_to_non_nullable
              as String,
      versionApp: null == versionApp
          ? _value.versionApp
          : versionApp // ignore: cast_nullable_to_non_nullable
              as String,
      scope: null == scope
          ? _value.scope
          : scope // ignore: cast_nullable_to_non_nullable
              as String,
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as String,
      collectionId: freezed == collectionId
          ? _value.collectionId
          : collectionId // ignore: cast_nullable_to_non_nullable
              as String?,
      nbQuestions: null == nbQuestions
          ? _value.nbQuestions
          : nbQuestions // ignore: cast_nullable_to_non_nullable
              as int,
      tempsLimiteSec: freezed == tempsLimiteSec
          ? _value.tempsLimiteSec
          : tempsLimiteSec // ignore: cast_nullable_to_non_nullable
              as int?,
      scoreMinimumSuccess: freezed == scoreMinimumSuccess
          ? _value.scoreMinimumSuccess
          : scoreMinimumSuccess // ignore: cast_nullable_to_non_nullable
              as int?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      isPublic: freezed == isPublic
          ? _value.isPublic
          : isPublic // ignore: cast_nullable_to_non_nullable
              as bool?,
      totalAttempts: freezed == totalAttempts
          ? _value.totalAttempts
          : totalAttempts // ignore: cast_nullable_to_non_nullable
              as int?,
      averageScore: freezed == averageScore
          ? _value.averageScore
          : averageScore // ignore: cast_nullable_to_non_nullable
              as double?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QuizModelImpl implements _QuizModel {
  const _$QuizModelImpl(
      {required this.id,
      @JsonKey(name: 'domain') required this.domain,
      required this.titre,
      this.description,
      @JsonKey(name: 'niveau_difficulte') required this.niveauDifficulte,
      @JsonKey(name: 'version_app') required this.versionApp,
      @JsonKey(name: 'scope') required this.scope,
      required this.mode,
      @JsonKey(name: 'collection_id') this.collectionId,
      @JsonKey(name: 'nb_questions') required this.nbQuestions,
      @JsonKey(name: 'temps_limite_sec') this.tempsLimiteSec,
      @JsonKey(name: 'score_minimum_success') this.scoreMinimumSuccess,
      @JsonKey(name: 'is_active') required this.isActive,
      @JsonKey(name: 'is_public') this.isPublic,
      @JsonKey(name: 'total_attempts') this.totalAttempts,
      @JsonKey(name: 'average_score') this.averageScore,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt});

  factory _$QuizModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuizModelImplFromJson(json);

  /// ID unique du quiz
  @override
  final String id;

  /// ✅ NOUVEAU - Domaine du quiz (geography, code_route, etc.)
  /// Utilisé pour sélectionner le bon plugin côté backend
  @override
  @JsonKey(name: 'domain')
  final String domain;

  /// Titre du quiz
  @override
  final String titre;

  /// Description (optionnel)
  @override
  final String? description;

  /// Niveau de difficulté: 'facile', 'moyen', 'difficile'
  @override
  @JsonKey(name: 'niveau_difficulte')
  final String niveauDifficulte;

  /// Version de l'application
  @override
  @JsonKey(name: 'version_app')
  final String versionApp;

  /// ✅ MODIFIÉ - Portée du quiz (france, europe, monde, etc.)
  /// Avant: region_scope → Maintenant: scope
  @override
  @JsonKey(name: 'scope')
  final String scope;

  /// Mode de quiz: 'decouverte', 'entrainement', 'examen', 'competition'
  @override
  final String mode;

  /// ✅ NOUVEAU - ID de collection (optionnel)
  /// Pour regrouper plusieurs quiz ensemble
  @override
  @JsonKey(name: 'collection_id')
  final String? collectionId;

  /// Nombre de questions dans le quiz
  @override
  @JsonKey(name: 'nb_questions')
  final int nbQuestions;

  /// Temps limite global du quiz en secondes (optionnel)
  @override
  @JsonKey(name: 'temps_limite_sec')
  final int? tempsLimiteSec;

  /// ✅ NOUVEAU - Score minimum pour réussir (en %)
  @override
  @JsonKey(name: 'score_minimum_success')
  final int? scoreMinimumSuccess;

  /// Quiz actif ?
  @override
  @JsonKey(name: 'is_active')
  final bool isActive;

  /// ✅ NOUVEAU - Quiz public ?
  @override
  @JsonKey(name: 'is_public')
  final bool? isPublic;

  /// ✅ NOUVEAU - Nombre total de tentatives
  @override
  @JsonKey(name: 'total_attempts')
  final int? totalAttempts;

  /// ✅ NOUVEAU - Score moyen des joueurs
  @override
  @JsonKey(name: 'average_score')
  final double? averageScore;

  /// Date de création
  @override
  @JsonKey(name: 'created_at')
  final String createdAt;

  /// ✅ NOUVEAU - Date de mise à jour
  @override
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  @override
  String toString() {
    return 'QuizModel(id: $id, domain: $domain, titre: $titre, description: $description, niveauDifficulte: $niveauDifficulte, versionApp: $versionApp, scope: $scope, mode: $mode, collectionId: $collectionId, nbQuestions: $nbQuestions, tempsLimiteSec: $tempsLimiteSec, scoreMinimumSuccess: $scoreMinimumSuccess, isActive: $isActive, isPublic: $isPublic, totalAttempts: $totalAttempts, averageScore: $averageScore, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuizModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.domain, domain) || other.domain == domain) &&
            (identical(other.titre, titre) || other.titre == titre) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.niveauDifficulte, niveauDifficulte) ||
                other.niveauDifficulte == niveauDifficulte) &&
            (identical(other.versionApp, versionApp) ||
                other.versionApp == versionApp) &&
            (identical(other.scope, scope) || other.scope == scope) &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.collectionId, collectionId) ||
                other.collectionId == collectionId) &&
            (identical(other.nbQuestions, nbQuestions) ||
                other.nbQuestions == nbQuestions) &&
            (identical(other.tempsLimiteSec, tempsLimiteSec) ||
                other.tempsLimiteSec == tempsLimiteSec) &&
            (identical(other.scoreMinimumSuccess, scoreMinimumSuccess) ||
                other.scoreMinimumSuccess == scoreMinimumSuccess) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.isPublic, isPublic) ||
                other.isPublic == isPublic) &&
            (identical(other.totalAttempts, totalAttempts) ||
                other.totalAttempts == totalAttempts) &&
            (identical(other.averageScore, averageScore) ||
                other.averageScore == averageScore) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      domain,
      titre,
      description,
      niveauDifficulte,
      versionApp,
      scope,
      mode,
      collectionId,
      nbQuestions,
      tempsLimiteSec,
      scoreMinimumSuccess,
      isActive,
      isPublic,
      totalAttempts,
      averageScore,
      createdAt,
      updatedAt);

  /// Create a copy of QuizModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QuizModelImplCopyWith<_$QuizModelImpl> get copyWith =>
      __$$QuizModelImplCopyWithImpl<_$QuizModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QuizModelImplToJson(
      this,
    );
  }
}

abstract class _QuizModel implements QuizModel {
  const factory _QuizModel(
      {required final String id,
      @JsonKey(name: 'domain') required final String domain,
      required final String titre,
      final String? description,
      @JsonKey(name: 'niveau_difficulte')
      required final String niveauDifficulte,
      @JsonKey(name: 'version_app') required final String versionApp,
      @JsonKey(name: 'scope') required final String scope,
      required final String mode,
      @JsonKey(name: 'collection_id') final String? collectionId,
      @JsonKey(name: 'nb_questions') required final int nbQuestions,
      @JsonKey(name: 'temps_limite_sec') final int? tempsLimiteSec,
      @JsonKey(name: 'score_minimum_success') final int? scoreMinimumSuccess,
      @JsonKey(name: 'is_active') required final bool isActive,
      @JsonKey(name: 'is_public') final bool? isPublic,
      @JsonKey(name: 'total_attempts') final int? totalAttempts,
      @JsonKey(name: 'average_score') final double? averageScore,
      @JsonKey(name: 'created_at') required final String createdAt,
      @JsonKey(name: 'updated_at') final String? updatedAt}) = _$QuizModelImpl;

  factory _QuizModel.fromJson(Map<String, dynamic> json) =
      _$QuizModelImpl.fromJson;

  /// ID unique du quiz
  @override
  String get id;

  /// ✅ NOUVEAU - Domaine du quiz (geography, code_route, etc.)
  /// Utilisé pour sélectionner le bon plugin côté backend
  @override
  @JsonKey(name: 'domain')
  String get domain;

  /// Titre du quiz
  @override
  String get titre;

  /// Description (optionnel)
  @override
  String? get description;

  /// Niveau de difficulté: 'facile', 'moyen', 'difficile'
  @override
  @JsonKey(name: 'niveau_difficulte')
  String get niveauDifficulte;

  /// Version de l'application
  @override
  @JsonKey(name: 'version_app')
  String get versionApp;

  /// ✅ MODIFIÉ - Portée du quiz (france, europe, monde, etc.)
  /// Avant: region_scope → Maintenant: scope
  @override
  @JsonKey(name: 'scope')
  String get scope;

  /// Mode de quiz: 'decouverte', 'entrainement', 'examen', 'competition'
  @override
  String get mode;

  /// ✅ NOUVEAU - ID de collection (optionnel)
  /// Pour regrouper plusieurs quiz ensemble
  @override
  @JsonKey(name: 'collection_id')
  String? get collectionId;

  /// Nombre de questions dans le quiz
  @override
  @JsonKey(name: 'nb_questions')
  int get nbQuestions;

  /// Temps limite global du quiz en secondes (optionnel)
  @override
  @JsonKey(name: 'temps_limite_sec')
  int? get tempsLimiteSec;

  /// ✅ NOUVEAU - Score minimum pour réussir (en %)
  @override
  @JsonKey(name: 'score_minimum_success')
  int? get scoreMinimumSuccess;

  /// Quiz actif ?
  @override
  @JsonKey(name: 'is_active')
  bool get isActive;

  /// ✅ NOUVEAU - Quiz public ?
  @override
  @JsonKey(name: 'is_public')
  bool? get isPublic;

  /// ✅ NOUVEAU - Nombre total de tentatives
  @override
  @JsonKey(name: 'total_attempts')
  int? get totalAttempts;

  /// ✅ NOUVEAU - Score moyen des joueurs
  @override
  @JsonKey(name: 'average_score')
  double? get averageScore;

  /// Date de création
  @override
  @JsonKey(name: 'created_at')
  String get createdAt;

  /// ✅ NOUVEAU - Date de mise à jour
  @override
  @JsonKey(name: 'updated_at')
  String? get updatedAt;

  /// Create a copy of QuizModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QuizModelImplCopyWith<_$QuizModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
