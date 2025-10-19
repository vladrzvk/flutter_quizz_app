// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SessionModelImpl _$$SessionModelImplFromJson(Map<String, dynamic> json) =>
    _$SessionModelImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      quizId: json['quiz_id'] as String,
      score: (json['score'] as num).toInt(),
      scoreMax: (json['score_max'] as num).toInt(),
      pourcentage: (json['pourcentage'] as num?)?.toDouble(),
      tempsTotalSec: (json['temps_total_sec'] as num?)?.toInt(),
      status: json['status'] as String,
      dateDebut: json['date_debut'] as String,
      dateFin: json['date_fin'] as String?,
    );

Map<String, dynamic> _$$SessionModelImplToJson(_$SessionModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'quiz_id': instance.quizId,
      'score': instance.score,
      'score_max': instance.scoreMax,
      'pourcentage': instance.pourcentage,
      'temps_total_sec': instance.tempsTotalSec,
      'status': instance.status,
      'date_debut': instance.dateDebut,
      'date_fin': instance.dateFin,
    };
