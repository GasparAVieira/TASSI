class LocationOption {
  final String id;
  final String name;
  final String? type;
  final int? floor;

  LocationOption({
    required this.id,
    required this.name,
    this.type,
    this.floor,
  });

  factory LocationOption.fromJson(Map<String, dynamic> json) {
    return LocationOption(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String?,
      floor: json['floor'] as int?,
    );
  }

  @override
  String toString() => name;
}