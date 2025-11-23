import '../../../domain/entities/session_entity.dart';
import '../session_model.dart';

/// Extension pour convertir SessionModel → SessionEntity
extension SessionModelMapper on SessionModel {
  /// Convertit le Model (JSON) en Entity (Domain)
  SessionEntity toEntity() {
    return SessionEntity(
      id: id,
      userId: userId,
      quizId: quizId,
      score: score,
      scoreMax: scoreMax,
      pourcentage: pourcentage,
      tempsTotalSec: tempsTotalSec,
      dateDebut: DateTime.parse(dateDebut),
      dateFin: dateFin != null ? DateTime.parse(dateFin!) : null,
      status: _mapStatus(status),
    );
  }

  /// Convertit le status string en enum SessionStatus
  SessionStatus _mapStatus(String statusString) {
    return SessionStatus.fromString(statusString);
  }
}

/// Extension pour convertir SessionEntity → SessionModel
extension SessionEntityMapper on SessionEntity {
  /// Convertit l'Entity (Domain) en Model (JSON)
  SessionModel toModel() {
    return SessionModel(
      id: id,
      userId: userId,
      quizId: quizId,
      score: score,
      scoreMax: scoreMax,
      pourcentage: pourcentage,
      tempsTotalSec: tempsTotalSec,
      dateDebut: dateDebut.toIso8601String(),
      dateFin: dateFin?.toIso8601String(),
      status: status.value,
    );
  }
}

/// Extension pour convertir une liste de Models en liste d'Entities
extension SessionModelListMapper on List<SessionModel> {
  List<SessionEntity> toEntities() {
    return map((model) => model.toEntity()).toList();
  }
}
