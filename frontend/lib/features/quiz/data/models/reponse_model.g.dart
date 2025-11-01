// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reponse_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReponseModelImpl _$$ReponseModelImplFromJson(Map<String, dynamic> json) =>
    _$ReponseModelImpl(
      id: json['id'] as String,
      valeur: json['valeur'] as String?,
      ordre: (json['ordre'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$ReponseModelImplToJson(_$ReponseModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'valeur': instance.valeur,
      'ordre': instance.ordre,
    };
