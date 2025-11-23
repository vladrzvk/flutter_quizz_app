import 'package:equatable/equatable.dart';
import '../../../domain/entities/answer_entity.dart';
import '../../../domain/entities/question_entity.dart';
import '../../../domain/entities/session_entity.dart';

/// States pour QuizSessionBloc
abstract class QuizSessionState extends Equatable {
  const QuizSessionState();

  @override
  List<Object?> get props => [];
}

/// État initial
class QuizSessionInitial extends QuizSessionState {
  const QuizSessionInitial();
}

/// Chargement en cours
class QuizSessionLoading extends QuizSessionState {
  const QuizSessionLoading();
}

/// Session démarrée, afficher la question
class QuizSessionInProgress extends QuizSessionState {
  final SessionEntity session;
  final List<QuestionEntity> questions;
  final int currentQuestionIndex;
  final List<AnswerEntity> submittedAnswers;

  const QuizSessionInProgress({
    required this.session,
    required this.questions,
    required this.currentQuestionIndex,
    required this.submittedAnswers,
  });

  QuestionEntity get currentQuestion => questions[currentQuestionIndex];
  bool get isLastQuestion => currentQuestionIndex >= questions.length - 1;
  int get totalQuestions => questions.length;
  int get answeredQuestions => submittedAnswers.length;
  int get totalScore {
    return submittedAnswers.fold<int>(
      0,
      (sum, answer) => sum + answer.pointsObtenus,
    );
  }

  @override
  List<Object> get props => [
        session,
        questions,
        currentQuestionIndex,
        submittedAnswers,
      ];

  QuizSessionInProgress copyWith({
    SessionEntity? session,
    List<QuestionEntity>? questions,
    int? currentQuestionIndex,
    List<AnswerEntity>? submittedAnswers,
  }) {
    return QuizSessionInProgress(
      session: session ?? this.session,
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      submittedAnswers: submittedAnswers ?? this.submittedAnswers,
    );
  }
}

/// Réponse soumise, afficher le feedback
class QuizAnswerSubmitted extends QuizSessionState {
  final SessionEntity session;
  final List<QuestionEntity> questions;
  final int currentQuestionIndex;
  final List<AnswerEntity> submittedAnswers;
  final AnswerEntity lastAnswer;

  const QuizAnswerSubmitted({
    required this.session,
    required this.questions,
    required this.currentQuestionIndex,
    required this.submittedAnswers,
    required this.lastAnswer,
  });

  int get totalScore {
    return submittedAnswers.fold<int>(
      0,
      (sum, answer) => sum + answer.pointsObtenus,
    );
  }

  @override
  List<Object> get props => [
        session,
        questions,
        currentQuestionIndex,
        submittedAnswers,
        lastAnswer,
      ];
}

/// Session terminée, afficher les résultats
class QuizSessionCompleted extends QuizSessionState {
  final SessionEntity session;
  final List<QuestionEntity> questions;
  final List<AnswerEntity> submittedAnswers;

  const QuizSessionCompleted({
    required this.session,
    required this.questions,
    required this.submittedAnswers,
  });

  @override
  List<Object> get props => [session, questions, submittedAnswers];
}

/// Erreur
class QuizSessionError extends QuizSessionState {
  final String message;

  const QuizSessionError(this.message);

  @override
  List<Object> get props => [message];
}
