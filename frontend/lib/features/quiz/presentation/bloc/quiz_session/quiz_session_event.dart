import 'package:equatable/equatable.dart';

/// Events pour QuizSessionBloc
abstract class QuizSessionEvent extends Equatable {
  const QuizSessionEvent();

  @override
  List<Object?> get props => [];
}

/// Démarrer une session de quiz
class StartQuizSessionEvent extends QuizSessionEvent {
  final String quizId;
  final String userId;

  const StartQuizSessionEvent({
    required this.quizId,
    required this.userId,
  });

  @override
  List<Object> get props => [quizId, userId];
}

/// Soumettre une réponse
class SubmitAnswerEvent extends QuizSessionEvent {
  final String questionId;
  final String answer;
  final int timeSpentSeconds;

  const SubmitAnswerEvent({
    required this.questionId,
    required this.answer,
    required this.timeSpentSeconds,
  });

  @override
  List<Object> get props => [questionId, answer, timeSpentSeconds];
}

/// Passer à la question suivante
class NextQuestionEvent extends QuizSessionEvent {
  const NextQuestionEvent();
}

/// Finaliser la session
class FinalizeQuizSessionEvent extends QuizSessionEvent {
  const FinalizeQuizSessionEvent();
}

/// Récupérer l'état de la session
class LoadSessionEvent extends QuizSessionEvent {
  final String sessionId;

  const LoadSessionEvent(this.sessionId);

  @override
  List<Object> get props => [sessionId];
}