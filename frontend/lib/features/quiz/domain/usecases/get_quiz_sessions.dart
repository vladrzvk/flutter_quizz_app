import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../entities/session_entity.dart';
import '../repositories/quiz_repository.dart';
import 'usecase.dart';

/// Use Case : Démarrer une session de quiz
class StartQuizSession implements UseCase<SessionEntity, StartQuizSessionParams> {
  final QuizRepository repository;

  StartQuizSession(this.repository);

  @override
  Future<Either<Failure, SessionEntity>> call(StartQuizSessionParams params) async {
    return await repository.startSession(
      quizId: params.quizId,
      userId: params.userId,
    );
  }
}

/// Paramètres pour StartQuizSession
class StartQuizSessionParams extends Equatable {
  final String quizId;
  final String userId;

  const StartQuizSessionParams({
    required this.quizId,
    required this.userId,
  });

  @override
  List<Object> get props => [quizId, userId];
}