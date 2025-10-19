// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$QuizModelImpl _$$QuizModelImplFromJson(Map<String, dynamic> json) =>
    _$QuizModelImpl(
      id: json['id'] as String,
      titre: json['titre'] as String,
      description: json['description'] as String?,
      niveauDifficulte: json['niveau_difficulte'] as String,
      versionApp: json['version_app'] as String,
      regionScope: json['region_scope'] as String,
      mode: json['mode'] as String,
      nbQuestions: (json['nb_questions'] as num).toInt(),
      tempsLimiteSec: (json['temps_limite_sec'] as num?)?.toInt(),
      isActive: json['is_active'] as bool,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$$QuizModelImplToJson(_$QuizModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'titre': instance.titre,
      'description': instance.description,
      'niveau_difficulte': instance.niveauDifficulte,
      'version_app': instance.versionApp,
      'region_scope': instance.regionScope,
      'mode': instance.mode,
      'nb_questions': instance.nbQuestions,
      'temps_limite_sec': instance.tempsLimiteSec,
      'is_active': instance.isActive,
      'created_at': instance.createdAt,
    };
