import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/quiz/presentation/pages/quiz_list_page.dart';
import '../../features/quiz/presentation/pages/quiz_result_page.dart';
import '../../features/quiz/presentation/pages/quiz_session_page.dart';

class AppRouter {
  static const String home = '/';
  static const String quizSession = '/quiz-session';
  static const String quizResult = '/quiz-result';

  static final GoRouter router = GoRouter(
    initialLocation: home,
    routes: [
      // Page liste des quiz
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const QuizListPage(),
      ),

      // Page session de quiz
      GoRoute(
        path: quizSession,
        name: 'quiz-session',
        builder: (context, state) {
          final quizId = state.uri.queryParameters['quizId'] ?? '';
          final quizTitle = state.uri.queryParameters['title'] ?? 'Quiz';

          return QuizSessionPage(
            quizId: quizId,
            quizTitle: quizTitle,
          );
        },
      ),

      // Page résultats
      GoRoute(
        path: quizResult,
        name: 'quiz-result',
        builder: (context, state) {
          final sessionId = state.uri.queryParameters['sessionId'] ?? '';
          return QuizResultPage(sessionId: sessionId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Erreur')),
      body: Center(
        child: Text('Page non trouvée: ${state.uri}'),
      ),
    ),
  );
}
