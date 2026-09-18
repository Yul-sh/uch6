import '../data/json_codec.dart';

class Destination {
  final String id;
  final String name;
  final String country;
  final DateTime? deletedAt;

  const Destination({
    required this.id,
    required this.name,
    required this.country,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Destination copyWith({
    String? name,
    String? country,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Destination(
      id: id,
      name: name ?? this.name,
      country: country ?? this.country,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'country': country,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Destination.fromJson(Map<String, dynamic> json) => Destination(
    id: jsonId(json['id']),
    name: jsonString(json['name']),
    country: jsonString(json['country']),
    deletedAt: deletedAtFromPb(json),
  );
}

class TourCategory {
  final String id;
  final String name;
  final DateTime? deletedAt;

  const TourCategory({required this.id, required this.name, this.deletedAt});

  bool get isDeleted => deletedAt != null;

  TourCategory copyWith({
    String? name,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return TourCategory(
      id: id,
      name: name ?? this.name,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory TourCategory.fromJson(Map<String, dynamic> json) => TourCategory(
    id: jsonId(json['id']),
    name: jsonString(json['name']),
    deletedAt: deletedAtFromPb(json),
  );
}
