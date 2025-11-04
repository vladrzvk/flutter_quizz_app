import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_model.freezed.dart';
part 'session_model.g.dart';

@freezed
class SessionModel with _$SessionModel {
  const factory SessionModel({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'quiz_id') required String quizId,
    required int score,
    @JsonKey(name: 'score_max') required int scoreMax,
    double? pourcentage,
    @JsonKey(name: 'temps_total_sec') int? tempsTotalSec,
    required String status,
    @JsonKey(name: 'date_debut') required String dateDebut,
    @JsonKey(name: 'date_fin') String? dateFin,
  }) = _SessionModel;

  factory SessionModel.fromJson(Map<String, dynamic> json) =>
      _$SessionModelFromJson(json);
}
