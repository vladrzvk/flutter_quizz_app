import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../entities/question_entity.dart';
import '../repositories/quiz_repository.dart';
import 'usecase.dart';

/// Use Case : Récupérer les questions d'un quiz
class GetQuizQuestions implements UseCase<List<QuestionEntity>, GetQuizQuestionsParams> {
  final QuizRepository repository;

  GetQuizQuestions(this.repository);

  @override
  Future<Either<Failure, List<QuestionEntity>>> call(GetQuizQuestionsParams params) async {
    return await repository.getQuizQuestions(params.quizId);
  }
}

/// Paramètres pour GetQuizQuestions
class GetQuizQuestionsParams extends Equatable {
  final String quizId;

  const GetQuizQuestionsParams({required this.quizId});

  @override
  List<Object> get props => [quizId];
}