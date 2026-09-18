import '../data/json_codec.dart';

class Hotel {
  final String id;
  final String name;
  final String country;
  final String city;
  final int stars;
  final DateTime? deletedAt;

  const Hotel({
    required this.id,
    required this.name,
    required this.country,
    required this.city,
    required this.stars,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Hotel copyWith({
    String? name,
    String? country,
    String? city,
    int? stars,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Hotel(
      id: id,
      name: name ?? this.name,
      country: country ?? this.country,
      city: city ?? this.city,
      stars: stars ?? this.stars,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'country': country,
    'city': city,
    'stars': stars,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Hotel.fromJson(Map<String, dynamic> json) => Hotel(
    id: jsonId(json['id']),
    name: jsonString(json['name']),
    country: jsonString(json['country']),
    city: jsonString(json['city']),
    stars: jsonInt(json['stars']),
    deletedAt: deletedAtFromPb(json),
  );
}
