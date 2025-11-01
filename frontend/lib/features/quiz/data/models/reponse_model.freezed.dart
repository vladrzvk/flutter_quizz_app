// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reponse_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ReponseModel _$ReponseModelFromJson(Map<String, dynamic> json) {
  return _ReponseModel.fromJson(json);
}

/// @nodoc
mixin _$ReponseModel {
  String get id => throw _privateConstructorUsedError;
  String? get valeur => throw _privateConstructorUsedError;
  int? get ordre => throw _privateConstructorUsedError;

  /// Serializes this ReponseModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReponseModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReponseModelCopyWith<ReponseModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReponseModelCopyWith<$Res> {
  factory $ReponseModelCopyWith(
          ReponseModel value, $Res Function(ReponseModel) then) =
      _$ReponseModelCopyWithImpl<$Res, ReponseModel>;
  @useResult
  $Res call({String id, String? valeur, int? ordre});
}

/// @nodoc
class _$ReponseModelCopyWithImpl<$Res, $Val extends ReponseModel>
    implements $ReponseModelCopyWith<$Res> {
  _$ReponseModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReponseModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? valeur = freezed,
    Object? ordre = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      valeur: freezed == valeur
          ? _value.valeur
          : valeur // ignore: cast_nullable_to_non_nullable
              as String?,
      ordre: freezed == ordre
          ? _value.ordre
          : ordre // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ReponseModelImplCopyWith<$Res>
    implements $ReponseModelCopyWith<$Res> {
  factory _$$ReponseModelImplCopyWith(
          _$ReponseModelImpl value, $Res Function(_$ReponseModelImpl) then) =
      __$$ReponseModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String? valeur, int? ordre});
}

/// @nodoc
class __$$ReponseModelImplCopyWithImpl<$Res>
    extends _$ReponseModelCopyWithImpl<$Res, _$ReponseModelImpl>
    implements _$$ReponseModelImplCopyWith<$Res> {
  __$$ReponseModelImplCopyWithImpl(
      _$ReponseModelImpl _value, $Res Function(_$ReponseModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of ReponseModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? valeur = freezed,
    Object? ordre = freezed,
  }) {
    return _then(_$ReponseModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      valeur: freezed == valeur
          ? _value.valeur
          : valeur // ignore: cast_nullable_to_non_nullable
              as String?,
      ordre: freezed == ordre
          ? _value.ordre
          : ordre // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ReponseModelImpl implements _ReponseModel {
  const _$ReponseModelImpl({required this.id, this.valeur, this.ordre});

  factory _$ReponseModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReponseModelImplFromJson(json);

  @override
  final String id;
  @override
  final String? valeur;
  @override
  final int? ordre;

  @override
  String toString() {
    return 'ReponseModel(id: $id, valeur: $valeur, ordre: $ordre)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReponseModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.valeur, valeur) || other.valeur == valeur) &&
            (identical(other.ordre, ordre) || other.ordre == ordre));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, valeur, ordre);

  /// Create a copy of ReponseModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReponseModelImplCopyWith<_$ReponseModelImpl> get copyWith =>
      __$$ReponseModelImplCopyWithImpl<_$ReponseModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReponseModelImplToJson(
      this,
    );
  }
}

abstract class _ReponseModel implements ReponseModel {
  const factory _ReponseModel(
      {required final String id,
      final String? valeur,
      final int? ordre}) = _$ReponseModelImpl;

  factory _ReponseModel.fromJson(Map<String, dynamic> json) =
      _$ReponseModelImpl.fromJson;

  @override
  String get id;
  @override
  String? get valeur;
  @override
  int? get ordre;

  /// Create a copy of ReponseModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReponseModelImplCopyWith<_$ReponseModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
