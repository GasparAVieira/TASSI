class ApiClient {
  static const String baseUrl = 'http://10.0.2.2:8000';

  static String url(String path) => '$baseUrl$path';
}