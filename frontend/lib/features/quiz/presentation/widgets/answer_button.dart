import 'package:flutter/material.dart';

class AnswerButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  final bool? isCorrect; // Pour afficher le feedback après validation
  final bool isDisabled;

  const AnswerButton({
    super.key,
    required this.text,
    required this.isSelected,
    required this.onTap,
    this.isCorrect,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color backgroundColor;
    Color textColor;

    if (isCorrect != null) {
      // Mode feedback
      if (isCorrect!) {
        borderColor = Colors.green;
        backgroundColor = Colors.green[50]!;
        textColor = Colors.green[900]!;
      } else {
        borderColor = Colors.red;
        backgroundColor = Colors.red[50]!;
        textColor = Colors.red[900]!;
      }
    } else if (isSelected) {
      // Sélectionné
      borderColor = Theme.of(context).colorScheme.primary;
      backgroundColor = Theme.of(context).colorScheme.primary.withOpacity(0.1);
      textColor = Theme.of(context).colorScheme.primary;
    } else {
      // Normal
      borderColor = Colors.grey[300]!;
      backgroundColor = Colors.white;
      textColor = Colors.black87;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: borderColor,
                width: isSelected || isCorrect != null ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Icône de sélection ou feedback
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: borderColor,
                      width: 2,
                    ),
                    color: isSelected || isCorrect != null
                        ? borderColor
                        : Colors.transparent,
                  ),
                  child: isCorrect != null
                      ? Icon(
                    isCorrect! ? Icons.check : Icons.close,
                    size: 16,
                    color: Colors.white,
                  )
                      : isSelected
                      ? const Icon(
                    Icons.circle,
                    size: 12,
                    color: Colors.white,
                  )
                      : null,
                ),
                const SizedBox(width: 16),

                // Texte de la réponse
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected || isCorrect != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}