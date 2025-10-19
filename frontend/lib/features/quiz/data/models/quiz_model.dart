import 'package:freezed_annotation/freezed_annotation.dart';

part 'quiz_model.freezed.dart';
part 'quiz_model.g.dart';

@freezed
class QuizModel with _$QuizModel {
  const factory QuizModel({
    required String id,
    required String titre,
    String? description,
    @JsonKey(name: 'niveau_difficulte') required String niveauDifficulte,
    @JsonKey(name: 'version_app') required String versionApp,
    @JsonKey(name: 'region_scope') required String regionScope,
    required String mode,
    @JsonKey(name: 'nb_questions') required int nbQuestions,
    @JsonKey(name: 'temps_limite_sec') int? tempsLimiteSec,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _QuizModel;

  factory QuizModel.fromJson(Map<String, dynamic> json) =>
      _$QuizModelFromJson(json);
}