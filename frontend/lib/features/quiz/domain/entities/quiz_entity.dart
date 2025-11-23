import 'package:equatable/equatable.dart';

class QuizEntity extends Equatable {
  final String id;
  final String domain;
  final String titre;
  final String? description;
  final String niveauDifficulte;
  final String versionApp;
  final String scope;
  final String mode;
  final String? collectionId;
  final int nbQuestions;
  final int? tempsLimiteSec;
  final int? scoreMinimumSuccess;
  final bool isActive;
  final bool? isPublic;
  final int? totalAttempts;
  final double? averageScore;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const QuizEntity({
    required this.id,
    required this.domain,
    required this.titre,
    this.description,
    required this.niveauDifficulte,
    required this.versionApp,
    required this.scope,
    required this.mode,
    this.collectionId,
    required this.nbQuestions,
    this.tempsLimiteSec,
    this.scoreMinimumSuccess,
    required this.isActive,
    this.isPublic,
    this.totalAttempts,
    this.averageScore,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [id, domain, titre, scope, mode];

  // Helpers
  String get difficultyEmoji {
    switch (niveauDifficulte) {
      case 'facile':
        return '🟢';
      case 'moyen':
        return '🟡';
      case 'difficile':
        return '🔴';
      default:
        return '⚪';
    }
  }

  String get domainEmoji {
    switch (domain) {
      case 'geography':
        return '🌍';
      case 'code_route':
        return '🚗';
      default:
        return '📚';
    }
  }

  String get modeLabel {
    switch (mode) {
      case 'decouverte':
        return 'Découverte';
      case 'entrainement':
        return 'Entraînement';
      case 'examen':
        return 'Examen';
      case 'competition':
        return 'Compétition';
      default:
        return mode;
    }
  }
}
