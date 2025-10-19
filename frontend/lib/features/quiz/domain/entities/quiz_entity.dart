import 'package:equatable/equatable.dart';

/// Entity représentant un Quiz dans le domaine métier
class QuizEntity extends Equatable {
  final String id;
  final String titre;
  final String? description;
  final String niveauDifficulte;
  final String versionApp;
  final String regionScope;
  final String mode;
  final int nbQuestions;
  final int? tempsLimiteSec;
  final bool isActive;
  final DateTime createdAt;

  const QuizEntity({
    required this.id,
    required this.titre,
    this.description,
    required this.niveauDifficulte,
    required this.versionApp,
    required this.regionScope,
    required this.mode,
    required this.nbQuestions,
    this.tempsLimiteSec,
    required this.isActive,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    titre,
    description,
    niveauDifficulte,
    versionApp,
    regionScope,
    mode,
    nbQuestions,
    tempsLimiteSec,
    isActive,
    createdAt,
  ];

  // 🎯 MÉTHODES MÉTIER (Business Logic)

  /// Vérifie si le quiz est disponible pour être joué
  bool get isAvailable => isActive && nbQuestions > 0;

  /// Vérifie si c'est un quiz V0 (texte uniquement)
  bool get isV0 => versionApp == 'v0' && mode == 'texte';

  /// Label de difficulté formaté
  String get difficultyLabel {
    switch (niveauDifficulte.toLowerCase()) {
      case 'facile':
        return 'Facile';
      case 'moyen':
        return 'Moyen';
      case 'difficile':
        return 'Difficile';
      default:
        return niveauDifficulte;
    }
  }

  /// Durée estimée en minutes
  int get estimatedDurationMinutes {
    if (tempsLimiteSec != null) {
      return (tempsLimiteSec! / 60).ceil();
    }
    // Estimation: 30 secondes par question
    return ((nbQuestions * 30) / 60).ceil();
  }

  /// Vérifie si le quiz a une limite de temps
  bool get hasTimeLimit => tempsLimiteSec != null && tempsLimiteSec! > 0;
}