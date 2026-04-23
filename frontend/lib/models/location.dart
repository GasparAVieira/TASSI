class Location {
  final String id;
  final String name;
  final String type;
  final String? description;
  final String? imageUrl;
  final bool isWheelchairFriendly;
  bool isFavorite;

  Location({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    this.imageUrl,
    this.isWheelchairFriendly = false,
    this.isFavorite = false,
  });

  Location copyWith({
    String? id,
    String? name,
    String? type,
    String? description,
    String? imageUrl,
    bool? isWheelchairFriendly,
    bool? isFavorite,
  }) {
    return Location(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isWheelchairFriendly: isWheelchairFriendly ?? this.isWheelchairFriendly,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'description': description,
      'imageUrl': imageUrl,
      'isWheelchairFriendly': isWheelchairFriendly,
      'isFavorite': isFavorite,
    };
  }

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      type: json['type']?.toString() ?? '',
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String? ?? json['model_url'] as String?,
      isWheelchairFriendly: json['is_accessible'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }
}
