import '../../../domain/entities/question_entity.dart';
import '../question_model.dart';

/// Extension pour convertir QuestionModel → QuestionEntity
extension QuestionModelMapper on QuestionModel {
  /// Convertit le Model (JSON) en Entity (Domain)
  QuestionEntity toEntity() {
    return QuestionEntity(
      id: id,
      quizId: quizId,
      ordre: ordre,
      typeQuestion: typeQuestion,
      questionText: _extractQuestionText(),
      options: _extractOptions(),
      points: points,
      tempsLimiteSec: tempsLimiteSec,
      hint: hint,
      explanation: explanation,
    );
  }

  /// Extrait le texte de la question depuis question_data
  String _extractQuestionText() {
    return questionData['text'] as String? ?? '';
  }

  /// Extrait les options de réponse depuis question_data
  List<String> _extractOptions() {
    final opts = questionData['options'];
    if (opts is List) {
      return opts.cast<String>();
    }
    return [];
  }
}

/// Extension pour convertir QuestionEntity → QuestionModel
extension QuestionEntityMapper on QuestionEntity {
  /// Convertit l'Entity (Domain) en Model (JSON)
  QuestionModel toModel() {
    return QuestionModel(
      id: id,
      quizId: quizId,
      ordre: ordre,
      typeQuestion: typeQuestion,
      questionData: {
        'text': questionText,
        'options': options,
      },
      points: points,
      tempsLimiteSec: tempsLimiteSec,
      hint: hint,
      explanation: explanation,
    );
  }
}

/// Extension pour convertir une liste de Models en liste d'Entities
extension QuestionModelListMapper on List<QuestionModel> {
  List<QuestionEntity> toEntities() {
    return map((model) => model.toEntity()).toList();
  }
}