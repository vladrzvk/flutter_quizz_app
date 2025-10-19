import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../entities/answer_entity.dart';
import '../repositories/quiz_repository.dart';
import 'usecase.dart';

/// Use Case : Soumettre une réponse
class SubmitAnswer implements UseCase<AnswerEntity, SubmitAnswerParams> {
  final QuizRepository repository;

  SubmitAnswer(this.repository);

  @override
  Future<Either<Failure, AnswerEntity>> call(SubmitAnswerParams params) async {
    return await repository.submitAnswer(
      sessionId: params.sessionId,
      questionId: params.questionId,
      answer: params.answer,
      timeSpentSeconds: params.timeSpentSeconds,
    );
  }
}

/// Paramètres pour SubmitAnswer
class SubmitAnswerParams extends Equatable {
  final String sessionId;
  final String questionId;
  final String answer;
  final int timeSpentSeconds;

  const SubmitAnswerParams({
    required this.sessionId,
    required this.questionId,
    required this.answer,
    required this.timeSpentSeconds,
  });

  @override
  List<Object> get props => [sessionId, questionId, answer, timeSpentSeconds];
}