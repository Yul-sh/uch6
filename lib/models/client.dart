import '../data/json_codec.dart';
import 'loyalty_card.dart';

class Client {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final LoyaltyCard card;
  final DateTime? deletedAt;

  const Client({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.card,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
  String get fullName => '$lastName $firstName';

  Client copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    LoyaltyCard? card,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Client(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      card: card ?? this.card,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'phone': phone,
    'card': card.toJson(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Client.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? cardJson;
    final card = json['card'];
    if (card is Map) {
      cardJson = Map<String, dynamic>.from(card);
    } else {
      final expand = json['expand'];
      if (expand is Map) {
        final cards = expand['loyalty_cards'] ?? expand['loyalty_card'];
        if (cards is List && cards.isNotEmpty && cards.first is Map) {
          cardJson = Map<String, dynamic>.from(cards.first as Map);
        } else if (cards is Map) {
          cardJson = Map<String, dynamic>.from(cards);
        }
      }
    }
    return Client(
      id: jsonId(json['id']),
      firstName: jsonString(json['firstName']),
      lastName: jsonString(json['lastName']),
      email: jsonString(json['email']),
      phone: jsonString(json['phone']),
      card: LoyaltyCard.fromJson(cardJson),
      deletedAt: deletedAtFromPb(json),
    );
  }
}
