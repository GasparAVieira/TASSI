class Room {
  final String id;
  final String buildingId;
  final String locationId;
  final String code;
  final String name;
  final int floor;
  final String? mpUrl;
  final bool isWheelchairFriendly;
  bool isFavorite;

  Room({
    required this.id,
    required this.buildingId,
    required this.locationId,
    required this.code,
    required this.name,
    required this.floor,
    this.mpUrl,
    this.isWheelchairFriendly = false,
    this.isFavorite = false,
  });

  Room copyWith({
    String? id,
    String? buildingId,
    String? locationId,
    String? code,
    String? name,
    int? floor,
    String? mpUrl,
    bool? isWheelchairFriendly,
    bool? isFavorite,
  }) {
    return Room(
      id: id ?? this.id,
      buildingId: buildingId ?? this.buildingId,
      locationId: locationId ?? this.locationId,
      code: code ?? this.code,
      name: name ?? this.name,
      floor: floor ?? this.floor,
      mpUrl: mpUrl ?? this.mpUrl,
      isWheelchairFriendly: isWheelchairFriendly ?? this.isWheelchairFriendly,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'building_id': buildingId,
      'location_id': locationId,
      'code': code,
      'name': name,
      'floor': floor,
      'mp_url': mpUrl,
      'is_accessible': isWheelchairFriendly,
      'isFavorite': isFavorite,
    };
  }

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id']?.toString() ?? '',
      buildingId: json['building_id'] as String? ?? '',
      locationId: json['location_id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      floor: json['floor'] as int? ?? 0,
      mpUrl: json['mp_url'] as String?,
      isWheelchairFriendly: json['is_accessible'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }
}
