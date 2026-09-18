import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/pb.dart';
import '../data/json_codec.dart';
import '../models/app_user.dart';
import 'api_tour_repository.dart';

class AdminRepository {
  AdminRepository(this._dio);
  final Dio _dio;

  Future<List<AppUser>> users() => guard(() async {
    final response = await _dio.get<dynamic>(
      pbRecords('users'),
      queryParameters: {'perPage': 200, 'page': 1, 'sort': 'email'},
    );
    final items = asJsonMap(response.data)['items'] as List? ?? [];
    return [
      for (final item in items)
        if (item is Map) AppUser.fromJson(Map<String, dynamic>.from(item)),
    ];
  });

  Future<AppUser> setRole(String id, String role) => guard(() async {
    final response = await _dio.patch<dynamic>(
      pbRecord('users', id),
      data: {'role': role},
    );
    return AppUser.fromJson(asJsonMap(response.data));
  });

  Future<Map<String, int>> stats() => guard(() async {
    Future<int> count(String collection, {String? filter}) async {
      final response = await _dio.get<dynamic>(
        pbRecords(collection),
        queryParameters: {
          'page': 1,
          'perPage': 1,
          'filter': ?filter,
        },
      );
      return jsonInt(asJsonMap(response.data)['totalItems']);
    }

    final tours = await count(
      'tours',
      filter: '(isDeleted = false || isDeleted = null)',
    );
    final hotels = await count(
      'hotels',
      filter: '(isDeleted = false || isDeleted = null)',
    );
    final clients = await count(
      'clients',
      filter: '(isDeleted = false || isDeleted = null)',
    );
    final bookings = await count('bookings');
    final activeBookings = await count('bookings', filter: 'status = "active"');
    final users = await count('users');
    return {
      'tours': tours,
      'hotels': hotels,
      'clients': clients,
      'bookings': bookings,
      'activeBookings': activeBookings,
      'users': users,
    };
  });
}
