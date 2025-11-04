import 'package:freezed_annotation/freezed_annotation.dart';

part 'answer_submission.freezed.dart';
part 'answer_submission.g.dart';

// ========================================
// 1. MODEL POUR SOUMETTRE UNE RÉPONSE
// ========================================

/// Modèle pour soumettre une réponse au backend
/// Endpoint: POST /api/v1/sessions/:session_id/answers
@freezed
class AnswerSubmission with _$AnswerSubmission {
  const factory AnswerSubmission({
    /// ID de la question
    @JsonKey(name: 'question_id') required String questionId,

    /// ID de la réponse (pour choix multiples pré-définis)
    @JsonKey(name: 'reponse_id') String? reponseId,

    /// Valeur saisie par l'utilisateur (pour réponses texte)
    @JsonKey(name: 'valeur_saisie') String? valeurSaisie,

    /// Temps de réponse en secondes
    @JsonKey(name: 'temps_reponse_sec') required int tempsReponseSec,
  }) = _AnswerSubmission;

  factory AnswerSubmission.fromJson(Map<String, dynamic> json) =>
      _$AnswerSubmissionFromJson(json);
}

// ========================================
// 2. MODEL POUR RECEVOIR LA RÉPONSE UTILISATEUR
// ========================================

/// Modèle de réponse utilisateur (retour du backend après soumission)
/// Retourné par: POST /api/v1/sessions/:session_id/answers
@freezed
class UserAnswerModel with _$UserAnswerModel {
  const UserAnswerModel._();

  const factory UserAnswerModel({
    /// ID unique de la réponse utilisateur
    required String id,

    /// ID de la session
    @JsonKey(name: 'session_id') required String sessionId,

    /// ID de la question
    @JsonKey(name: 'question_id') required String questionId,

    /// ID de la réponse choisie (si applicable)
    @JsonKey(name: 'reponse_id') String? reponseId,

    /// Valeur saisie (si réponse texte)
    @JsonKey(name: 'valeur_saisie') String? valeurSaisie,

    /// La réponse est-elle correcte ?
    @JsonKey(name: 'is_correct') required bool isCorrect,

    /// Points obtenus pour cette réponse
    @JsonKey(name: 'points_obtenus') required int pointsObtenus,

    /// Temps de réponse en secondes
    @JsonKey(name: 'temps_reponse_sec') required int tempsReponseSec,

    /// Métadonnées supplémentaires
    Map<String, dynamic>? metadata,

    /// Date de création
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _UserAnswerModel;

  factory UserAnswerModel.fromJson(Map<String, dynamic> json) =>
      _$UserAnswerModelFromJson(json);

  // 🎯 MÉTHODES PERSONNALISÉES

  /// Icône selon le résultat
  String get resultIcon => isCorrect ? '✅' : '❌';

  /// Couleur selon le résultat (hex)
  String get resultColor => isCorrect ? '#4CAF50' : '#F44336';

  /// Message de feedback simple
  String get feedbackMessage {
    if (isCorrect) {
      if (pointsObtenus >= 15) return 'Parfait !';
      if (pointsObtenus >= 10) return 'Correct !';
      return 'Bien !';
    }
    return 'Incorrect';
  }

  /// Message de feedback détaillé avec points
  String get detailedFeedback {
    if (isCorrect) {
      return 'Correct ! +$pointsObtenus points 🎉';
    }
    return 'Incorrect • 0 point';
  }

  /// Emoji selon le résultat et les points
  String get resultEmoji {
    if (!isCorrect) return '❌';
    if (pointsObtenus >= 15) return '🏆';
    if (pointsObtenus >= 10) return '🎉';
    return '✅';
  }

  /// Temps de réponse formaté
  String get formattedTime {
    if (tempsReponseSec < 60) {
      return '${tempsReponseSec}s';
    }
    final minutes = tempsReponseSec ~/ 60;
    final seconds = tempsReponseSec % 60;
    return '${minutes}m ${seconds}s';
  }

  /// Vérifie si la réponse a été rapide (< 10s)
  bool get isFastAnswer => tempsReponseSec < 10;

  /// Vérifie si la réponse a été lente (> 30s)
  bool get isSlowAnswer => tempsReponseSec > 30;

  /// Badge de vitesse
  String? get speedBadge {
    if (isCorrect && isFastAnswer) return '⚡ Rapide !';
    if (isSlowAnswer) return '🐢 Prends ton temps';
    return null;
  }

  /// Message combiné (feedback + vitesse)
  String get fullFeedback {
    final speed = speedBadge;
    if (speed != null) {
      return '$detailedFeedback • $speed';
    }
    return detailedFeedback;
  }
}
