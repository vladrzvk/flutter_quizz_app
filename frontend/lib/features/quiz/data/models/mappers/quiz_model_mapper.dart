import '../../../domain/entities/quiz_entity.dart';
import '../quiz_model.dart';

/// Extension pour convertir QuizModel → QuizEntity
extension QuizModelMapper on QuizModel {
  /// Convertit le Model (JSON) en Entity (Domain)
  QuizEntity toEntity() {
    return QuizEntity(
      id: id,
      titre: titre,
      description: description,
      niveauDifficulte: niveauDifficulte,
      versionApp: versionApp,
      regionScope: regionScope,
      mode: mode,
      nbQuestions: nbQuestions,
      tempsLimiteSec: tempsLimiteSec,
      isActive: isActive,
      createdAt: DateTime.parse(createdAt),
    );
  }
}

/// Extension pour convertir QuizEntity → QuizModel
extension QuizEntityMapper on QuizEntity {
  /// Convertit l'Entity (Domain) en Model (JSON)
  /// Utile si on doit envoyer des données au backend
  QuizModel toModel() {
    return QuizModel(
      id: id,
      titre: titre,
      description: description,
      niveauDifficulte: niveauDifficulte,
      versionApp: versionApp,
      regionScope: regionScope,
      mode: mode,
      nbQuestions: nbQuestions,
      tempsLimiteSec: tempsLimiteSec,
      isActive: isActive,
      createdAt: createdAt.toIso8601String(),
    );
  }
}

/// Extension pour convertir une liste de Models en liste d'Entities
extension QuizModelListMapper on List<QuizModel> {
  List<QuizEntity> toEntities() {
    return map((model) => model.toEntity()).toList();
  }
}