import 'dart:async';
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
  String? _selectedAnswerId; // ✅ Stocker l'ID, pas le texte !
  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    _startTimer();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _timer?.cancel();
    super.dispose();
  }

  /// ✅ Timer pour mettre à jour l'UI chaque seconde
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // L'UI se rafraîchit automatiquement
        });
      }
    });
  }

  /// ✅ Démarrer le countdown pour une question avec temps limite
  void _startQuestionCountdown(int seconds) {
    setState(() {
      _remainingSeconds = seconds;
    });

    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        // ✅ Temps écoulé : soumettre automatiquement
        timer.cancel();
        if (mounted) {
          // ✅ Récupérer le state actuel depuis le BLoC
          final currentState = context.read<QuizSessionBloc>().state;
          if (currentState is QuizSessionInProgress) {
            final timeSpent = _stopwatch.elapsed.inSeconds;

            // Soumettre avec une réponse vide (timeout)
            context.read<QuizSessionBloc>().add(
              SubmitAnswerEvent(
                questionId: currentState.currentQuestion.id,
                answer: '', // ✅ Réponse vide = timeout
                timeSpentSeconds: timeSpent,
              ),
            );
          }
        }
      }
    });
  }

  /// ✅ Réinitialiser pour la question suivante
  void _resetForNextQuestion(int? timeLimit) {
    setState(() {
      _selectedAnswerId = null;
      _stopwatch.reset();
      _stopwatch.start();
    });

    if (timeLimit != null) {
      _startQuestionCountdown(timeLimit);
    } else {
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<QuizSessionBloc>()
        ..add(StartQuizSessionEvent(
          quizId: widget.quizId,
          userId: const Uuid().v4(),
        )),
      child: BlocConsumer<QuizSessionBloc, QuizSessionState>(
        listener: (context, state) {


          // Quand la session est terminée
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
          // ✅ AJOUTER ICI - Initialiser le timer pour chaque nouvelle question
          if (state is QuizSessionInProgress) {
            final question = state.currentQuestion;

            // Vérifier si c'est une nouvelle question (index a changé)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (question.hasTimeLimit && _remainingSeconds == 0) {
                _startQuestionCountdown(question.tempsLimiteSec!);
              }
            });
          }
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
    final hasTimeLimit = question.hasTimeLimit;

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
                // Header avec progress et timer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Progress
                    Text(
                      'Question ${state.currentQuestionIndex + 1} / ${state.totalQuestions}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),

                    // ✅ Timer
                    if (hasTimeLimit)
                      _buildCountdownTimer()
                    else
                      _buildElapsedTimer(),
                  ],
                ),
                const SizedBox(height: 16),

                // Question Card
                QuestionCard(question: question),
                const SizedBox(height: 24),

                // ✅ Options de réponse (QCM/Vrai-Faux)
                if (question.isQcm || question.isVraiFaux)
                  ...?question.reponses?.map((option) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AnswerButton(
                        text: option.valeur ?? '',
                        isSelected: _selectedAnswerId == option.id, // ✅ Comparer les IDs
                        onTap: () {
                          setState(() {
                            _selectedAnswerId = option.id; // ✅ Stocker l'ID !
                          });
                        },
                      ),
                    );
                  }),

                // ✅ Champ de saisie texte
                if (question.isSaisieTexte) ...[
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Votre réponse...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedAnswerId = value; // Pour saisie texte, on stocke le texte
                      });
                    },
                  ),
                ],

                const SizedBox(height: 24),

                // Hint (si disponible)
                if (question.hasHint) ...[
                  ExpansionTile(
                    leading: const Icon(Icons.lightbulb_outline, color: Colors.orange),
                    title: const Text('💡 Besoin d\'un indice ?'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          question.hint!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Bouton valider
                ElevatedButton(
                  onPressed: _selectedAnswerId == null || _selectedAnswerId!.isEmpty
                      ? null
                      : () => _submitAnswer(context, state),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: const Text(
                    'Valider',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// ✅ Timer countdown (pour questions avec temps limite)
  Widget _buildCountdownTimer() {
    final isUrgent = _remainingSeconds <= 5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.red[100] : Colors.blue[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            size: 18,
            color: isUrgent ? Colors.red[700] : Colors.blue[700],
          ),
          const SizedBox(width: 6),
          Text(
            '${_remainingSeconds}s',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isUrgent ? Colors.red[700] : Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Timer elapsed (pour questions sans temps limite)
  Widget _buildElapsedTimer() {
    final elapsed = _stopwatch.elapsed;
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerFeedbackView(
      BuildContext context,
      QuizAnswerSubmitted state,
      ) {
    final answer = state.lastAnswer;
    final question = state.questions[state.currentQuestionIndex];
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
                  elevation: 4,
                  color: answer.isCorrect ? Colors.green[50] : Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          answer.isCorrect ? Icons.check_circle : Icons.cancel,
                          size: 80,
                          color: answer.isCorrect ? Colors.green : Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          answer.isCorrect ? 'Correct !' : 'Incorrect',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: answer.isCorrect ? Colors.green[900] : Colors.red[900],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '+${answer.pointsObtenus} points',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (answer.speedBadge != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              answer.speedBadge!,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Explication (si disponible)
                if (question.hasExplanation) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              Text(
                                'Explication',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            question.explanation!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Score actuel
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(
                          context,
                          'Score',
                          '${state.session.score}',
                          Icons.star,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey[300],
                        ),
                        _buildStatColumn(
                          context,
                          'Questions',
                          '${state.submittedAnswers.length} / ${state.questions.length}',
                          Icons.quiz,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Bouton suivant ou terminer
                ElevatedButton(
                  onPressed: () {
                    final nextQuestion = !isLastQuestion
                        ? state.questions[state.currentQuestionIndex + 1]
                        : null;

                    _resetForNextQuestion(nextQuestion?.tempsLimiteSec);

                    context.read<QuizSessionBloc>().add(const NextQuestionEvent());
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    isLastQuestion ? '🏆 Voir les résultats' : '➡️ Question suivante',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue[700]),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _submitAnswer(BuildContext context, QuizSessionInProgress? state) {
    if (state == null) return;

    final timeSpent = _stopwatch.elapsed.inSeconds;

    context.read<QuizSessionBloc>().add(
      SubmitAnswerEvent(
        questionId: state.currentQuestion.id,
        answer: _selectedAnswerId ?? '', // ✅ Envoyer l'ID ou le texte
        timeSpentSeconds: timeSpent,
      ),
    );

    // Arrêter le timer après soumission
    _timer?.cancel();
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