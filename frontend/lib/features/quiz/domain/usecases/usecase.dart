import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';

/// Classe de base pour tous les Use Cases
/// Type: Le type de retour
/// Params: Les paramètres d'entrée
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Classe pour les Use Cases sans paramètres
class NoParams extends Equatable {
  @override
  List<Object> get props => [];
}
