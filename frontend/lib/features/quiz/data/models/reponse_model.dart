import 'package:freezed_annotation/freezed_annotation.dart';

part 'reponse_model.freezed.dart';
part 'reponse_model.g.dart';

/// Options de réponse pour QCM/Vrai-Faux
/// ⚠️ is_correct n'est PAS exposé par l'API (sécurité)
@freezed
class ReponseModel with _$ReponseModel {
  const factory ReponseModel({
    required String id,
    String? valeur,
    int? ordre,
  }) = _ReponseModel;

  factory ReponseModel.fromJson(Map<String, dynamic> json) =>
      _$ReponseModelFromJson(json);
}