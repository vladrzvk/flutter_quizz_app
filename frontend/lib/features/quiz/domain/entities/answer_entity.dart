import 'package:equatable/equatable.dart';

/// Entity représentant une Réponse Utilisateur dans le domaine métier
class AnswerEntity extends Equatable {
  final String id;
  final String sessionId;
  final String questionId;
  final String? reponseId;
  final String? valeurSaisie;
  final bool isCorrect;
  final int pointsObtenus;
  final int tempsReponseSec;
  final DateTime createdAt;

  const AnswerEntity({
    required this.id,
    required this.sessionId,
    required this.questionId,
    this.reponseId,
    this.valeurSaisie,
    required this.isCorrect,
    required this.pointsObtenus,
    required this.tempsReponseSec,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        sessionId,
        questionId,
        reponseId,
        valeurSaisie,
        isCorrect,
        pointsObtenus,
        tempsReponseSec,
        createdAt,
      ];

  // 🎯 MÉTHODES MÉTIER

  /// Vérifie si la réponse a été rapide (< 10s)
  bool get isFastAnswer => tempsReponseSec < 10;

  /// Vérifie si la réponse a été lente (> 30s)
  bool get isSlowAnswer => tempsReponseSec > 30;

  /// Message de feedback
  String get feedbackMessage {
    if (isCorrect) {
      if (pointsObtenus >= 15) return 'Parfait !';
      if (pointsObtenus >= 10) return 'Correct !';
      return 'Bien !';
    }
    return 'Incorrect';
  }

  /// Badge de vitesse (si applicable)
  String? get speedBadge {
    if (!isCorrect) return null;
    if (isFastAnswer) return 'Rapide';
    if (isSlowAnswer) return 'Prends ton temps';
    return null;
  }

  /// Durée formatée
  Duration get duration => Duration(seconds: tempsReponseSec);
}
