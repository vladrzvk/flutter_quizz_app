import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/quiz_session/quiz_session_bloc.dart';
import '../bloc/quiz_session/quiz_session_event.dart';
import '../bloc/quiz_session/quiz_session_state.dart';
import '../widgets/answer_button.dart';
import '../widgets/question_card.dart';

class QuizSessionPage extends StatefulWidget {
  final String quizId;
  final String quizTitle;

  const QuizSessionPage({
    super.key,
    required this.quizId,
    required this.quizTitle,
  });

  @override
  State<QuizSessionPage> createState() => _QuizSessionPageState();
}

class _QuizSessionPageState extends State<QuizSessionPage> {
  final Stopwatch _stopwatch = Stopwatch();
  String? _selectedAnswer;

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<QuizSessionBloc>()
        ..add(StartQuizSessionEvent(
          quizId: widget.quizId,
          userId: const Uuid().v4(), // Générer un user ID temporaire
        )),
      child: BlocConsumer<QuizSessionBloc, QuizSessionState>(
        listener: (context, state) {
          // Quand la session est terminée, naviguer vers les résultats
          if (state is QuizSessionCompleted) {
            context.pushReplacementNamed(
              'quiz-result',
              queryParameters: {
                'sessionId': state.session.id,
              },
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.quizTitle),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  _showQuitDialog(context);
                },
              ),
            ),
            body: _buildBody(context, state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, QuizSessionState state) {
    if (state is QuizSessionLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement du quiz...'),
          ],
        ),
      );
    }

    if (state is QuizSessionError) {
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
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Retour'),
            ),
          ],
        ),
      );
    }

    if (state is QuizSessionInProgress) {
      return _buildQuestionView(context, state);
    }

    if (state is QuizAnswerSubmitted) {
      return _buildAnswerFeedbackView(context, state);
    }

    return const SizedBox.shrink();
  }

  Widget _buildQuestionView(
      BuildContext context,
      QuizSessionInProgress state,
      ) {
    final question = state.currentQuestion;

    return Column(
      children: [
        // Progress bar
        LinearProgressIndicator(
          value: (state.currentQuestionIndex + 1) / state.totalQuestions,
          backgroundColor: Colors.grey[200],
          minHeight: 8,
        ),

        // Contenu
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info progress
                Text(
                  'Question ${state.currentQuestionIndex + 1} / ${state.totalQuestions}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),

                // Question Card
                QuestionCard(question: question),
                const SizedBox(height: 24),

                // Options de réponse
                ...question.options.map((option) {
                  return AnswerButton(
                    text: option,
                    isSelected: _selectedAnswer == option,
                    onTap: () {
                      setState(() {
                        _selectedAnswer = option;
                      });
                    },
                  );
                }),

                const SizedBox(height: 24),

                // Bouton valider
                ElevatedButton(
                  onPressed: _selectedAnswer == null
                      ? null
                      : () => _submitAnswer(context, state),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Valider'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerFeedbackView(
      BuildContext context,
      QuizAnswerSubmitted state,
      ) {
    final answer = state.lastAnswer;
    final isLastQuestion = state.currentQuestionIndex >= state.questions.length - 1;

    return Column(
      children: [
        // Progress bar
        LinearProgressIndicator(
          value: (state.currentQuestionIndex + 1) / state.questions.length,
          backgroundColor: Colors.grey[200],
          minHeight: 8,
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Feedback card
                Card(
                  color: answer.isCorrect ? Colors.green[50] : Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          answer.isCorrect ? Icons.check_circle : Icons.cancel,
                          size: 64,
                          color: answer.isCorrect ? Colors.green : Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          answer.feedbackMessage,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: answer.isCorrect ? Colors.green[900] : Colors.red[900],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${answer.pointsObtenus} points',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (answer.speedBadge != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            answer.speedBadge!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Score actuel
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              'Score',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${state.session.score}',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey[300],
                        ),
                        Column(
                          children: [
                            Text(
                              'Questions',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${state.submittedAnswers.length} / ${state.questions.length}',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Bouton suivant ou terminer
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedAnswer = null;
                      _stopwatch.reset();
                      _stopwatch.start();
                    });

                    context.read<QuizSessionBloc>().add(const NextQuestionEvent());
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    isLastQuestion ? 'Voir les résultats' : 'Question suivante',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _submitAnswer(BuildContext context, QuizSessionInProgress state) {
    if (_selectedAnswer == null) return;

    final timeSpent = _stopwatch.elapsed.inSeconds;

    context.read<QuizSessionBloc>().add(
      SubmitAnswerEvent(
        questionId: state.currentQuestion.id,
        answer: _selectedAnswer!,
        timeSpentSeconds: timeSpent,
      ),
    );
  }

  Future<void> _showQuitDialog(BuildContext context) async {
    final shouldQuit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter le quiz ?'),
        content: const Text('Votre progression sera perdue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );

    if (shouldQuit == true && context.mounted) {
      context.pop();
    }
  }
}