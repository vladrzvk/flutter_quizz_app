// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SessionModel _$SessionModelFromJson(Map<String, dynamic> json) {
  return _SessionModel.fromJson(json);
}

/// @nodoc
mixin _$SessionModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'quiz_id')
  String get quizId => throw _privateConstructorUsedError;
  int get score => throw _privateConstructorUsedError;
  @JsonKey(name: 'score_max')
  int get scoreMax => throw _privateConstructorUsedError;
  double? get pourcentage => throw _privateConstructorUsedError;
  @JsonKey(name: 'temps_total_sec')
  int? get tempsTotalSec => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'date_debut')
  String get dateDebut => throw _privateConstructorUsedError;
  @JsonKey(name: 'date_fin')
  String? get dateFin => throw _privateConstructorUsedError;

  /// Serializes this SessionModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SessionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SessionModelCopyWith<SessionModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SessionModelCopyWith<$Res> {
  factory $SessionModelCopyWith(
          SessionModel value, $Res Function(SessionModel) then) =
      _$SessionModelCopyWithImpl<$Res, SessionModel>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'quiz_id') String quizId,
      int score,
      @JsonKey(name: 'score_max') int scoreMax,
      double? pourcentage,
      @JsonKey(name: 'temps_total_sec') int? tempsTotalSec,
      String status,
      @JsonKey(name: 'date_debut') String dateDebut,
      @JsonKey(name: 'date_fin') String? dateFin});
}

/// @nodoc
class _$SessionModelCopyWithImpl<$Res, $Val extends SessionModel>
    implements $SessionModelCopyWith<$Res> {
  _$SessionModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SessionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? quizId = null,
    Object? score = null,
    Object? scoreMax = null,
    Object? pourcentage = freezed,
    Object? tempsTotalSec = freezed,
    Object? status = null,
    Object? dateDebut = null,
    Object? dateFin = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      quizId: null == quizId
          ? _value.quizId
          : quizId // ignore: cast_nullable_to_non_nullable
              as String,
      score: null == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as int,
      scoreMax: null == scoreMax
          ? _value.scoreMax
          : scoreMax // ignore: cast_nullable_to_non_nullable
              as int,
      pourcentage: freezed == pourcentage
          ? _value.pourcentage
          : pourcentage // ignore: cast_nullable_to_non_nullable
              as double?,
      tempsTotalSec: freezed == tempsTotalSec
          ? _value.tempsTotalSec
          : tempsTotalSec // ignore: cast_nullable_to_non_nullable
              as int?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      dateDebut: null == dateDebut
          ? _value.dateDebut
          : dateDebut // ignore: cast_nullable_to_non_nullable
              as String,
      dateFin: freezed == dateFin
          ? _value.dateFin
          : dateFin // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SessionModelImplCopyWith<$Res>
    implements $SessionModelCopyWith<$Res> {
  factory _$$SessionModelImplCopyWith(
          _$SessionModelImpl value, $Res Function(_$SessionModelImpl) then) =
      __$$SessionModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'quiz_id') String quizId,
      int score,
      @JsonKey(name: 'score_max') int scoreMax,
      double? pourcentage,
      @JsonKey(name: 'temps_total_sec') int? tempsTotalSec,
      String status,
      @JsonKey(name: 'date_debut') String dateDebut,
      @JsonKey(name: 'date_fin') String? dateFin});
}

