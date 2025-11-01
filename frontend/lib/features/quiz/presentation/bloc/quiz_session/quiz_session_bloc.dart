import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/answer_entity.dart';
import '../../../domain/entities/question_entity.dart';
import '../../../domain/usecases/finalize_session.dart';
import '../../../domain/usecases/get_quiz_questions.dart';
import '../../../domain/usecases/get_session.dart';
import '../../../domain/usecases/start_quiz_session.dart';
import '../../../domain/usecases/submit_answer.dart';
import 'quiz_session_event.dart';
import 'quiz_session_state.dart';

class QuizSessionBloc extends Bloc<QuizSessionEvent, QuizSessionState> {
  final GetQuizQuestions getQuizQuestions;
  final StartQuizSession startQuizSession;
  final SubmitAnswer submitAnswer;
  final FinalizeSession finalizeSession;
  final GetSession getSession;

  QuizSessionBloc({
    required this.getQuizQuestions,
    required this.startQuizSession,
    required this.submitAnswer,
    required this.finalizeSession,
    required this.getSession,
  }) : super(const QuizSessionInitial()) {
    on<StartQuizSessionEvent>(_onStartSession);
    on<SubmitAnswerEvent>(_onSubmitAnswer);
    on<NextQuestionEvent>(_onNextQuestion);
    on<FinalizeQuizSessionEvent>(_onFinalizeSession);
    on<LoadSessionEvent>(_onLoadSession);
  }

  /// Démarre une session de quiz
  Future<void> _onStartSession(
      StartQuizSessionEvent event,
      Emitter<QuizSessionState> emit,
      ) async {
    emit(const QuizSessionLoading());

    // 1. Récupérer les questions du quiz
    final questionsResult = await getQuizQuestions(
      GetQuizQuestionsParams(quizId: event.quizId),
    );

    await questionsResult.fold(
          (failure) async => emit(QuizSessionError(failure.message)),
          (questions) async {
        if (questions.isEmpty) {
          emit(const QuizSessionError('Ce quiz ne contient aucune question'));
          return;
        }

        // 2. Démarrer la session
        final sessionResult = await startQuizSession(
          StartQuizSessionParams(
            quizId: event.quizId,
            userId: event.userId,
          ),
        );

        sessionResult.fold(
              (failure) => emit(QuizSessionError(failure.message)),
              (session) => emit(
            QuizSessionInProgress(
              session: session,
              questions: questions,
              currentQuestionIndex: 0,
              submittedAnswers: const [],
            ),
          ),
        );
      },
    );
  }

  /// Soumet une réponse
  Future<void> _onSubmitAnswer(
      SubmitAnswerEvent event,
      Emitter<QuizSessionState> emit,
      ) async {
    if (state is! QuizSessionInProgress) return;

    final currentState = state as QuizSessionInProgress;
    final currentQuestion = currentState.questions[currentState.currentQuestionIndex];

    // ✅ Déterminer si c'est QCM/Vrai-Faux ou Saisie
    String? reponseId;
    String? valeurSaisie;

    if (currentQuestion.isQcm || currentQuestion.isVraiFaux) {
      reponseId = event.answer.isEmpty ? null : event.answer;
      valeurSaisie = null;
    } else if (currentQuestion.isSaisieTexte) {
      // Pour saisie texte : envoyer le texte
      reponseId = null;
      valeurSaisie = event.answer;
    }

    final result = await submitAnswer(
      SubmitAnswerParams(
        sessionId: currentState.session.id,
        questionId: event.questionId,
        reponseId: reponseId,
        valeurSaisie: valeurSaisie,
        timeSpentSeconds: event.timeSpentSeconds,
      ),
    );

    result.fold(
          (failure) => emit(QuizSessionError(failure.message)),
          (answer) {
        final updatedAnswers = List<AnswerEntity>.from(currentState.submittedAnswers)
          ..add(answer);

        // Afficher le feedback de la réponse
        emit(QuizAnswerSubmitted(
          session: currentState.session,
          questions: currentState.questions,
          currentQuestionIndex: currentState.currentQuestionIndex,
          submittedAnswers: updatedAnswers,
          lastAnswer: answer,
        ));
      },
    );
  }

  /// Passe à la question suivante
  void _onNextQuestion(
      NextQuestionEvent event,
      Emitter<QuizSessionState> emit,
      ) {
    if (state is! QuizAnswerSubmitted) return;

    final currentState = state as QuizAnswerSubmitted;

    // Si c'était la dernière question, finaliser automatiquement
    if (currentState.currentQuestionIndex >= currentState.questions.length - 1) {
      add(const FinalizeQuizSessionEvent());
    } else {
      // Sinon, passer à la question suivante
      emit(QuizSessionInProgress(
        session: currentState.session,
        questions: currentState.questions,
        currentQuestionIndex: currentState.currentQuestionIndex + 1,
        submittedAnswers: currentState.submittedAnswers,
      ));
    }
  }

  /// Finalise la session
  Future<void> _onFinalizeSession(
      FinalizeQuizSessionEvent event,
      Emitter<QuizSessionState> emit,
      ) async {
    // Récupérer l'état actuel avec les bonnes propriétés
    String sessionId;
    List<QuestionEntity> questions;
    List<AnswerEntity> submittedAnswers;

    if (state is QuizAnswerSubmitted) {
      final currentState = state as QuizAnswerSubmitted;
      sessionId = currentState.session.id;
      questions = currentState.questions;
      submittedAnswers = currentState.submittedAnswers;
    } else if (state is QuizSessionInProgress) {
      final currentState = state as QuizSessionInProgress;
      sessionId = currentState.session.id;
      questions = currentState.questions;
      submittedAnswers = currentState.submittedAnswers;
    } else {
      emit(const QuizSessionError('Impossible de finaliser la session'));
      return;
    }

    emit(const QuizSessionLoading());

    final result = await finalizeSession(
      FinalizeSessionParams(sessionId: sessionId),
    );

    result.fold(
          (failure) => emit(QuizSessionError(failure.message)),
          (finalSession) => emit(
        QuizSessionCompleted(
          session: finalSession,
          questions: questions,
          submittedAnswers: submittedAnswers,
        ),
      ),
    );
  }

  /// Charge une session existante
  Future<void> _onLoadSession(
      LoadSessionEvent event,
      Emitter<QuizSessionState> emit,
      ) async {
    emit(const QuizSessionLoading());

    final result = await getSession(
      GetSessionParams(sessionId: event.sessionId),
    );

    result.fold(
          (failure) => emit(QuizSessionError(failure.message)),
          (session) {
        // TODO: Charger aussi les questions et réponses
        emit(const QuizSessionError('Fonctionnalité pas encore implémentée'));
      },
    );
  }
}