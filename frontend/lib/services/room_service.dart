import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/room.dart';
import 'api_client.dart';

class RoomService {
  static const Duration _timeout = Duration(seconds: 10);

  Future<List<Room>> fetchRooms([String query = '']) async {
    try {
      final response = await http.get(
        Uri.parse(ApiClient.url('/api/v1/rooms/')),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to load rooms: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as List<dynamic>;
      final rooms = data
          .map((item) => Room.fromJson(item as Map<String, dynamic>))
          .toList();

      if (query.trim().isEmpty) {
        return rooms;
      }

      final normalizedQuery = query.toLowerCase().trim();

      return rooms.where((room) {
        return room.name.toLowerCase().contains(normalizedQuery) ||
            room.code.toLowerCase().contains(normalizedQuery) ||
            room.floor.toString().contains(normalizedQuery);
      }).toList();
    } catch (e) {
      if (e is TimeoutException) {
        throw Exception('Server request timed out');
      }
      rethrow;
    }
  }
}
