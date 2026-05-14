import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_client.dart';
import 'auth_service.dart';
import 'accessibility_profile_service.dart';

class NavigationService {
  static const Duration _timeout = Duration(seconds: 15);

  Future<Map<String, dynamic>> getRoute({
    required String fromLocationId,
    required String toLocationId,
  }) async {
    final accessibilityService = AccessibilityProfileService();

    try {
      final uri = Uri.parse(ApiClient.url('/api/v1/navigation/route')).replace(
        queryParameters: {
          'from_location_id': fromLocationId,
          'to_location_id': toLocationId,
          'accessibility_profile': accessibilityService.selectedProfile.serverValue,
        },
      );

      final response = await http.get(uri);

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
