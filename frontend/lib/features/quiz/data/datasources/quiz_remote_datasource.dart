import 'package:dio/dio.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/error/exceptions.dart';
import '../models/quiz_model.dart';
import '../models/question_model.dart';
import '../models/session_model.dart';
import '../models/answer_submission.dart';

/// Interface du DataSource distant
/// Définit les méthodes pour communiquer avec l'API
abstract class QuizRemoteDataSource {
  /// GET /api/v1/quizzes
  Future<List<QuizModel>> getQuizzes();

  /// GET /api/v1/quizzes/:id
  Future<QuizModel> getQuizById(String id);

  /// GET /api/v1/quizzes/:quizId/questions
  Future<List<QuestionModel>> getQuizQuestions(String quizId);

  /// POST /api/v1/quizzes/:quizId/sessions
  Future<SessionModel> startSession({
    required String quizId,
    required String userId,
  });

  /// POST /api/v1/sessions/:sessionId/answers
  Future<UserAnswerModel> submitAnswer({
    required String sessionId,
    required AnswerSubmission answer,
  });

  /// POST /api/v1/sessions/:sessionId/finalize
  Future<SessionModel> finalizeSession(String sessionId);

  /// GET /api/v1/sessions/:sessionId
  Future<SessionModel> getSession(String sessionId);
}

/// Implémentation du DataSource distant avec Dio
class QuizRemoteDataSourceImpl implements QuizRemoteDataSource {
  final Dio dio;

  QuizRemoteDataSourceImpl({required this.dio}) {
    // Configuration de base pour ce DataSource
    dio.options.baseUrl = ApiConfig.quizServiceUrl;
    dio.options.connectTimeout = ApiConfig.connectTimeout;
    dio.options.receiveTimeout = ApiConfig.receiveTimeout;
  }

  @override
  Future<List<QuizModel>> getQuizzes() async {
    try {
      final response = await dio.get('/quizzes');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => QuizModel.fromJson(json)).toList();
      } else {
        throw ServerException(
          message: 'Erreur lors de la récupération des quiz',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(
        message: 'Erreur inattendue: $e',
      );
    }
  }

  @override
  Future<QuizModel> getQuizById(String id) async {
    try {
      final response = await dio.get('/quizzes/$id');

      if (response.statusCode == 200) {
        return QuizModel.fromJson(response.data);
      } else if (response.statusCode == 404) {
        throw NotFoundException(message: 'Quiz non trouvé');
      } else {
        throw ServerException(
          message: 'Erreur lors de la récupération du quiz',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erreur inattendue: $e');
    }
  }

  @override
  Future<List<QuestionModel>> getQuizQuestions(String quizId) async {
    try {
      final response = await dio.get('/quizzes/$quizId/questions');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => QuestionModel.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        throw NotFoundException(message: 'Quiz non trouvé');
      } else {
        throw ServerException(
          message: 'Erreur lors de la récupération des questions',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erreur inattendue: $e');
    }
  }

  @override
  Future<SessionModel> startSession({
    required String quizId,
    required String userId,
  }) async {
    try {
      final response = await dio.post(
        '/quizzes/$quizId/sessions',
        data: {'user_id': userId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return SessionModel.fromJson(response.data);
      } else if (response.statusCode == 404) {
        throw NotFoundException(message: 'Quiz non trouvé');
      } else {
        throw ServerException(
          message: 'Erreur lors du démarrage de la session',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erreur inattendue: $e');
    }
  }

  @override
  Future<UserAnswerModel> submitAnswer({
    required String sessionId,
    required AnswerSubmission answer,
  }) async {
    try {
      final response = await dio.post(
        '/sessions/$sessionId/answers',
        data: answer.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return UserAnswerModel.fromJson(response.data);
      } else if (response.statusCode == 404) {
        throw NotFoundException(message: 'Session non trouvée');
      } else if (response.statusCode == 400) {
        throw ValidationException(
          message: response.data['message'] ?? 'Données invalides',
        );
      } else {
        throw ServerException(
          message: 'Erreur lors de la soumission de la réponse',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erreur inattendue: $e');
    }
  }

  @override
  Future<SessionModel> finalizeSession(String sessionId) async {
    try {
      final response = await dio.post('/sessions/$sessionId/finalize');

      if (response.statusCode == 200) {
        return SessionModel.fromJson(response.data);
      } else if (response.statusCode == 404) {
        throw NotFoundException(message: 'Session non trouvée');
      } else {
        throw ServerException(
          message: 'Erreur lors de la finalisation de la session',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erreur inattendue: $e');
    }
  }

  @override
  Future<SessionModel> getSession(String sessionId) async {
    try {
      final response = await dio.get('/sessions/$sessionId');

      if (response.statusCode == 200) {
        return SessionModel.fromJson(response.data);
      } else if (response.statusCode == 404) {
        throw NotFoundException(message: 'Session non trouvée');
      } else {
        throw ServerException(
          message: 'Erreur lors de la récupération de la session',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erreur inattendue: $e');
    }
  }

  /// Gère les erreurs Dio et les convertit en exceptions personnalisées
  AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ConnectionException(
          message: 'Délai de connexion dépassé',
        );

      case DioExceptionType.connectionError:
        return ConnectionException(
          message: 'Erreur de connexion au serveur',
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data['message'] ?? 'Erreur serveur';

        if (statusCode == 404) {
          return NotFoundException(message: message);
        } else if (statusCode == 400) {
          return ValidationException(message: message);
        } else if (statusCode != null && statusCode >= 500) {
          return ServerException(
            message: message,
            statusCode: statusCode,
          );
        } else {
          return ServerException(
            message: message,
            statusCode: statusCode,
          );
        }

      case DioExceptionType.cancel:
        return ServerException(message: 'Requête annulée');

      case DioExceptionType.unknown:
        return ConnectionException(
          message: 'Erreur de connexion: ${error.message}',
        );

      default:
        return ServerException(
          message: 'Erreur inconnue: ${error.message}',
        );
    }
  }
}
