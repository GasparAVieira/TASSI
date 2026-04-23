import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/location.dart';
import 'api_client.dart';

class LocationService {
  Future<List<Location>> fetchLocations([String query = '']) async {
    final response = await http.get(
      Uri.parse(ApiClient.url('/api/v1/locations/')),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load locations: ${response.body}');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    final locations = data
        .map((item) => Location.fromJson(item as Map<String, dynamic>))
        .toList();

    if (query.trim().isEmpty) {
      return locations;
    }

    final normalizedQuery = query.toLowerCase().trim();

    return locations.where((location) {
      return location.name.toLowerCase().contains(normalizedQuery) ||
          (location.description?.toLowerCase().contains(normalizedQuery) ?? false) ||
          location.type.toLowerCase().contains(normalizedQuery);
    }).toList();
  }
}