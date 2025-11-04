class ApiConfig {
  // Base URLs des services
  static const String quizServiceUrl = 'http://localhost:8080/api/v1';
  // static const String geographyServiceUrl = 'http://localhost:8081/api/v1';
  // static const String mapServiceUrl = 'http://localhost:8082/api/v1';

  // Sur Android émulateur : http://10.0.2.2:8080/api/v1
  // Sur iOS simulateur : http://localhost:8080/api/v1
  // Sur device physique : http://192.168.X.X:8080/api/v1

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Pour Android Emulator, utiliser 10.0.2.2 au lieu de localhost
  static String get quizServiceUrlForEmulator =>
      quizServiceUrl.replaceAll('localhost', '10.0.2.2');

  // Headers communs
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
}
