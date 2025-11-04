import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_quiz_by_id.dart';
import '../../../domain/usecases/get_quiz_list.dart';
import '../../../domain/usecases/usecase.dart';
import 'quiz_list_event.dart';
import 'quiz_list_state.dart';

class QuizListBloc extends Bloc<QuizListEvent, QuizListState> {
  final GetQuizList getQuizList;
  final GetQuizById getQuizById;

  QuizListBloc({
    required this.getQuizList,
    required this.getQuizById,
  }) : super(const QuizListInitial()) {
    on<LoadQuizListEvent>(_onLoadQuizList);
    on<RefreshQuizListEvent>(_onRefreshQuizList);
    on<SelectQuizEvent>(_onSelectQuiz);
  }

  /// Charge la liste des quiz
  Future<void> _onLoadQuizList(
    LoadQuizListEvent event,
    Emitter<QuizListState> emit,
  ) async {
    emit(const QuizListLoading());

    final result = await getQuizList(NoParams());

    result.fold(
      (failure) => emit(QuizListError(failure.message)),
      (quizzes) {
        if (quizzes.isEmpty) {
          emit(const QuizListEmpty());
        } else {
          emit(QuizListLoaded(quizzes: quizzes));
        }
      },
    );
  }

  /// Rafraîchit la liste des quiz
  Future<void> _onRefreshQuizList(
    RefreshQuizListEvent event,
    Emitter<QuizListState> emit,
  ) async {
    // Garde l'état actuel pendant le refresh
    final currentState = state;

    final result = await getQuizList(NoParams());

    result.fold(
      (failure) {
        // En cas d'erreur, on garde l'état précédent
        if (currentState is QuizListLoaded) {
          // Optionnel : afficher un snackbar d'erreur
        } else {
          emit(QuizListError(failure.message));
        }
      },
      (quizzes) {
        if (quizzes.isEmpty) {
          emit(const QuizListEmpty());
        } else {
          emit(QuizListLoaded(quizzes: quizzes));
        }
      },
    );
  }

  /// Sélectionne un quiz
  Future<void> _onSelectQuiz(
    SelectQuizEvent event,
    Emitter<QuizListState> emit,
  ) async {
    if (state is! QuizListLoaded) return;

    final currentState = state as QuizListLoaded;

    final result = await getQuizById(GetQuizByIdParams(quizId: event.quizId));

    result.fold(
      (failure) => emit(QuizListError(failure.message)),
      (quiz) => emit(currentState.copyWith(selectedQuiz: quiz)),
    );
  }
}
