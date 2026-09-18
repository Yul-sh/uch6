import '../data/json_codec.dart';

class Tour {
  final String id;
  final String title;
  final String code;
  final int year;
  final int durationDays;
  final String destinationId;
  final List<String> hotelIds;
  final List<String> categoryIds;
  final int seatsTotal;
  final int seatsAvailable;
  final int price;
  final DateTime? deletedAt;
  final String? destinationLabel;
  final String? categoriesLabel;
  final String? hotelsLabel;

  const Tour({
    required this.id,
    required this.title,
    required this.code,
    required this.year,
    required this.durationDays,
    required this.destinationId,
    required this.hotelIds,
    required this.categoryIds,
    required this.seatsTotal,
    required this.seatsAvailable,
    required this.price,
    this.deletedAt,
    this.destinationLabel,
    this.categoriesLabel,
    this.hotelsLabel,
  });

  bool get isDeleted => deletedAt != null;

  Tour copyWith({
    String? title,
    String? code,
    int? year,
    int? durationDays,
    String? destinationId,
    List<String>? hotelIds,
    List<String>? categoryIds,
    int? seatsTotal,
    int? seatsAvailable,
    int? price,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    String? destinationLabel,
    String? categoriesLabel,
    String? hotelsLabel,
  }) {
    return Tour(
      id: id,
      title: title ?? this.title,
      code: code ?? this.code,
      year: year ?? this.year,
      durationDays: durationDays ?? this.durationDays,
      destinationId: destinationId ?? this.destinationId,
      hotelIds: hotelIds ?? this.hotelIds,
      categoryIds: categoryIds ?? this.categoryIds,
      seatsTotal: seatsTotal ?? this.seatsTotal,
      seatsAvailable: seatsAvailable ?? this.seatsAvailable,
      price: price ?? this.price,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      destinationLabel: destinationLabel ?? this.destinationLabel,
      categoriesLabel: categoriesLabel ?? this.categoriesLabel,
      hotelsLabel: hotelsLabel ?? this.hotelsLabel,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'code': code,
    'year': year,
    'durationDays': durationDays,
    'destinationId': destinationId,
    'hotelIds': hotelIds,
    'categoryIds': categoryIds,
    'seatsTotal': seatsTotal,
    'seatsAvailable': seatsAvailable,
    'price': price,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Tour.fromJson(Map<String, dynamic> json) {
    final expand = json['expand'] is Map
        ? Map<String, dynamic>.from(json['expand'] as Map)
        : const <String, dynamic>{};

    String? destLabel;
    final destExp = expand['destination'];
    if (destExp is Map) {
      destLabel = jsonString(destExp['name']);
      if (destLabel.isEmpty) destLabel = null;
    }

    String? catsLabel;
    final catsExp = expand['categories'];
    if (catsExp is List && catsExp.isNotEmpty) {
      final names = [
        for (final item in catsExp)
          if (item is Map) jsonString(item['name']),
      ].where((n) => n.isNotEmpty);
      if (names.isNotEmpty) catsLabel = names.join(', ');
    }

    String? hotelsLab;
    final hotelsExp = expand['hotels'];
    if (hotelsExp is List && hotelsExp.isNotEmpty) {
      final names = [
        for (final item in hotelsExp)
          if (item is Map) jsonString(item['name']),
      ].where((n) => n.isNotEmpty);
      if (names.isNotEmpty) hotelsLab = names.join(', ');
    }

    return Tour(
      id: jsonId(json['id']),
      title: jsonString(json['title']),
      code: jsonString(json['code']),
      year: jsonInt(json['year']),
      durationDays: jsonInt(json['durationDays']),
      destinationId: json['destinationId'] != null
          ? jsonId(json['destinationId'])
          : jsonId(json['destination']),
      hotelIds: json['hotelIds'] != null
          ? jsonIdList(json['hotelIds'])
          : jsonIdList(json['hotels']),
      categoryIds: json['categoryIds'] != null
          ? jsonIdList(json['categoryIds'])
          : jsonIdList(json['categories']),
      seatsTotal: jsonInt(json['seatsTotal']),
      seatsAvailable: jsonInt(json['seatsAvailable']),
      price: jsonInt(json['price']),
      deletedAt: deletedAtFromPb(json),
      destinationLabel: destLabel,
      categoriesLabel: catsLabel,
      hotelsLabel: hotelsLab,
    );
  }
}
