import 'package:equatable/equatable.dart';

class ReponseEntity extends Equatable {
  final String id;
  final String? valeur;
  final int? ordre;

  const ReponseEntity({
    required this.id,
    this.valeur,
    this.ordre,
  });

  @override
  List<Object?> get props => [id, valeur, ordre];
}
