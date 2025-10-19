import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../entities/session_entity.dart';
import '../repositories/quiz_repository.dart';
import 'usecase.dart';

/// Use Case : Finaliser une session de quiz
class FinalizeSession implements UseCase<SessionEntity, FinalizeSessionParams> {
  final QuizRepository repository;

  FinalizeSession(this.repository);

  @override
  Future<Either<Failure, SessionEntity>> call(FinalizeSessionParams params) async {
    return await repository.finalizeSession(params.sessionId);
  }
}

/// Paramètres pour FinalizeSession
class FinalizeSessionParams extends Equatable {
  final String sessionId;

  const FinalizeSessionParams({required this.sessionId});

  @override
  List<Object> get props => [sessionId];
}
