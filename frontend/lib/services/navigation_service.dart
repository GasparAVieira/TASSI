import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_client.dart';
import 'auth_service.dart';

class NavigationService {
  static const Duration _timeout = Duration(seconds: 15);

  Future<Map<String, dynamic>> getRoute({
    required String fromLocationId,
    required String toLocationId,
  }) async {
    final auth = AuthService();

    try {
      final response = await http.post(
        Uri.parse(ApiClient.url('/api/v1/navigation/route')),
        headers: auth.authHeaders(),
        body: jsonEncode({
          'from_location_id': fromLocationId,
          'to_location_id': toLocationId,
        }),
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to get route: ${response.statusCode}');
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      if (e is TimeoutException) {
        throw Exception('Navigation request timed out');
      }
      rethrow;
    }
  }
}
