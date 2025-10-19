/// Exception de base pour les erreurs
class AppException implements Exception {
  final String message;
  final int? statusCode;

  AppException({required this.message, this.statusCode});

  @override
  String toString() => 'AppException: $message (Status: $statusCode)';
}

/// Exception serveur
class ServerException extends AppException {
  ServerException({String message = 'Erreur serveur', int? statusCode})
      : super(message: message, statusCode: statusCode);
}

/// Exception de cache
class CacheException extends AppException {
  CacheException({String message = 'Erreur de cache'})
      : super(message: message);
}

/// Exception de connexion
class ConnectionException extends AppException {
  ConnectionException({String message = 'Pas de connexion'})
      : super(message: message);
}

/// Exception non trouvé
class NotFoundException extends AppException {
  NotFoundException({String message = 'Ressource non trouvée'})
      : super(message: message, statusCode: 404);
}

/// Exception de validation
class ValidationException extends AppException {
  ValidationException({String message = 'Données invalides'})
      : super(message: message, statusCode: 400);
}