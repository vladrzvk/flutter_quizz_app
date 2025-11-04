import '../../../domain/entities/reponse_entity.dart';
import '../reponse_model.dart';

extension ReponseModelMapper on ReponseModel {
  ReponseEntity toEntity() {
    return ReponseEntity(
      id: id,
      valeur: valeur,
      ordre: ordre,
    );
  }
}

extension ReponseModelListMapper on List<ReponseModel> {
  List<ReponseEntity> toEntities() => map((m) => m.toEntity()).toList();
}