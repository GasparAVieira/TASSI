class Location {
  final String title;
  final String subtitle;
  final String description;
  final String imageUrl;
  final bool isWheelchairFriendly;
  bool isFavorite;

  Location({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imageUrl,
    this.isWheelchairFriendly = false,
    this.isFavorite = false,
  });

  Location copyWith({
    String? title,
    String? subtitle,
    String? description,
    String? imageUrl,
    bool? isWheelchairFriendly,
    bool? isFavorite,
  }) {
    return Location(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isWheelchairFriendly: isWheelchairFriendly ?? this.isWheelchairFriendly,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'imageUrl': imageUrl,
      'isWheelchairFriendly': isWheelchairFriendly,
      'isFavorite': isFavorite,
    };
  }

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      isWheelchairFriendly: json['isWheelchairFriendly'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }
}
