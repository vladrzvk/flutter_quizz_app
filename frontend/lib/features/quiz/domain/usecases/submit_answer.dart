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

  @override  // ✅ Ajouter @override
  Future<Either<Failure, AnswerEntity>> call(SubmitAnswerParams params) {
    return repository.submitAnswer(
      sessionId: params.sessionId,
      questionId: params.questionId,
      reponseId: params.reponseId,
      valeurSaisie: params.valeurSaisie,
      timeSpentSeconds: params.timeSpentSeconds,
    );
  }
}

/// Paramètres pour SubmitAnswer
class SubmitAnswerParams extends Equatable {
  final String sessionId;
  final String questionId;
  final String? reponseId;
  final String? valeurSaisie;
  final int timeSpentSeconds;

  const SubmitAnswerParams({
    required this.sessionId,
    required this.questionId,
    this.reponseId,
    this.valeurSaisie,
    required this.timeSpentSeconds,
  });

  @override
  List<Object?> get props => [  // ✅ Object? pour accepter les nulls
    sessionId,
    questionId,
    reponseId,      // ✅ Sans le ?
    valeurSaisie,   // ✅ Sans le ,
    timeSpentSeconds,
  ];
}