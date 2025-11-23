import 'package:freezed_annotation/freezed_annotation.dart';
import 'reponse_model.dart';

part 'question_model.freezed.dart';
part 'question_model.g.dart';

@freezed
class QuestionModel with _$QuestionModel {
  const factory QuestionModel({
    required String id,
    @JsonKey(name: 'quiz_id') required String quizId,
    required int ordre,

    // ✅ NOUVEAU - Catégorisation
    String? category,
    String? subcategory,
    @JsonKey(name: 'type_question') required String typeQuestion,
    @JsonKey(name: 'question_data') required Map<String, dynamic> questionData,

    // ✅ NOUVEAU - Médias
    @JsonKey(name: 'media_url') String? mediaUrl,
    @JsonKey(name: 'target_id') String? targetId,
    required int points,
    @JsonKey(name: 'temps_limite_sec') int? tempsLimiteSec,
    String? hint,
    String? explanation,

    // ✅ NOUVEAU - Métadonnées & Stats
    Map<String, dynamic>? metadata,
    @JsonKey(name: 'total_attempts') int? totalAttempts,
    @JsonKey(name: 'correct_attempts') int? correctAttempts,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,

    // ✅ CRUCIAL - Réponses incluses dans GET questions
    List<ReponseModel>? reponses,
  }) = _QuestionModel;

  factory QuestionModel.fromJson(Map<String, dynamic> json) =>
      _$QuestionModelFromJson(json);
}
