// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$QuestionModelImpl _$$QuestionModelImplFromJson(Map<String, dynamic> json) =>
    _$QuestionModelImpl(
      id: json['id'] as String,
      quizId: json['quiz_id'] as String,
      ordre: (json['ordre'] as num).toInt(),
      category: json['category'] as String?,
      subcategory: json['subcategory'] as String?,
      typeQuestion: json['type_question'] as String,
      questionData: json['question_data'] as Map<String, dynamic>,
      mediaUrl: json['media_url'] as String?,
      targetId: json['target_id'] as String?,
      points: (json['points'] as num).toInt(),
      tempsLimiteSec: (json['temps_limite_sec'] as num?)?.toInt(),
      hint: json['hint'] as String?,
      explanation: json['explanation'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      totalAttempts: (json['total_attempts'] as num?)?.toInt(),
      correctAttempts: (json['correct_attempts'] as num?)?.toInt(),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      reponses: (json['reponses'] as List<dynamic>?)
          ?.map((e) => ReponseModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$QuestionModelImplToJson(_$QuestionModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'quiz_id': instance.quizId,
      'ordre': instance.ordre,
      'category': instance.category,
      'subcategory': instance.subcategory,
      'type_question': instance.typeQuestion,
      'question_data': instance.questionData,
      'media_url': instance.mediaUrl,
      'target_id': instance.targetId,
      'points': instance.points,
      'temps_limite_sec': instance.tempsLimiteSec,
      'hint': instance.hint,
      'explanation': instance.explanation,
      'metadata': instance.metadata,
      'total_attempts': instance.totalAttempts,
      'correct_attempts': instance.correctAttempts,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'reponses': instance.reponses,
    };
