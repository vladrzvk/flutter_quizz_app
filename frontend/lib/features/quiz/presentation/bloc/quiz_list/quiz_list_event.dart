import 'package:equatable/equatable.dart';

/// Events pour QuizListBloc
abstract class QuizListEvent extends Equatable {
  const QuizListEvent();

  @override
  List<Object?> get props => [];
}

/// Charger la liste des quiz
class LoadQuizListEvent extends QuizListEvent {
  const LoadQuizListEvent();
}

/// Rafraîchir la liste des quiz
class RefreshQuizListEvent extends QuizListEvent {
  const RefreshQuizListEvent();
}

/// Sélectionner un quiz
class SelectQuizEvent extends QuizListEvent {
  final String quizId;

  const SelectQuizEvent(this.quizId);

  @override
  List<Object> get props => [quizId];
}