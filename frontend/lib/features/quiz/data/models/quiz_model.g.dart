// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$QuizModelImpl _$$QuizModelImplFromJson(Map<String, dynamic> json) =>
    _$QuizModelImpl(
      id: json['id'] as String,
      domain: json['domain'] as String,
      titre: json['titre'] as String,
      description: json['description'] as String?,
      niveauDifficulte: json['niveau_difficulte'] as String,
      versionApp: json['version_app'] as String,
      scope: json['scope'] as String,
      mode: json['mode'] as String,
      collectionId: json['collection_id'] as String?,
      nbQuestions: (json['nb_questions'] as num).toInt(),
      tempsLimiteSec: (json['temps_limite_sec'] as num?)?.toInt(),
      scoreMinimumSuccess: (json['score_minimum_success'] as num?)?.toInt(),
      isActive: json['is_active'] as bool,
      isPublic: json['is_public'] as bool?,
      totalAttempts: (json['total_attempts'] as num?)?.toInt(),
      averageScore: (json['average_score'] as num?)?.toDouble(),
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String?,
    );

Map<String, dynamic> _$$QuizModelImplToJson(_$QuizModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'domain': instance.domain,
      'titre': instance.titre,
      'description': instance.description,
      'niveau_difficulte': instance.niveauDifficulte,
      'version_app': instance.versionApp,
      'scope': instance.scope,
      'mode': instance.mode,
      'collection_id': instance.collectionId,
      'nb_questions': instance.nbQuestions,
      'temps_limite_sec': instance.tempsLimiteSec,
      'score_minimum_success': instance.scoreMinimumSuccess,
      'is_active': instance.isActive,
      'is_public': instance.isPublic,
      'total_attempts': instance.totalAttempts,
      'average_score': instance.averageScore,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
