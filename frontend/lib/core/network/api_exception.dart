class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';

  factory ApiException.fromDioError(dynamic error) {
    if (error.response != null) {
      return ApiException(
        message: error.response?.data['message'] ?? 'Erreur serveur',
        statusCode: error.response?.statusCode,
        data: error.response?.data,
      );
    } else {
      return ApiException(
        message: 'Erreur de connexion: ${error.message}',
      );
    }
  }
}
