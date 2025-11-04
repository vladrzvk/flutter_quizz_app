import 'package:equatable/equatable.dart';

/// Entity représentant une Session de Quiz dans le domaine métier
class SessionEntity extends Equatable {
  final String id;
  final String userId;
  final String quizId;
  final int score;
  final int scoreMax;
  final double? pourcentage;
  final int? tempsTotalSec;
  final DateTime dateDebut;
  final DateTime? dateFin;
  final SessionStatus status;

  const SessionEntity({
    required this.id,
    required this.userId,
    required this.quizId,
    required this.score,
    required this.scoreMax,
    this.pourcentage,
    this.tempsTotalSec,
    required this.dateDebut,
    this.dateFin,
    required this.status,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        quizId,
        score,
        scoreMax,
        pourcentage,
        tempsTotalSec,
        dateDebut,
        dateFin,
        status,
      ];

  // 🎯 MÉTHODES MÉTIER

  /// Vérifie si la session est terminée
  bool get isCompleted => status == SessionStatus.termine;

  /// Vérifie si la session est en cours
  bool get isInProgress => status == SessionStatus.enCours;

  /// Vérifie si la session est abandonnée
  bool get isAbandoned => status == SessionStatus.abandonne;

  /// Calcule le pourcentage si non disponible
  double get calculatedPourcentage {
    if (pourcentage != null) return pourcentage!;
    if (scoreMax == 0) return 0.0;
    return (score / scoreMax) * 100;
  }

  /// Vérifie si le quiz est réussi (>= 50%)
  bool get isPassed => calculatedPourcentage >= 50;

  /// Vérifie si c'est un excellent score (>= 80%)
  bool get isExcellent => calculatedPourcentage >= 80;

  /// Vérifie si c'est un bon score (>= 60%)
  bool get isGood => calculatedPourcentage >= 60;

  /// Progression (0.0 à 1.0)
  double get progress {
    if (scoreMax == 0) return 0.0;
    return score / scoreMax;
  }

  /// Durée de la session (calculée ou réelle)
  Duration get duration {
    if (tempsTotalSec != null) {
      return Duration(seconds: tempsTotalSec!);
    }
    if (dateFin != null) {
      return dateFin!.difference(dateDebut);
    }
    return DateTime.now().difference(dateDebut);
  }

  /// Message de résultat selon le score
  String get resultMessage {
    if (!isCompleted) return 'En cours...';

    final pct = calculatedPourcentage;
    if (pct >= 90) return 'Parfait !';
    if (pct >= 80) return 'Excellent !';
    if (pct >= 70) return 'Très bien !';
    if (pct >= 60) return 'Bien';
    if (pct >= 50) return 'Passable';
    return 'À améliorer';
  }

  /// Peut terminer la session (doit être en cours)
  bool get canFinalize => isInProgress;

  /// Peut abandonner la session (doit être en cours)
  bool get canAbandon => isInProgress;
}

/// Enum pour le statut de la session
enum SessionStatus {
  enCours('en_cours'),
  termine('termine'),
  abandonne('abandonne');

  final String value;
  const SessionStatus(this.value);

  static SessionStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'en_cours':
        return SessionStatus.enCours;
      case 'termine':
        return SessionStatus.termine;
      case 'abandonne':
        return SessionStatus.abandonne;
      default:
        return SessionStatus.enCours;
    }
  }
}