/// @nodoc
class __$$SessionModelImplCopyWithImpl<$Res>
    extends _$SessionModelCopyWithImpl<$Res, _$SessionModelImpl>
    implements _$$SessionModelImplCopyWith<$Res> {
  __$$SessionModelImplCopyWithImpl(
      _$SessionModelImpl _value, $Res Function(_$SessionModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of SessionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? quizId = null,
    Object? score = null,
    Object? scoreMax = null,
    Object? pourcentage = freezed,
    Object? tempsTotalSec = freezed,
    Object? status = null,
    Object? dateDebut = null,
    Object? dateFin = freezed,
  }) {
    return _then(_$SessionModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      quizId: null == quizId
          ? _value.quizId
          : quizId // ignore: cast_nullable_to_non_nullable
              as String,
      score: null == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as int,
      scoreMax: null == scoreMax
          ? _value.scoreMax
          : scoreMax // ignore: cast_nullable_to_non_nullable
              as int,
      pourcentage: freezed == pourcentage
          ? _value.pourcentage
          : pourcentage // ignore: cast_nullable_to_non_nullable
              as double?,
      tempsTotalSec: freezed == tempsTotalSec
          ? _value.tempsTotalSec
          : tempsTotalSec // ignore: cast_nullable_to_non_nullable
              as int?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      dateDebut: null == dateDebut
          ? _value.dateDebut
          : dateDebut // ignore: cast_nullable_to_non_nullable
              as String,
      dateFin: freezed == dateFin
          ? _value.dateFin
          : dateFin // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SessionModelImpl implements _SessionModel {
  const _$SessionModelImpl(
      {required this.id,
      @JsonKey(name: 'user_id') required this.userId,
      @JsonKey(name: 'quiz_id') required this.quizId,
      required this.score,
      @JsonKey(name: 'score_max') required this.scoreMax,
      this.pourcentage,
      @JsonKey(name: 'temps_total_sec') this.tempsTotalSec,
      required this.status,
      @JsonKey(name: 'date_debut') required this.dateDebut,
      @JsonKey(name: 'date_fin') this.dateFin});

  factory _$SessionModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$SessionModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'quiz_id')
  final String quizId;
  @override
  final int score;
  @override
  @JsonKey(name: 'score_max')
  final int scoreMax;
  @override
  final double? pourcentage;
  @override
  @JsonKey(name: 'temps_total_sec')
  final int? tempsTotalSec;
  @override
  final String status;
  @override
  @JsonKey(name: 'date_debut')
  final String dateDebut;
  @override
  @JsonKey(name: 'date_fin')
  final String? dateFin;

  @override
  String toString() {
    return 'SessionModel(id: $id, userId: $userId, quizId: $quizId, score: $score, scoreMax: $scoreMax, pourcentage: $pourcentage, tempsTotalSec: $tempsTotalSec, status: $status, dateDebut: $dateDebut, dateFin: $dateFin)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SessionModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.quizId, quizId) || other.quizId == quizId) &&
            (identical(other.score, score) || other.score == score) &&
            (identical(other.scoreMax, scoreMax) ||
                other.scoreMax == scoreMax) &&
            (identical(other.pourcentage, pourcentage) ||
                other.pourcentage == pourcentage) &&
            (identical(other.tempsTotalSec, tempsTotalSec) ||
                other.tempsTotalSec == tempsTotalSec) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.dateDebut, dateDebut) ||
                other.dateDebut == dateDebut) &&
            (identical(other.dateFin, dateFin) || other.dateFin == dateFin));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, userId, quizId, score,
      scoreMax, pourcentage, tempsTotalSec, status, dateDebut, dateFin);

  /// Create a copy of SessionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SessionModelImplCopyWith<_$SessionModelImpl> get copyWith =>
      __$$SessionModelImplCopyWithImpl<_$SessionModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SessionModelImplToJson(
      this,
    );
  }
}

abstract class _SessionModel implements SessionModel {
  const factory _SessionModel(
      {required final String id,
      @JsonKey(name: 'user_id') required final String userId,
      @JsonKey(name: 'quiz_id') required final String quizId,
      required final int score,
      @JsonKey(name: 'score_max') required final int scoreMax,
      final double? pourcentage,
      @JsonKey(name: 'temps_total_sec') final int? tempsTotalSec,
      required final String status,
      @JsonKey(name: 'date_debut') required final String dateDebut,
      @JsonKey(name: 'date_fin') final String? dateFin}) = _$SessionModelImpl;

  factory _SessionModel.fromJson(Map<String, dynamic> json) =
      _$SessionModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @JsonKey(name: 'quiz_id')
  String get quizId;
  @override
  int get score;
  @override
  @JsonKey(name: 'score_max')
  int get scoreMax;
  @override
  double? get pourcentage;
  @override
  @JsonKey(name: 'temps_total_sec')
  int? get tempsTotalSec;
  @override
  String get status;
  @override
  @JsonKey(name: 'date_debut')
  String get dateDebut;
  @override
  @JsonKey(name: 'date_fin')
  String? get dateFin;

  /// Create a copy of SessionModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SessionModelImplCopyWith<_$SessionModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
