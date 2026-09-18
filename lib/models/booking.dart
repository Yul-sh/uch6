import '../data/json_codec.dart';

class Booking {
  final String id;
  final String tourId;
  final String tourTitle;
  final String userId;
  final String status;
  final DateTime expiresAt;

  const Booking({
    required this.id,
    required this.tourId,
    required this.tourTitle,
    required this.userId,
    required this.status,
    required this.expiresAt,
  });

  bool get isActive => status == 'active';

  String get statusRu => isActive ? 'активно' : 'не активно';

  String get expiresFormatted {
    final d = expiresAt.toLocal();
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}';
  }

  String get managerSubtitle =>
      'клиент $userId · $statusRu · до $expiresFormatted';

  String get subtitleRu => isActive
      ? 'активно до $expiresFormatted'
      : 'не активно · до $expiresFormatted';

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
    id: jsonId(json['id']),
    tourId: json['tourId'] != null
        ? jsonId(json['tourId'])
        : jsonId(json['tour']),
    tourTitle: jsonString(json['tourTitle']),
    userId: json['userId'] != null
        ? jsonId(json['userId'])
        : jsonId(json['user']),
    status: jsonString(json['status'], 'active'),
    expiresAt: jsonDate(json['expiresAt']) ?? DateTime.now(),
  );
}
