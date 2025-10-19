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
      typeQuestion: json['type_question'] as String,
      questionData: json['question_data'] as Map<String, dynamic>,
      points: (json['points'] as num).toInt(),
      tempsLimiteSec: (json['temps_limite_sec'] as num?)?.toInt(),
      hint: json['hint'] as String?,
      explanation: json['explanation'] as String?,
    );

Map<String, dynamic> _$$QuestionModelImplToJson(_$QuestionModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'quiz_id': instance.quizId,
      'ordre': instance.ordre,
      'type_question': instance.typeQuestion,
      'question_data': instance.questionData,
      'points': instance.points,
      'temps_limite_sec': instance.tempsLimiteSec,
      'hint': instance.hint,
      'explanation': instance.explanation,
    };
