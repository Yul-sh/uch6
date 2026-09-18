import 'package:flutter_test/flutter_test.dart';
import 'package:fly_y/models/booking.dart';
import 'package:fly_y/models/lookups.dart';
import 'package:fly_y/models/tour.dart';

void main() {
  group('Разбор моделей', () {
    test('Tour.fromJson не падает при минимальном JSON', () {
      final tour = Tour.fromJson({'id': 'abc123xyz45678'});
      expect(tour.id, 'abc123xyz45678');
      expect(tour.title, '');
      expect(tour.hotelIds, isEmpty);
      expect(tour.categoryIds, isEmpty);
    });

    test('Tour.fromJson читает вложенное направление', () {
      final tour = Tour.fromJson({
        'id': 'tour00000000001',
        'title': 'Тест',
        'destination': {'id': 'dest0000000001', 'name': 'Рим'},
        'hotels': [
          {'id': 'hotel000000001'},
        ],
        'categories': [
          {'id': 'cat00000000001'},
        ],
      });
      expect(tour.destinationId, 'dest0000000001');
      expect(tour.hotelIds, ['hotel000000001']);
      expect(tour.categoryIds, ['cat00000000001']);
    });

    test('Destination.fromJson терпит null-поля', () {
      final d = Destination.fromJson({'id': 'dest0000000009'});
      expect(d.name, '');
      expect(d.country, '');
    });

    test('Booking форматирует дату и статус по-русски', () {
      final b = Booking(
        id: 'abc123xyz45678',
        tourId: 'tour00000000001',
        tourTitle: 'Тур',
        userId: 'user00000000001',
        status: 'active',
        expiresAt: DateTime(2027, 9, 1),
      );
      expect(b.subtitleRu, contains('активно до'));
      expect(b.expiresFormatted, '01.09.2027');
      expect(b.statusRu, 'активно');
    });
  });
}
