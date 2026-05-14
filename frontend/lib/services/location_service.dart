import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import 'auth_service.dart';

class LocationService {
  final auth = AuthService();

  Future<List<dynamic>> fetchLocations() async {
    try {
      final uri = Uri.parse(ApiClient.url("/api/v1/locations/"));
      final response = await http.get(
        uri,
        headers: auth.authHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Error fetching locations: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Location Service Exception: $e");
      return [];
    }
  }
}