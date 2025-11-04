import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../entities/quiz_entity.dart';
import '../repositories/quiz_repository.dart';
import 'usecase.dart';

/// Use Case : Récupérer un quiz par son ID
class GetQuizById implements UseCase<QuizEntity, GetQuizByIdParams> {
  final QuizRepository repository;

  GetQuizById(this.repository);

  @override
  Future<Either<Failure, QuizEntity>> call(GetQuizByIdParams params) async {
    return await repository.getQuizById(params.quizId);
  }
}

/// Paramètres pour GetQuizById
class GetQuizByIdParams extends Equatable {
  final String quizId;

  const GetQuizByIdParams({required this.quizId});

  @override
  List<Object> get props => [quizId];
}
