import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/router/app_router.dart';
import '../bloc/quiz_list/quiz_list_bloc.dart';
import '../bloc/quiz_list/quiz_list_event.dart';
import '../bloc/quiz_list/quiz_list_state.dart';
import '../widgets/quiz_card.dart';

class QuizListPage extends StatelessWidget {
  const QuizListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<QuizListBloc>()..add(const LoadQuizListEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quiz Disponibles'),
          actions: [
            BlocBuilder<QuizListBloc, QuizListState>(
              builder: (context, state) {
                return IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    context.read<QuizListBloc>().add(const RefreshQuizListEvent());
                  },
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<QuizListBloc, QuizListState>(
          builder: (context, state) {
            if (state is QuizListLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is QuizListError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<QuizListBloc>().add(const LoadQuizListEvent());
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              );
            }

            if (state is QuizListEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun quiz disponible',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              );
            }

            if (state is QuizListLoaded) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<QuizListBloc>().add(const RefreshQuizListEvent());
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.quizzes.length,
                  itemBuilder: (context, index) {
                    final quiz = state.quizzes[index];
                    return QuizCard(
                      quiz: quiz,
                      onTap: () {
                        // Naviguer vers la page de session
                        context.pushNamed(
                          'quiz-session',
                          queryParameters: {
                            'quizId': quiz.id,
                            'title': quiz.titre,
                          },
                        );
                      },
                    );
                  },
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}