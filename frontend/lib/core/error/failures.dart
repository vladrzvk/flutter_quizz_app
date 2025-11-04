import 'package:equatable/equatable.dart';

/// Classe de base pour les erreurs métier
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

/// Erreur serveur (500, 502, etc.)
class ServerFailure extends Failure {
  const ServerFailure([String message = 'Erreur serveur']) : super(message);
}

/// Erreur de connexion
class ConnectionFailure extends Failure {
  const ConnectionFailure([String message = 'Pas de connexion Internet'])
      : super(message);
}

/// Erreur de cache
class CacheFailure extends Failure {
  const CacheFailure([String message = 'Erreur de cache']) : super(message);
}

/// Ressource non trouvée (404)
class NotFoundFailure extends Failure {
  const NotFoundFailure([String message = 'Ressource non trouvée'])
      : super(message);
}

/// Erreur de validation
class ValidationFailure extends Failure {
  const ValidationFailure([String message = 'Données invalides'])
      : super(message);
}

/// Erreur non autorisée (401, 403)
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([String message = 'Non autorisé']) : super(message);
}
