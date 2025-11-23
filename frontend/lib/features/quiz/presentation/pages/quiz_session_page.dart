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

  QuizSessionBloc? _bloc;
  int _lastQuestionIndex = -1;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // _stopwatch.start();
    // _startTimer();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _timer?.cancel();
    super.dispose();
  }

  /// Timer pour mettre à jour l'UI chaque seconde
  void _startTimer() {
    //  Annuler le timer précédent
    _timer?.cancel();

    // On force juste un rebuild toutes les secondes pour l'affichage
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {}); // Juste pour rafraîchir l'UI
      }
    });
  }

  ///  Démarrer le countdown pour une question avec temps limite
  void _startQuestionCountdown(int seconds) {
    // ✅ Annuler tous les timers existants
    _timer?.cancel();

    setState(() {
      _remainingSeconds = seconds;
    });

    print('⏱️ Countdown START: ${seconds}s');

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // ✅ VÉRIFIER D'ABORD si _isSubmitting
      if (_isSubmitting) {
        print('⚠️ Déjà en train de soumettre, on annule le timer');
        timer.cancel();
        return;
      }

      if (_remainingSeconds > 0) {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
          });

          // Log uniquement les 5 dernières secondes
          if (_remainingSeconds <= 5 && _remainingSeconds > 0) {
            print('⏱️ Countdown: ${_remainingSeconds}s restantes');
          }
        }
      } else {
        // ✅ ARRÊTER LE TIMER IMMÉDIATEMENT
        timer.cancel();
        print('⏰ COUNTDOWN FINISHED');

        // ✅ Double vérification
        if (mounted && _bloc != null && !_isSubmitting) {
          _isSubmitting = true;

          final currentState = _bloc!.state;

          if (currentState is QuizSessionInProgress) {
            final timeSpent = _stopwatch.elapsed.inSeconds;

            print('⏰ TIMEOUT - Auto-submit after ${timeSpent}s');

            // ✅ Soumettre
            _bloc!.add(
              SubmitAnswerEvent(
                questionId: currentState.currentQuestion.id,
                answer: '',
                timeSpentSeconds: timeSpent,
              ),
            );

            // ✅ Arrêter le Stopwatch aussi
            _stopwatch.stop();
          }
        }
      }
    });
  }

  ///  Réinitialiser pour la question suivante
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
      create: (_) {
        // ✅ Stocker la référence
        _bloc = sl<QuizSessionBloc>()
          ..add(StartQuizSessionEvent(
            quizId: widget.quizId,
            userId: const Uuid().v4(),
          ));
        return _bloc!;
      },
      child: BlocConsumer<QuizSessionBloc, QuizSessionState>(
        listener: (context, state) {
          print('🔔 LISTENER CALLED - State: ${state.runtimeType}');
          // ✅ Détecter nouvelle question
          if (state is QuizSessionInProgress) {
            final currentIndex = state.currentQuestionIndex;
            print(
                '   → currentIndex: $currentIndex, _lastQuestionIndex: $_lastQuestionIndex'); //

            // ✅ AJOUTER : Ne pas redémarrer si on est en train de soumettre
            if (_isSubmitting && currentIndex == _lastQuestionIndex) {
              print('⚠️ Soumission en cours, on ne redémarre pas le timer');
              return;
            }

            // Si nouvelle question détectée
            if (currentIndex != _lastQuestionIndex) {
              print(
                  '🎯 Nouvelle question ${currentIndex + 1} - Timer: ${state.currentQuestion.tempsLimiteSec}s');

              _lastQuestionIndex = currentIndex;
              _isSubmitting = false; // ✅ Reset pour la nouvelle question

              final question = state.currentQuestion;

              // ✅ Réinitialiser pour la nouvelle question
              setState(() {
                _selectedAnswerId = null;
              });

              // ✅ Arrêter et réinitialiser le Stopwatch
              _stopwatch.stop();
              _stopwatch.reset();
              _stopwatch.start();

              // Démarrer le timer approprié
              _timer?.cancel();
              if (question.hasTimeLimit) {
                print('⏱️ Countdown de ${question.tempsLimiteSec}s démarre');
                _startQuestionCountdown(question.tempsLimiteSec!);
              } else {
                _startTimer();
              }
            }
          }

          // ✅ AJOUTER : Quand on passe à QuizAnswerSubmitted
          if (state is QuizAnswerSubmitted) {
            print('✅ Réponse soumise - Arrêt des timers');
            _timer?.cancel();
            _stopwatch.stop();
          }

          // Session terminée
          if (state is QuizSessionCompleted) {
            print('🏁 Quiz terminé');
            _stopwatch.stop();
            _timer?.cancel();

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
                        isSelected: _selectedAnswerId ==
                            option.id, // ✅ Comparer les IDs
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
                        _selectedAnswerId =
                            value; // Pour saisie texte, on stocke le texte
                      });
                    },
                  ),
                ],

                const SizedBox(height: 24),

                // Hint (si disponible)
                if (question.hasHint) ...[
                  ExpansionTile(
                    leading: const Icon(Icons.lightbulb_outline,
                        color: Colors.orange),
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
                  onPressed:
                      _selectedAnswerId == null || _selectedAnswerId!.isEmpty
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
    final isLastQuestion =
        state.currentQuestionIndex >= state.questions.length - 1;

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
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: answer.isCorrect
                                    ? Colors.green[900]
                                    : Colors.red[900],
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '+${answer.pointsObtenus} points',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (answer.speedBadge != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
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
                          '${state.totalScore}',
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
                    // final nextQuestion = !isLastQuestion
                    //     ? state.questions[state.currentQuestionIndex + 1]
                    //     : null;
                    //
                    // _resetForNextQuestion(nextQuestion?.tempsLimiteSec);

                    context
                        .read<QuizSessionBloc>()
                        .add(const NextQuestionEvent());
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    isLastQuestion
                        ? '🏆 Voir les résultats'
                        : '➡️ Question suivante',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(
      BuildContext context, String label, String value, IconData icon) {
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
    if (state == null || _isSubmitting) return;

    _isSubmitting = true; // ✅ Bloquer les doubles soumissions
    final timeSpent = _stopwatch.elapsed.inSeconds;

    print('✅ Manuel submit after ${timeSpent}s');

    context.read<QuizSessionBloc>().add(
          SubmitAnswerEvent(
            questionId: state.currentQuestion.id,
            answer: _selectedAnswerId ?? '',
            timeSpentSeconds: timeSpent,
          ),
        );

    // Arrêter le timer
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
