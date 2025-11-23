import '../../../domain/entities/question_entity.dart';
import '../question_model.dart';
import 'reponse_model_mapper.dart';

extension QuestionModelMapper on QuestionModel {
  QuestionEntity toEntity() {
    return QuestionEntity(
      id: id,
      quizId: quizId,
      ordre: ordre,
      category: category,
      subcategory: subcategory,
      typeQuestion: typeQuestion,
      questionData: questionData,
      mediaUrl: mediaUrl,
      targetId: targetId,
      points: points,
      tempsLimiteSec: tempsLimiteSec,
      hint: hint,
      explanation: explanation,
      metadata: metadata,
      totalAttempts: totalAttempts,
      correctAttempts: correctAttempts,
      createdAt: createdAt != null ? DateTime.parse(createdAt!) : null,
      updatedAt: updatedAt != null ? DateTime.parse(updatedAt!) : null,
      reponses: reponses?.toEntities(), // ✅ CRUCIAL
    );
  }
}

extension QuestionModelListMapper on List<QuestionModel> {
  List<QuestionEntity> toEntities() => map((m) => m.toEntity()).toList();
}
