import '../../../domain/entities/quiz_entity.dart';
import '../quiz_model.dart';

extension QuizModelMapper on QuizModel {
  QuizEntity toEntity() {
    return QuizEntity(
      id: id,
      domain: domain,
      titre: titre,
      description: description,
      niveauDifficulte: niveauDifficulte,
      versionApp: versionApp,
      scope: scope,
      mode: mode,
      collectionId: collectionId,
      nbQuestions: nbQuestions,
      tempsLimiteSec: tempsLimiteSec,
      scoreMinimumSuccess: scoreMinimumSuccess,
      isActive: isActive,
      isPublic: isPublic,
      totalAttempts: totalAttempts,
      averageScore: averageScore,
      createdAt: DateTime.parse(createdAt),
      updatedAt: updatedAt != null ? DateTime.parse(updatedAt!) : null,
    );
  }
}

extension QuizModelListMapper on List<QuizModel> {
  List<QuizEntity> toEntities() => map((m) => m.toEntity()).toList();
}
