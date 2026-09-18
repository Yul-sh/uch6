import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/pb.dart';
import '../models/hotel.dart';
import '../models/hotel_query.dart';
import '../models/page_result.dart';
import 'api_tour_repository.dart';
import 'hotel_repository.dart';

class ApiHotelRepository implements HotelRepository {
  ApiHotelRepository(this._dio);
  final Dio _dio;
  CancelToken? _findToken;

  Map<String, dynamic> _body(Hotel hotel) => {
    'name': hotel.name,
    'country': hotel.country,
    'city': hotel.city,
    'stars': hotel.stars,
    'isDeleted': hotel.isDeleted,
  };

  @override
  Future<PageResult<Hotel>> find(HotelQuery q) {
    _findToken?.cancel();
    _findToken = CancelToken();
    final token = _findToken!;
    return guardRead(() async {
      final extra = <String>[];
      if (q.country != null && q.country!.isNotEmpty) {
        extra.add('country = "${pbEscape(q.country!)}"');
      }
      if (q.stars != null) extra.add('stars = ${q.stars}');
      final params = pbListQuery(
        search: q.search,
        sortField: q.sortField,
        sortAscending: q.sortAscending,
        page: q.page,
        size: q.size,
        includeDeleted: q.includeDeleted,
        searchFields: const ['name', 'city', 'country'],
        extraFilters: extra,
      );
      await maybeDelay(params);
      final response = await _dio.get<dynamic>(
        pbRecords('hotels'),
        queryParameters: params,
        cancelToken: token,
      );
      return parsePage(response.data, Hotel.fromJson, fallbackSize: q.size);
    });
  }

  @override
  Future<List<Hotel>> findAll({bool includeDeleted = false}) => guardRead(
    () => fetchAllRecords(
      _dio,
      'hotels',
      Hotel.fromJson,
      includeDeleted: includeDeleted,
    ),
  );

  @override
  Future<Hotel?> findById(String id) => guardRead(() async {
    try {
      final response = await _dio.get<dynamic>(pbRecord('hotels', id));
      return Hotel.fromJson(asJsonMap(response.data));
    } on DioException catch (e) {
      final mapped = mapDioError(e);
      if (mapped is NotFoundException) return null;
      throw mapped;
    }
  });

  @override
  Future<Hotel> create(Hotel hotel) => guard(() async {
    final response = await _dio.post<dynamic>(
      pbRecords('hotels'),
      data: {..._body(hotel), 'isDeleted': false},
    );
    return Hotel.fromJson(asJsonMap(response.data));
  });

  @override
  Future<Hotel> update(Hotel hotel) => guard(() async {
    final response = await _dio.patch<dynamic>(
      pbRecord('hotels', hotel.id),
      data: _body(hotel),
    );
    return Hotel.fromJson(asJsonMap(response.data));
  });

  @override
  Future<void> softDelete(String id) => guard(
    () =>
        _dio.patch<dynamic>(pbRecord('hotels', id), data: {'isDeleted': true}),
  );

  @override
  Future<void> hardDelete(String id) =>
      guard(() => _dio.delete<dynamic>(pbRecord('hotels', id)));

  @override
  Future<void> restore(String id) => guard(
    () =>
        _dio.patch<dynamic>(pbRecord('hotels', id), data: {'isDeleted': false}),
  );

  @override
  Future<int> deleteMany(List<String> ids) => guard(() async {
    var n = 0;
    for (final id in ids) {
      await softDelete(id);
      n++;
    }
    return n;
  });
}
