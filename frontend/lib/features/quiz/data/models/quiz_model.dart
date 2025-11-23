import 'package:freezed_annotation/freezed_annotation.dart';

part 'quiz_model.freezed.dart';
part 'quiz_model.g.dart';

/// Modèle de Quiz (correspondance avec l'API Backend)
/// Endpoint: GET /api/v1/quizzes
@freezed
class QuizModel with _$QuizModel {
  const factory QuizModel({
    /// ID unique du quiz
    required String id,

    /// ✅ NOUVEAU - Domaine du quiz (geography, code_route, etc.)
    /// Utilisé pour sélectionner le bon plugin côté backend
    @JsonKey(name: 'domain') required String domain,

    /// Titre du quiz
    required String titre,

    /// Description (optionnel)
    String? description,

    /// Niveau de difficulté: 'facile', 'moyen', 'difficile'
    @JsonKey(name: 'niveau_difficulte') required String niveauDifficulte,

    /// Version de l'application
    @JsonKey(name: 'version_app') required String versionApp,

    /// ✅ MODIFIÉ - Portée du quiz (france, europe, monde, etc.)
    /// Avant: region_scope → Maintenant: scope
    @JsonKey(name: 'scope') required String scope,

    /// Mode de quiz: 'decouverte', 'entrainement', 'examen', 'competition'
    required String mode,

    /// ✅ NOUVEAU - ID de collection (optionnel)
    /// Pour regrouper plusieurs quiz ensemble
    @JsonKey(name: 'collection_id') String? collectionId,

    /// Nombre de questions dans le quiz
    @JsonKey(name: 'nb_questions') required int nbQuestions,

    /// Temps limite global du quiz en secondes (optionnel)
    @JsonKey(name: 'temps_limite_sec') int? tempsLimiteSec,

    /// ✅ NOUVEAU - Score minimum pour réussir (en %)
    @JsonKey(name: 'score_minimum_success') int? scoreMinimumSuccess,

    /// Quiz actif ?
    @JsonKey(name: 'is_active') required bool isActive,

    /// ✅ NOUVEAU - Quiz public ?
    @JsonKey(name: 'is_public') bool? isPublic,

    /// ✅ NOUVEAU - Nombre total de tentatives
    @JsonKey(name: 'total_attempts') int? totalAttempts,

    /// ✅ NOUVEAU - Score moyen des joueurs
    @JsonKey(name: 'average_score') double? averageScore,

    /// Date de création
    @JsonKey(name: 'created_at') required String createdAt,

    /// ✅ NOUVEAU - Date de mise à jour
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _QuizModel;

  factory QuizModel.fromJson(Map<String, dynamic> json) =>
      _$QuizModelFromJson(json);
}
