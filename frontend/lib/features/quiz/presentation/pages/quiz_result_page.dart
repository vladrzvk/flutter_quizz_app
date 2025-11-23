import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/session_entity.dart';
import '../bloc/quiz_session/quiz_session_bloc.dart';
import '../bloc/quiz_session/quiz_session_event.dart';
import '../bloc/quiz_session/quiz_session_state.dart';
import '../widgets/resultat_card.dart';

class QuizResultPage extends StatelessWidget {
  final String sessionId;

  const QuizResultPage({
    super.key,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<QuizSessionBloc>()..add(LoadSessionEvent(sessionId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Résultats'),
          automaticallyImplyLeading: false,
        ),
        body: BlocBuilder<QuizSessionBloc, QuizSessionState>(
          builder: (context, state) {
            if (state is QuizSessionLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is QuizSessionCompleted) {
              return _buildResultView(context, state);
            }

            if (state is QuizSessionError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(state.message),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/'),
                      child: const Text('Retour à l\'accueil'),
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildResultView(BuildContext context, QuizSessionCompleted state) {
    final session = state.session;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Emoji et message
          Center(
            child: Column(
              children: [
                // Text(
                //   session.resultEmoji,
                //   style: const TextStyle(fontSize: 80),
                // ),
                const SizedBox(height: 16),
                Text(
                  session.resultMessage,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Score principal
          ResultCard(
            title: 'Score Final',
            child: Column(
              children: [
                Text(
                  '${session.score}',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getScoreColor(session.calculatedPourcentage),
                      ),
                ),
                Text(
                  'sur ${session.scoreMax} points',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${session.calculatedPourcentage.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getScoreColor(session.calculatedPourcentage),
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Statistiques
          ResultCard(
            title: 'Statistiques',
            child: Column(
              children: [
                _buildStatRow(
                  context,
                  icon: Icons.quiz,
                  label: 'Questions',
                  value: '${state.questions.length}',
                ),
                const Divider(height: 24),
                _buildStatRow(
                  context,
                  icon: Icons.check_circle,
                  label: 'Bonnes réponses',
                  value: '${_countCorrectAnswers(state)}',
                  color: Colors.green,
                ),
                const Divider(height: 24),
                _buildStatRow(
                  context,
                  icon: Icons.cancel,
                  label: 'Mauvaises réponses',
                  value: '${_countIncorrectAnswers(state)}',
                  color: Colors.red,
                ),
                const Divider(height: 24),
                _buildStatRow(
                  context,
                  icon: Icons.timer,
                  label: 'Temps total',
                  value: session.duration.inMinutes > 0
                      ? '${session.duration.inMinutes} min'
                      : '${session.duration.inSeconds} s',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Réussite/Échec
          if (session.isPassed)
            ResultCard(
              title: 'Félicitations ! 🎉',
              color: Colors.green[50],
              child: Text(
                'Vous avez réussi ce quiz !',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.green[900],
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            ResultCard(
              title: 'Pas tout à fait... 💪',
              color: Colors.orange[50],
              child: Text(
                'Continuez à vous entraîner !',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.orange[900],
                ),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 32),

          // Boutons d'action
          ElevatedButton(
            onPressed: () => context.go('/'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Retour à l\'accueil'),
          ),

          const SizedBox(height: 12),

          OutlinedButton(
            onPressed: () {
              // TODO: Recommencer le quiz
              context.go('/');
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Recommencer'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color ?? Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }

  int _countCorrectAnswers(QuizSessionCompleted state) {
    return state.submittedAnswers.where((a) => a.isCorrect).length;
  }

  int _countIncorrectAnswers(QuizSessionCompleted state) {
    return state.submittedAnswers.where((a) => !a.isCorrect).length;
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }
}
