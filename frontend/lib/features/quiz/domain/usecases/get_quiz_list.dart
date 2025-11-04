import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/quiz_entity.dart';
import '../repositories/quiz_repository.dart';
import 'usecase.dart';

/// Use Case : Récupérer la liste de tous les quiz
class GetQuizList implements UseCase<List<QuizEntity>, NoParams> {
  final QuizRepository repository;

  GetQuizList(this.repository);

  @override
  Future<Either<Failure, List<QuizEntity>>> call(NoParams params) async {
    return await repository.getQuizzes();
  }
}
