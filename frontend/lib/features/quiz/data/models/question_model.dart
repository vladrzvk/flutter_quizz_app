import 'package:freezed_annotation/freezed_annotation.dart';

part 'question_model.freezed.dart';
part 'question_model.g.dart';

@freezed
class QuestionModel with _$QuestionModel {
  const factory QuestionModel({
    required String id,
    @JsonKey(name: 'quiz_id') required String quizId,
    required int ordre,
    @JsonKey(name: 'type_question') required String typeQuestion,
    @JsonKey(name: 'question_data') required Map<String, dynamic> questionData,
    required int points,
    @JsonKey(name: 'temps_limite_sec') int? tempsLimiteSec,
    String? hint,
    String? explanation,
  }) = _QuestionModel;

  factory QuestionModel.fromJson(Map<String, dynamic> json) =>
      _$QuestionModelFromJson(json);
}