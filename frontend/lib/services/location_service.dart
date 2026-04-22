import 'dart:async';

import '../models/location.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final List<Location> _locations = [
    Location(
      title: 'B401',
      subtitle: 'Classroom',
      description: 'Building B, Floor 4, Room 1. Equipped with high-end projectors and seating for 40 students.',
      imageUrl: 'https://picsum.photos/id/1/600/300',
      isWheelchairFriendly: true,
    ),
    Location(
      title: 'Library',
      subtitle: 'Study Area',
      description: 'Central library, 2nd floor. Silent zone for focused research and group study rooms.',
      imageUrl: 'https://picsum.photos/id/24/600/300',
      isWheelchairFriendly: true,
      isFavorite: true,
    ),
    Location(
      title: 'Cafeteria',
      subtitle: 'Food Court',
      description: 'Ground floor. Wide variety of healthy snacks and full meals available daily.',
      imageUrl: 'https://picsum.photos/id/42/600/300',
      isWheelchairFriendly: false,
    ),
    Location(
      title: 'Auditorium A1',
      subtitle: 'Event Hall',
      description: 'Main auditorium for guest lectures and ceremonies. Capacity: 500 people.',
      imageUrl: 'https://picsum.photos/id/60/600/300',
      isWheelchairFriendly: true,
    ),
    Location(
      title: 'Lab 102',
      subtitle: 'Computer Lab',
      description: 'Advanced computing lab with latest GPUs for AI research.',
      imageUrl: 'https://picsum.photos/id/160/600/300',
      isWheelchairFriendly: false,
    ),
    Location(
      title: 'Student Lounge',
      subtitle: 'Relaxation Area',
      description: 'Comfortable sofas, board games, and a coffee machine for student breaks.',
      imageUrl: 'https://picsum.photos/id/180/600/300',
      isWheelchairFriendly: true,
    ),
    Location(
      title: 'Admin Office',
      subtitle: 'Administration',
      description: 'Main office for student affairs, registrations, and general inquiries.',
      imageUrl: 'https://picsum.photos/id/201/600/300',
      isWheelchairFriendly: true,
    ),
    Location(
      title: 'Gym',
      subtitle: 'Sports Center',
      description: 'Fully equipped fitness center with cardio and weightlifting sections.',
      imageUrl: 'https://picsum.photos/id/250/600/300',
      isWheelchairFriendly: false,
    ),
    Location(
      title: 'Parking Lot P1',
      subtitle: 'Outdoor Parking',
      description: 'Main parking area for staff and visitors. 24/7 security surveillance.',
      imageUrl: 'https://picsum.photos/id/301/600/300',
      isWheelchairFriendly: true,
    ),
  ];

  Future<List<Location>> fetchLocations([String query = '']) async {
    await Future.delayed(const Duration(milliseconds: 450));

    if (query.toLowerCase() == 'error') {
      throw Exception('Simulated API error.');
    }

    if (query.isEmpty) {
      return List<Location>.from(_locations);
    }

    return _locations.where((location) {
      final searchTarget = '${location.title} ${location.subtitle}'.toLowerCase();
      return searchTarget.contains(query.toLowerCase());
    }).toList();
  }

  Future<void> toggleFavorite(Location location) async {
    await Future.delayed(const Duration(milliseconds: 250));
    location.isFavorite = !location.isFavorite;
  }

  List<Location> get cachedLocations => List.unmodifiable(_locations);
}
