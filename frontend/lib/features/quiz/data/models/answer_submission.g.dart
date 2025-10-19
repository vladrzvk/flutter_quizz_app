// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'answer_submission.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AnswerSubmissionImpl _$$AnswerSubmissionImplFromJson(
        Map<String, dynamic> json) =>
    _$AnswerSubmissionImpl(
      questionId: json['question_id'] as String,
      reponseId: json['reponse_id'] as String?,
      valeurSaisie: json['valeur_saisie'] as String?,
      tempsReponseSec: (json['temps_reponse_sec'] as num).toInt(),
    );

Map<String, dynamic> _$$AnswerSubmissionImplToJson(
        _$AnswerSubmissionImpl instance) =>
    <String, dynamic>{
      'question_id': instance.questionId,
      'reponse_id': instance.reponseId,
      'valeur_saisie': instance.valeurSaisie,
      'temps_reponse_sec': instance.tempsReponseSec,
    };

_$UserAnswerModelImpl _$$UserAnswerModelImplFromJson(
        Map<String, dynamic> json) =>
    _$UserAnswerModelImpl(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      questionId: json['question_id'] as String,
      reponseId: json['reponse_id'] as String?,
      valeurSaisie: json['valeur_saisie'] as String?,
      isCorrect: json['is_correct'] as bool,
      pointsObtenus: (json['points_obtenus'] as num).toInt(),
      tempsReponseSec: (json['temps_reponse_sec'] as num).toInt(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$$UserAnswerModelImplToJson(
        _$UserAnswerModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'session_id': instance.sessionId,
      'question_id': instance.questionId,
      'reponse_id': instance.reponseId,
      'valeur_saisie': instance.valeurSaisie,
      'is_correct': instance.isCorrect,
      'points_obtenus': instance.pointsObtenus,
      'temps_reponse_sec': instance.tempsReponseSec,
      'metadata': instance.metadata,
      'created_at': instance.createdAt,
    };
