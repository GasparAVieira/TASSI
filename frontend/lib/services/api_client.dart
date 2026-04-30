class ApiClient {
  static const String baseUrl = 'https://tassi.onrender.com';

  static String url(String path) => '$baseUrl$path';
}