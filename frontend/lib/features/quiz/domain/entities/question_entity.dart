import 'package:equatable/equatable.dart';
import 'package:flutter_geo_app/features/quiz/domain/entities/reponse_entity.dart';
import 'reponse_entity.dart';

class QuestionEntity extends Equatable {
  final String id;
  final String quizId;
  final int ordre;
  final String? category;
  final String? subcategory;
  final String typeQuestion;
  final Map<String, dynamic> questionData;
  final String? mediaUrl;
  final String? targetId;
  final int points;
  final int? tempsLimiteSec;
  final String? hint;
  final String? explanation;
  final Map<String, dynamic>? metadata;
  final int? totalAttempts;
  final int? correctAttempts;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<ReponseEntity>? reponses;

  const QuestionEntity({
    required this.id,
    required this.quizId,
    required this.ordre,
    this.category,
    this.subcategory,
    required this.typeQuestion,
    required this.questionData,
    this.mediaUrl,
    this.targetId,
    required this.points,
    this.tempsLimiteSec,
    this.hint,
    this.explanation,
    this.metadata,
    this.totalAttempts,
    this.correctAttempts,
    this.createdAt,
    this.updatedAt,
    this.reponses,
  });

  @override
  List<Object?> get props => [id, quizId, ordre, typeQuestion];

  // Helpers
  String get questionText => questionData['text'] as String? ?? '';
  String? get questionImage => questionData['image'] as String?;

  bool get hasHint => hint != null && hint!.isNotEmpty;
  bool get hasExplanation => explanation != null && explanation!.isNotEmpty;
  bool get hasTimeLimit => tempsLimiteSec != null;
  bool get hasReponses => reponses != null && reponses!.isNotEmpty;

  // Types
  bool get isQcm => typeQuestion == 'qcm';
  bool get isVraiFaux => typeQuestion == 'vrai_faux';
  bool get isSaisieTexte => typeQuestion == 'saisie_texte';
  bool get isCarteCliquable => typeQuestion == 'carte_cliquable';

  String get typeIcon {
    if (isQcm) return '📝';
    if (isVraiFaux) return '✅❌';
    if (isSaisieTexte) return '⌨️';
    if (isCarteCliquable) return '🗺️';
    return '❓';
  }

  String get categoryLabel => category ?? 'Général';
}