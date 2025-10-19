import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../config/api_config.dart';

class DioClient{
  late final Dio _dio;
  final Logger _logger = Logger();

  DioClient(){
    _dio = Dio(BaseOptions(
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: ApiConfig.headers
    ));

    // intercepteurs pour logging
    _dio.interceptors.add(
      InterceptorsWrapper(
          onRequest: (options, handler){
        _logger.d('-> ${options.method} ${options.uri}');
        _logger.d('Headers: ${options.headers}');
        if(options.data != null){
          _logger.d('Body: ${options.data}');
        }
        handler.next(options);
      },
        onResponse: (response, handler) {
          _logger.i('← ${response.statusCode} ${response.requestOptions.uri}');
          _logger.d('Response: ${response.data}');
          handler.next(response);
        },
        onError: (error, handler) {
    _logger.e('✗ ${error.requestOptions.method} ${error.requestOptions.uri}');
    _logger.e('Error: ${error.message}');
    if (error.response != null) {
    _logger.e('Response: ${error.response?.data}');
    }
    handler.next(error);
    },
      )
    );
  }
  Dio get dio => _dio;


  // GET request
  Future<Response> get(
      String url, {
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    return await _dio.get(
      url,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // POST request
  Future<Response> post(
      String url, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    return await _dio.post(
      url,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // PUT request
  Future<Response> put(
      String url, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    return await _dio.put(
      url,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // DELETE request
  Future<Response> delete(
      String url, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    return await _dio.delete(
      url,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}