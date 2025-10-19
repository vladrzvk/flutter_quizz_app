import 'package:equatable/equatable.dart';

/// Entity représentant une Question dans le domaine métier
class QuestionEntity extends Equatable {
  final String id;
  final String quizId;
  final int ordre;
  final String typeQuestion;
  final String questionText;
  final List<String> options;
  final int points;
  final int? tempsLimiteSec;
  final String? hint;
  final String? explanation;

  const QuestionEntity({
    required this.id,
    required this.quizId,
    required this.ordre,
    required this.typeQuestion,
    required this.questionText,
    required this.options,
    required this.points,
    this.tempsLimiteSec,
    this.hint,
    this.explanation,
  });

  @override
  List<Object?> get props => [
    id,
    quizId,
    ordre,
    typeQuestion,
    questionText,
    options,
    points,
    tempsLimiteSec,
    hint,
    explanation,
  ];

  // 🎯 MÉTHODES MÉTIER

  /// Numéro de la question (commence à 1)
  int get questionNumber => ordre + 1;

  /// Vérifie si la question a des options de réponse
  bool get hasOptions => options.isNotEmpty;

  /// Vérifie si la question a un indice
  bool get hasHint => hint != null && hint!.isNotEmpty;

  /// Vérifie si la question a une explication
  bool get hasExplanation => explanation != null && explanation!.isNotEmpty;

  /// Vérifie si la question a une limite de temps
  bool get hasTimeLimit => tempsLimiteSec != null && tempsLimiteSec! > 0;

  /// Durée en secondes (ou valeur par défaut)
  int get durationInSeconds => tempsLimiteSec ?? 30;

  /// Vérifie si c'est une question à choix multiple
  bool get isMultipleChoice => typeQuestion == 'choix_multiple';

  /// Vérifie si la réponse donnée est valide
  bool isValidAnswer(String? answer) {
    if (answer == null || answer.isEmpty) return false;
    if (isMultipleChoice) {
      return options.contains(answer);
    }
    return true;
  }
}