import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/pb.dart';
import '../models/booking.dart';
import 'api_tour_repository.dart';

class BookingRepository {
  BookingRepository(this._dio);
  final Dio _dio;

  Future<List<Booking>> _list({String? filter}) async {
    final response = await _dio.get<dynamic>(
      pbRecords('bookings'),
      queryParameters: {
        'perPage': 200,
        'page': 1,
        'sort': '-id',
        if (filter != null && filter.isNotEmpty) 'filter': filter,
      },
    );
    final items = asJsonMap(response.data)['items'] as List? ?? [];
    return [
      for (final item in items)
        if (item is Map) Booking.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  Future<List<Booking>> all() => guard(() => _list());

  Future<List<Booking>> mine(String userId) => guard(
    () => _list(filter: 'user = "${pbEscape(userId)}"'),
  );

  Future<Booking> create({
    required String tourId,
    required String userId,
    required String tourTitle,
    int days = 14,
  }) => guard(() async {
    final response = await _dio.post<dynamic>(
      pbRecords('bookings'),
      data: {
        'tour': tourId,
        'user': userId,
        'tourTitle': tourTitle,
        'status': 'active',
        'expiresAt': DateTime.now()
            .toUtc()
            .add(Duration(days: days))
            .toIso8601String(),
      },
    );
    return Booking.fromJson(asJsonMap(response.data));
  });

  Future<Booking> extend(String id, {int days = 7}) => guard(() async {
    final current = await _dio.get<dynamic>(pbRecord('bookings', id));
    final booking = Booking.fromJson(asJsonMap(current.data));
    final response = await _dio.patch<dynamic>(
      pbRecord('bookings', id),
      data: {
        'expiresAt': booking.expiresAt
            .toUtc()
            .add(Duration(days: days))
            .toIso8601String(),
        'status': 'active',
      },
    );
    return Booking.fromJson(asJsonMap(response.data));
  });

  Future<Booking> close(String id) => guard(() async {
    final response = await _dio.patch<dynamic>(
      pbRecord('bookings', id),
      data: {'status': 'closed'},
    );
    return Booking.fromJson(asJsonMap(response.data));
  });

  Future<Booking> reopen(String id) => guard(() async {
    final response = await _dio.patch<dynamic>(
      pbRecord('bookings', id),
      data: {
        'status': 'active',
        'expiresAt': DateTime.now()
            .toUtc()
            .add(const Duration(days: 14))
            .toIso8601String(),
      },
    );
    return Booking.fromJson(asJsonMap(response.data));
  });
}
