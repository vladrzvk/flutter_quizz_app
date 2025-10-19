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
  String get id => throw _privateConstructorUsedError;
  String get titre => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'niveau_difficulte')
  String get niveauDifficulte => throw _privateConstructorUsedError;
  @JsonKey(name: 'version_app')
  String get versionApp => throw _privateConstructorUsedError;
  @JsonKey(name: 'region_scope')
  String get regionScope => throw _privateConstructorUsedError;
  String get mode => throw _privateConstructorUsedError;
  @JsonKey(name: 'nb_questions')
  int get nbQuestions => throw _privateConstructorUsedError;
  @JsonKey(name: 'temps_limite_sec')
  int? get tempsLimiteSec => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_active')
  bool get isActive => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String get createdAt => throw _privateConstructorUsedError;

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
      String titre,
      String? description,
      @JsonKey(name: 'niveau_difficulte') String niveauDifficulte,
      @JsonKey(name: 'version_app') String versionApp,
      @JsonKey(name: 'region_scope') String regionScope,
      String mode,
      @JsonKey(name: 'nb_questions') int nbQuestions,
      @JsonKey(name: 'temps_limite_sec') int? tempsLimiteSec,
      @JsonKey(name: 'is_active') bool isActive,
      @JsonKey(name: 'created_at') String createdAt});
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
    Object? titre = null,
    Object? description = freezed,
    Object? niveauDifficulte = null,
    Object? versionApp = null,
    Object? regionScope = null,
    Object? mode = null,
    Object? nbQuestions = null,
    Object? tempsLimiteSec = freezed,
    Object? isActive = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
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
      regionScope: null == regionScope
          ? _value.regionScope
          : regionScope // ignore: cast_nullable_to_non_nullable
              as String,
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as String,
      nbQuestions: null == nbQuestions
          ? _value.nbQuestions
          : nbQuestions // ignore: cast_nullable_to_non_nullable
              as int,
      tempsLimiteSec: freezed == tempsLimiteSec
          ? _value.tempsLimiteSec
          : tempsLimiteSec // ignore: cast_nullable_to_non_nullable
              as int?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
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
      String titre,
      String? description,
      @JsonKey(name: 'niveau_difficulte') String niveauDifficulte,
      @JsonKey(name: 'version_app') String versionApp,
      @JsonKey(name: 'region_scope') String regionScope,
      String mode,
      @JsonKey(name: 'nb_questions') int nbQuestions,
      @JsonKey(name: 'temps_limite_sec') int? tempsLimiteSec,
      @JsonKey(name: 'is_active') bool isActive,
      @JsonKey(name: 'created_at') String createdAt});
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
    Object? titre = null,
    Object? description = freezed,
    Object? niveauDifficulte = null,
    Object? versionApp = null,
    Object? regionScope = null,
    Object? mode = null,
    Object? nbQuestions = null,
    Object? tempsLimiteSec = freezed,
    Object? isActive = null,
    Object? createdAt = null,
  }) {
    return _then(_$QuizModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
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
      regionScope: null == regionScope
          ? _value.regionScope
          : regionScope // ignore: cast_nullable_to_non_nullable
              as String,
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as String,
      nbQuestions: null == nbQuestions
          ? _value.nbQuestions
          : nbQuestions // ignore: cast_nullable_to_non_nullable
              as int,
      tempsLimiteSec: freezed == tempsLimiteSec
          ? _value.tempsLimiteSec
          : tempsLimiteSec // ignore: cast_nullable_to_non_nullable
              as int?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QuizModelImpl implements _QuizModel {
  const _$QuizModelImpl(
      {required this.id,
      required this.titre,
      this.description,
      @JsonKey(name: 'niveau_difficulte') required this.niveauDifficulte,
      @JsonKey(name: 'version_app') required this.versionApp,
      @JsonKey(name: 'region_scope') required this.regionScope,
      required this.mode,
      @JsonKey(name: 'nb_questions') required this.nbQuestions,
      @JsonKey(name: 'temps_limite_sec') this.tempsLimiteSec,
      @JsonKey(name: 'is_active') required this.isActive,
      @JsonKey(name: 'created_at') required this.createdAt});

  factory _$QuizModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuizModelImplFromJson(json);

  @override
  final String id;
  @override
  final String titre;
  @override
  final String? description;
  @override
  @JsonKey(name: 'niveau_difficulte')
  final String niveauDifficulte;
  @override
  @JsonKey(name: 'version_app')
  final String versionApp;
  @override
  @JsonKey(name: 'region_scope')
  final String regionScope;
  @override
  final String mode;
  @override
  @JsonKey(name: 'nb_questions')
  final int nbQuestions;
  @override
  @JsonKey(name: 'temps_limite_sec')
  final int? tempsLimiteSec;
  @override
  @JsonKey(name: 'is_active')
  final bool isActive;
  @override
  @JsonKey(name: 'created_at')
  final String createdAt;

  @override
  String toString() {
    return 'QuizModel(id: $id, titre: $titre, description: $description, niveauDifficulte: $niveauDifficulte, versionApp: $versionApp, regionScope: $regionScope, mode: $mode, nbQuestions: $nbQuestions, tempsLimiteSec: $tempsLimiteSec, isActive: $isActive, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuizModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.titre, titre) || other.titre == titre) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.niveauDifficulte, niveauDifficulte) ||
                other.niveauDifficulte == niveauDifficulte) &&
            (identical(other.versionApp, versionApp) ||
                other.versionApp == versionApp) &&
            (identical(other.regionScope, regionScope) ||
                other.regionScope == regionScope) &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.nbQuestions, nbQuestions) ||
                other.nbQuestions == nbQuestions) &&
            (identical(other.tempsLimiteSec, tempsLimiteSec) ||
                other.tempsLimiteSec == tempsLimiteSec) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      titre,
      description,
      niveauDifficulte,
      versionApp,
      regionScope,
      mode,
      nbQuestions,
      tempsLimiteSec,
      isActive,
      createdAt);

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
          required final String titre,
          final String? description,
          @JsonKey(name: 'niveau_difficulte')
          required final String niveauDifficulte,
          @JsonKey(name: 'version_app') required final String versionApp,
          @JsonKey(name: 'region_scope') required final String regionScope,
          required final String mode,
          @JsonKey(name: 'nb_questions') required final int nbQuestions,
          @JsonKey(name: 'temps_limite_sec') final int? tempsLimiteSec,
          @JsonKey(name: 'is_active') required final bool isActive,
          @JsonKey(name: 'created_at') required final String createdAt}) =
      _$QuizModelImpl;

  factory _QuizModel.fromJson(Map<String, dynamic> json) =
      _$QuizModelImpl.fromJson;

  @override
  String get id;
  @override
  String get titre;
  @override
  String? get description;
  @override
  @JsonKey(name: 'niveau_difficulte')
  String get niveauDifficulte;
  @override
  @JsonKey(name: 'version_app')
  String get versionApp;
  @override
  @JsonKey(name: 'region_scope')
  String get regionScope;
  @override
  String get mode;
  @override
  @JsonKey(name: 'nb_questions')
  int get nbQuestions;
  @override
  @JsonKey(name: 'temps_limite_sec')
  int? get tempsLimiteSec;
  @override
  @JsonKey(name: 'is_active')
  bool get isActive;
  @override
  @JsonKey(name: 'created_at')
  String get createdAt;

  /// Create a copy of QuizModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QuizModelImplCopyWith<_$QuizModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
