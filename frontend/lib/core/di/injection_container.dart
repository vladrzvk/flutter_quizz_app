import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../../features/quiz/data/datasources/quiz_remote_datasource.dart';
import '../../features/quiz/data/repositories/quiz_repository_impl.dart';
import '../../features/quiz/domain/repositories/quiz_repository.dart';
import '../../features/quiz/domain/usecases/finalize_session.dart';
import '../../features/quiz/domain/usecases/get_quiz_by_id.dart';
import '../../features/quiz/domain/usecases/get_quiz_list.dart';
import '../../features/quiz/domain/usecases/get_quiz_questions.dart';
import '../../features/quiz/domain/usecases/get_session.dart';
import '../../features/quiz/domain/usecases/start_quiz_session.dart';
import '../../features/quiz/domain/usecases/submit_answer.dart';
import '../../features/quiz/presentation/bloc/quiz_list/quiz_list_bloc.dart';
import '../../features/quiz/presentation/bloc/quiz_session/quiz_session_bloc.dart';
import '../config/api_config.dart';

/// Service Locator global
final sl = GetIt.instance;

/// Initialise toutes les dépendances
Future<void> initializeDependencies() async {
  // ========================================
  // 🌐 CORE - External
  // ========================================

  // Dio Client
  sl.registerLazySingleton<Dio>(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.quizServiceUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: ApiConfig.headers,
      ),
    );

    // Intercepteurs pour le logging (optionnel)
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => print('[DIO] $obj'),
      ),
    );

    return dio;
  });

  // ========================================
  // 🎯 FEATURE: QUIZ
  // ========================================

  // DataSources
  sl.registerLazySingleton<QuizRemoteDataSource>(
    () => QuizRemoteDataSourceImpl(dio: sl()),
  );

  // Repositories
  sl.registerLazySingleton<QuizRepository>(
    () => QuizRepositoryImpl(remoteDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetQuizList(sl()));
  sl.registerLazySingleton(() => GetQuizById(sl()));
  sl.registerLazySingleton(() => GetQuizQuestions(sl()));
  sl.registerLazySingleton(() => StartQuizSession(sl()));
  sl.registerLazySingleton(() => SubmitAnswer(sl()));
  sl.registerLazySingleton(() => FinalizeSession(sl()));
  sl.registerLazySingleton(() => GetSession(sl()));

  // BLoCs - Factory (nouvelle instance à chaque fois)
  sl.registerFactory(
    () => QuizListBloc(
      getQuizList: sl(),
      getQuizById: sl(),
    ),
  );

  sl.registerFactory(
    () => QuizSessionBloc(
      getQuizQuestions: sl(),
      startQuizSession: sl(),
      submitAnswer: sl(),
      finalizeSession: sl(),
      getSession: sl(),
    ),
  );
}
