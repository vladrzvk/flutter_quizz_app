import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../entities/session_entity.dart';
import '../repositories/quiz_repository.dart';
import 'usecase.dart';

/// Use Case : Récupérer une session par son ID
class GetSession implements UseCase<SessionEntity, GetSessionParams> {
  final QuizRepository repository;

  GetSession(this.repository);

  @override
  Future<Either<Failure, SessionEntity>> call(GetSessionParams params) async {
    return await repository.getSession(params.sessionId);
  }
}

/// Paramètres pour GetSession
class GetSessionParams extends Equatable {
  final String sessionId;

  const GetSessionParams({required this.sessionId});

  @override
  List<Object> get props => [sessionId];
}
