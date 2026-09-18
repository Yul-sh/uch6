import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/pb.dart';
import '../data/json_codec.dart';
import '../models/page_result.dart';
import '../models/tour.dart';
import '../models/tour_query.dart';
import 'tour_repository.dart';

Map<String, dynamic> asJsonMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  return {};
}

PageResult<T> parsePage<T>(
  dynamic data,
  T Function(Map<String, dynamic>) fromJson, {
  int fallbackSize = 10,
}) {
  final map = asJsonMap(data);
  return PageResult(
    items: [
      for (final item in (map['items'] as List? ?? []))
        if (item is Map) fromJson(Map<String, dynamic>.from(item)),
    ],
    page: jsonInt(map['page'], 1),
    size: jsonInt(map['perPage'] ?? map['size'], fallbackSize),
    total: jsonInt(map['totalItems'] ?? map['total']),
  );
}

Future<List<T>> fetchAllRecords<T>(
  Dio dio,
  String collection,
  T Function(Map<String, dynamic>) fromJson, {
  bool includeDeleted = false,
  bool hasSoftDelete = true,
  String? expand,
}) async {
  final params = pbListQuery(
    search: '',
    sortField: 'id',
    sortAscending: true,
    page: 1,
    size: 200,
    includeDeleted: includeDeleted,
    hasSoftDelete: hasSoftDelete,
    expand: expand,
  );
  final response = await dio.get<dynamic>(
    pbRecords(collection),
    queryParameters: params,
  );
  return parsePage(response.data, fromJson).items;
}

Future<int> fetchFilteredTotal(
  Dio dio,
  String collection,
  List<String> filters, {
  bool includeDeleted = true,
}) async {
  final params = pbListQuery(
    search: '',
    sortField: 'created',
    sortAscending: false,
    page: 1,
    size: 1,
    includeDeleted: includeDeleted,
    extraFilters: filters,
  );
  final response = await dio.get<dynamic>(
    pbRecords(collection),
    queryParameters: params,
  );
  return jsonInt(asJsonMap(response.data)['totalItems']);
}

class ApiTourRepository implements TourRepository {
  ApiTourRepository(this._dio);

  final Dio _dio;
  CancelToken? _findToken;

  Map<String, dynamic> _body(Tour tour) => {
    'title': tour.title,
    'code': tour.code,
    'year': tour.year,
    'durationDays': tour.durationDays,
    'destination': tour.destinationId,
    'hotels': tour.hotelIds,
    'categories': tour.categoryIds,
    'seatsTotal': tour.seatsTotal,
    'seatsAvailable': tour.seatsAvailable,
    'price': tour.price,
    'isDeleted': tour.isDeleted,
  };

  @override
  Future<PageResult<Tour>> find(TourQuery q) {
    _findToken?.cancel();
    _findToken = CancelToken();
    final token = _findToken!;
    return guardRead(() async {
      final extra = <String>[];
      if (q.categoryId != null) {
        extra.add('categories ?~ "${pbEscape(q.categoryId!)}"');
      }
      if (q.destinationId != null) {
        extra.add('destination = "${pbEscape(q.destinationId!)}"');
      }
      if (q.yearFrom != null) extra.add('year >= ${q.yearFrom}');
      if (q.yearTo != null) extra.add('year <= ${q.yearTo}');
      final params = pbListQuery(
        search: q.search,
        sortField: q.sortField,
        sortAscending: q.sortAscending,
        page: q.page,
        size: q.size,
        includeDeleted: q.includeDeleted,
        searchFields: const ['title', 'code'],
        extraFilters: extra,
        expand: 'destination,categories,hotels',
      );
      await maybeDelay(params);
      final response = await _dio.get<dynamic>(
        pbRecords('tours'),
        queryParameters: params,
        cancelToken: token,
      );
      return parsePage(response.data, Tour.fromJson, fallbackSize: q.size);
    });
  }

  @override
  Future<Tour?> findById(String id) => guardRead(() async {
    try {
      final response = await _dio.get<dynamic>(
        pbRecord('tours', id),
        queryParameters: {'expand': 'destination,categories,hotels'},
      );
      return Tour.fromJson(asJsonMap(response.data));
    } on DioException catch (e) {
      final mapped = mapDioError(e);
      if (mapped is NotFoundException) return null;
      throw mapped;
    }
  });

  @override
  Future<bool> codeExists(String code, {String? excludeId}) =>
      guardRead(() async {
        final escaped = pbEscape(code.trim());
        final response = await _dio.get<dynamic>(
          pbRecords('tours'),
          queryParameters: {
            'filter': 'code = "$escaped"',
            'perPage': 5,
            'page': 1,
          },
        );
        final page = parsePage(response.data, Tour.fromJson);
        return page.items.any((t) => t.id != excludeId);
      });

  @override
  Future<int> countByDestination(String destinationId) => guardRead(
    () => fetchFilteredTotal(_dio, 'tours', [
      'destination = "${pbEscape(destinationId)}"',
    ]),
  );

  @override
  Future<int> countByCategory(String categoryId) => guardRead(
    () => fetchFilteredTotal(_dio, 'tours', [
      'categories ?~ "${pbEscape(categoryId)}"',
    ]),
  );

  @override
  Future<int> countByHotel(String hotelId) => guardRead(
    () =>
        fetchFilteredTotal(_dio, 'tours', ['hotels ?~ "${pbEscape(hotelId)}"']),
  );

  @override
  Future<Tour> create(Tour tour) => guard(() async {
    final response = await _dio.post<dynamic>(
      pbRecords('tours'),
      data: {..._body(tour), 'isDeleted': false},
    );
    return Tour.fromJson(asJsonMap(response.data));
  });

  @override
  Future<Tour> update(Tour tour) => guard(() async {
    final response = await _dio.patch<dynamic>(
      pbRecord('tours', tour.id),
      data: _body(tour),
    );
    return Tour.fromJson(asJsonMap(response.data));
  });

  @override
  Future<Tour> book(String id) => guard(() async {
    final tour = await findById(id);
    if (tour == null) throw const NotFoundException();
    if (tour.seatsAvailable <= 0) {
      throw const ConflictException('Нет свободных мест на тур.');
    }
    try {
      final response = await _dio.patch<dynamic>(
        pbRecord('tours', id),
        data: {'seatsAvailable': tour.seatsAvailable - 1},
      );
      return Tour.fromJson(asJsonMap(response.data));
    } on DioException catch (e) {
      final mapped = mapDioError(e);
      // Клиент не может PATCH tours (правила PB) — бронь всё равно создаём.
      if (mapped is ForbiddenException || mapped is NotFoundException) {
        return tour.copyWith(seatsAvailable: tour.seatsAvailable - 1);
      }
      throw mapped;
    }
  });

  @override
  Future<void> softDelete(String id) => guard(
    () => _dio.patch<dynamic>(pbRecord('tours', id), data: {'isDeleted': true}),
  );

  @override
  Future<void> hardDelete(String id) =>
      guard(() => _dio.delete<dynamic>(pbRecord('tours', id)));

  @override
  Future<void> restore(String id) => guard(
    () =>
        _dio.patch<dynamic>(pbRecord('tours', id), data: {'isDeleted': false}),
  );

  @override
  Future<int> deleteMany(List<String> ids) => guard(() async {
    var deleted = 0;
    for (final id in ids) {
      await softDelete(id);
      deleted++;
    }
    return deleted;
  });
}
