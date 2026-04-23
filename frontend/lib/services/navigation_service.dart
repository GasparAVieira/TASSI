import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_client.dart';
import 'auth_service.dart';

class NavigationService {
  Future<Map<String, dynamic>> getRoute({
    required String fromLocationId,
    required String toLocationId,
  }) async {
    final auth = AuthService();

    final response = await http.post(
      Uri.parse(ApiClient.url('/api/v1/navigation/route')),
      headers: auth.authHeaders(),
      body: jsonEncode({
        'from_location_id': fromLocationId,
        'to_location_id': toLocationId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get route: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}