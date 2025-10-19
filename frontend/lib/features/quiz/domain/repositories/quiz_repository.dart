import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/quiz_entity.dart';
import '../entities/question_entity.dart';
import '../entities/session_entity.dart';
import '../entities/answer_entity.dart';

/// Interface du Repository Quiz
/// Définit le contrat que doit respecter l'implémentation
abstract class QuizRepository {
  /// Récupère la liste de tous les quiz disponibles
  ///
  /// Returns:
  /// - Right(List<QuizEntity>) en cas de succès
  /// - Left(Failure) en cas d'erreur
  Future<Either<Failure, List<QuizEntity>>> getQuizzes();

  /// Récupère un quiz spécifique par son ID
  ///
  /// Parameters:
  /// - [id] : ID du quiz
  ///
  /// Returns:
  /// - Right(QuizEntity) en cas de succès
  /// - Left(Failure) en cas d'erreur (NotFoundFailure si introuvable)
  Future<Either<Failure, QuizEntity>> getQuizById(String id);

  /// Récupère toutes les questions d'un quiz
  ///
  /// Parameters:
  /// - [quizId] : ID du quiz
  ///
  /// Returns:
  /// - Right(List<QuestionEntity>) en cas de succès
  /// - Left(Failure) en cas d'erreur
  Future<Either<Failure, List<QuestionEntity>>> getQuizQuestions(String quizId);

  /// Démarre une nouvelle session de quiz
  ///
  /// Parameters:
  /// - [quizId] : ID du quiz à jouer
  /// - [userId] : ID de l'utilisateur
  ///
  /// Returns:
  /// - Right(SessionEntity) en cas de succès
  /// - Left(Failure) en cas d'erreur
  Future<Either<Failure, SessionEntity>> startSession({
    required String quizId,
    required String userId,
  });

  /// Soumet une réponse à une question
  ///
  /// Parameters:
  /// - [sessionId] : ID de la session en cours
  /// - [questionId] : ID de la question
  /// - [answer] : Réponse de l'utilisateur
  /// - [timeSpentSeconds] : Temps passé sur la question (en secondes)
  ///
  /// Returns:
  /// - Right(AnswerEntity) avec le résultat de la réponse
  /// - Left(Failure) en cas d'erreur
  Future<Either<Failure, AnswerEntity>> submitAnswer({
    required String sessionId,
    required String questionId,
    required String answer,
    required int timeSpentSeconds,
  });

  /// Finalise une session de quiz
  ///
  /// Parameters:
  /// - [sessionId] : ID de la session à finaliser
  ///
  /// Returns:
  /// - Right(SessionEntity) avec le résultat final
  /// - Left(Failure) en cas d'erreur
  Future<Either<Failure, SessionEntity>> finalizeSession(String sessionId);

  /// Récupère les détails d'une session
  ///
  /// Parameters:
  /// - [sessionId] : ID de la session
  ///
  /// Returns:
  /// - Right(SessionEntity) en cas de succès
  /// - Left(Failure) en cas d'erreur
  Future<Either<Failure, SessionEntity>> getSession(String sessionId);
}