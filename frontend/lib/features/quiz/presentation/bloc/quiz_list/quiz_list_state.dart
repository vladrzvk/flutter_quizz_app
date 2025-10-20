import 'package:equatable/equatable.dart';
import '../../../domain/entities/quiz_entity.dart';

/// States pour QuizListBloc
abstract class QuizListState extends Equatable {
  const QuizListState();

  @override
  List<Object?> get props => [];
}

/// État initial
class QuizListInitial extends QuizListState {
  const QuizListInitial();
}

/// Chargement en cours
class QuizListLoading extends QuizListState {
  const QuizListLoading();
}

/// Liste chargée avec succès
class QuizListLoaded extends QuizListState {
  final List<QuizEntity> quizzes;
  final QuizEntity? selectedQuiz;

  const QuizListLoaded({
    required this.quizzes,
    this.selectedQuiz,
  });

  @override
  List<Object?> get props => [quizzes, selectedQuiz];

  QuizListLoaded copyWith({
    List<QuizEntity>? quizzes,
    QuizEntity? selectedQuiz,
  }) {
    return QuizListLoaded(
      quizzes: quizzes ?? this.quizzes,
      selectedQuiz: selectedQuiz ?? this.selectedQuiz,
    );
  }
}

/// Erreur
class QuizListError extends QuizListState {
  final String message;

  const QuizListError(this.message);

  @override
  List<Object> get props => [message];
}

/// Liste vide
class QuizListEmpty extends QuizListState {
  const QuizListEmpty();
}