import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/answer_entity.dart';
import '../../domain/entities/question_entity.dart';
import '../../domain/entities/quiz_entity.dart';
import '../../domain/entities/session_entity.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../datasources/quiz_remote_datasource.dart';
import '../models/answer_submission.dart';
import '../models/mappers/mapper.dart';

/// Implémentation du Repository Quiz
/// Utilise le DataSource et convertit Models → Entities
class QuizRepositoryImpl implements QuizRepository {
  final QuizRemoteDataSource remoteDataSource;

  QuizRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<QuizEntity>>> getQuizzes() async {
    try {
      // 1. Récupérer les Models depuis le DataSource
      final quizModels = await remoteDataSource.getQuizzes();

      // 2. Convertir Models → Entities
      final quizEntities = quizModels.toEntities();

      // 3. Retourner le succès
      return Right(quizEntities);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on ConnectionException catch (e) {
      return Left(ConnectionFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erreur inattendue: $e'));
    }
  }

  @override
  Future<Either<Failure, QuizEntity>> getQuizById(String id) async {
    try {
      final quizModel = await remoteDataSource.getQuizById(id);
      final quizEntity = quizModel.toEntity();
      return Right(quizEntity);
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on ConnectionException catch (e) {
      return Left(ConnectionFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erreur inattendue: $e'));
    }
  }

  @override
  Future<Either<Failure, List<QuestionEntity>>> getQuizQuestions(
      String quizId,
      ) async {
    try {
      final questionModels = await remoteDataSource.getQuizQuestions(quizId);
      final questionEntities = questionModels.toEntities();
      return Right(questionEntities);
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on ConnectionException catch (e) {
      return Left(ConnectionFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erreur inattendue: $e'));
    }
  }

  @override
  Future<Either<Failure, SessionEntity>> startSession({
    required String quizId,
    required String userId,
  }) async {
    try {
      final sessionModel = await remoteDataSource.startSession(
        quizId: quizId,
        userId: userId,
      );
      final sessionEntity = sessionModel.toEntity();
      return Right(sessionEntity);
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on ConnectionException catch (e) {
      return Left(ConnectionFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erreur inattendue: $e'));
    }
  }

  @override
  Future<Either<Failure, AnswerEntity>> submitAnswer({
    required String sessionId,
    required String questionId,
    required String answer,
    required int timeSpentSeconds,
  }) async {
    try {
      // Créer le model de soumission
      final submission = AnswerSubmission(
        questionId: questionId,
        valeurSaisie: answer,
        tempsReponseSec: timeSpentSeconds,
      );

      // Soumettre la réponse
      final answerModel = await remoteDataSource.submitAnswer(
        sessionId: sessionId,
        answer: submission,
      );

      // Convertir en Entity
      final answerEntity = answerModel.toEntity();
      return Right(answerEntity);
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on ConnectionException catch (e) {
      return Left(ConnectionFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erreur inattendue: $e'));
    }
  }

  @override
  Future<Either<Failure, SessionEntity>> finalizeSession(
      String sessionId,
      ) async {
    try {
      final sessionModel = await remoteDataSource.finalizeSession(sessionId);
      final sessionEntity = sessionModel.toEntity();
      return Right(sessionEntity);
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on ConnectionException catch (e) {
      return Left(ConnectionFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erreur inattendue: $e'));
    }
  }

  @override
  Future<Either<Failure, SessionEntity>> getSession(String sessionId) async {
    try {
      final sessionModel = await remoteDataSource.getSession(sessionId);
      final sessionEntity = sessionModel.toEntity();
      return Right(sessionEntity);
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on ConnectionException catch (e) {
      return Left(ConnectionFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erreur inattendue: $e'));
    }
  }
}

