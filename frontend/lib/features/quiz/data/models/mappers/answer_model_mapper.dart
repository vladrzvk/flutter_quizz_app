import '../../../domain/entities/answer_entity.dart';
import '../answer_submission.dart';

/// Extension pour convertir UserAnswerModel → AnswerEntity
extension UserAnswerModelMapper on UserAnswerModel {
  /// Convertit le Model (JSON) en Entity (Domain)
  AnswerEntity toEntity() {
    return AnswerEntity(
      id: id,
      sessionId: sessionId,
      questionId: questionId,
      reponseId: reponseId,
      valeurSaisie: valeurSaisie,
      isCorrect: isCorrect,
      pointsObtenus: pointsObtenus,
      tempsReponseSec: tempsReponseSec,
      createdAt:
          createdAt != null ? DateTime.parse(createdAt!) : DateTime.now(),
    );
  }
}

/// Extension pour convertir AnswerEntity → UserAnswerModel
extension AnswerEntityMapper on AnswerEntity {
  /// Convertit l'Entity (Domain) en Model (JSON)
  UserAnswerModel toModel() {
    return UserAnswerModel(
      id: id,
      sessionId: sessionId,
      questionId: questionId,
      reponseId: reponseId,
      valeurSaisie: valeurSaisie,
      isCorrect: isCorrect,
      pointsObtenus: pointsObtenus,
      tempsReponseSec: tempsReponseSec,
      createdAt: createdAt.toIso8601String(),
    );
  }
}

/// Extension pour convertir une liste de Models en liste d'Entities
extension UserAnswerModelListMapper on List<UserAnswerModel> {
  List<AnswerEntity> toEntities() {
    return map((model) => model.toEntity()).toList();
  }
}
