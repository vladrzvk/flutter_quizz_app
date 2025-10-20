import 'package:flutter/material.dart';
import '../../domain/entities/question_entity.dart';

class QuestionCard extends StatelessWidget {
  final QuestionEntity question;

  const QuestionCard({
    super.key,
    required this.question,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type de question
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    question.typeQuestion,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  // Text(
                  //   question.points,
                  //   style: TextStyle(
                  //     fontSize: 12,
                  //     fontWeight: FontWeight.w600,
                  //     color: Theme.of(context).colorScheme.onPrimaryContainer,
                  //   ),
                  // ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Texte de la question
            Text(
              question.questionText,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Points et temps
            Row(
              children: [
                Icon(Icons.star, size: 20, color: Colors.amber[700]),
                const SizedBox(width: 4),
                Text(
                  '${question.points} points',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 16),
                if (question.hasTimeLimit) ...[
                  Icon(Icons.timer, size: 20, color: Colors.blue[700]),
                  const SizedBox(width: 4),
                  Text(
                    question.durationInSeconds.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ],
            ),

            // Indice (si disponible)
            if (question.hasHint) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 20, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        question.hint!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[900],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}