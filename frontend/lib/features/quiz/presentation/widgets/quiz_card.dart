import 'package:flutter/material.dart';
import '../../domain/entities/quiz_entity.dart';

class QuizCard extends StatelessWidget {
  final QuizEntity quiz;
  final VoidCallback onTap;

  const QuizCard({
    super.key,
    required this.quiz,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre
              Row(
                children: [
                  Expanded(
                    child: Text(
                      quiz.titre,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ],
              ),

              // Description
              if (quiz.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  quiz.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 16),

              // Infos (badges)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Difficulté
                  _buildBadge(
                    context,
                    icon: Icons.speed,
                    label: quiz.difficultyEmoji,
                    color: _getDifficultyColor(quiz.niveauDifficulte),
                  ),

                  // Nombre de questions
                  _buildBadge(
                    context,
                    icon: Icons.quiz,
                    label: '${quiz.nbQuestions} questions',
                    color: Colors.blue,
                  ),

                  // Durée
                  _buildBadge(
                    context,
                    icon: Icons.timer,
                    label: '~${(quiz.nbQuestions * 15) ~/ 60} min',
                    color: Colors.orange,
                  ),

                  // Mode
                  _buildBadge(
                    context,
                    icon: Icons.description,
                    label: quiz.titre,
                    color: Colors.purple,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'facile':
        return Colors.green;
      case 'moyen':
        return Colors.orange;
      case 'difficile':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
