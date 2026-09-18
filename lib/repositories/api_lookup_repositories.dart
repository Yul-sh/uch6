import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/pb.dart';
import '../models/catalog_query.dart';
import '../models/lookups.dart';
import '../models/page_result.dart';
import 'api_tour_repository.dart';
import 'lookup_repositories.dart';

class ApiDestinationRepository implements DestinationRepository {
  ApiDestinationRepository(this._dio);
  final Dio _dio;
  CancelToken? _findToken;

  Map<String, dynamic> _body(Destination item) => {
    'name': item.name,
    'country': item.country,
    'isDeleted': item.isDeleted,
  };

  @override
  Future<PageResult<Destination>> find(CatalogQuery q) {
    _findToken?.cancel();
    _findToken = CancelToken();
    final token = _findToken!;
    return guardRead(() async {
      final extra = <String>[];
      if (q.country != null && q.country!.isNotEmpty) {
        extra.add('country = "${pbEscape(q.country!)}"');
      }
      final params = pbListQuery(
        search: q.search,
        sortField: q.sortField,
        sortAscending: q.sortAscending,
        page: q.page,
        size: q.size,
        includeDeleted: q.includeDeleted,
        searchFields: const ['name', 'country'],
        extraFilters: extra,
      );
      await maybeDelay(params);
      final response = await _dio.get<dynamic>(
        pbRecords('destinations'),
        queryParameters: params,
        cancelToken: token,
      );
      return parsePage(
        response.data,
        Destination.fromJson,
        fallbackSize: q.size,
      );
    });
  }

  @override
  Future<List<Destination>> findAll({bool includeDeleted = false}) => guardRead(
    () => fetchAllRecords(
      _dio,
      'destinations',
      Destination.fromJson,
      includeDeleted: includeDeleted,
    ),
  );

  @override
  Future<Destination?> findById(String id) => guardRead(() async {
    try {
      final response = await _dio.get<dynamic>(pbRecord('destinations', id));
      return Destination.fromJson(asJsonMap(response.data));
    } on DioException catch (e) {
      final mapped = mapDioError(e);
      if (mapped is NotFoundException) return null;
      throw mapped;
    }
  });

  @override
  Future<Destination> create(Destination item) => guard(() async {
    final response = await _dio.post<dynamic>(
      pbRecords('destinations'),
      data: {..._body(item), 'isDeleted': false},
    );
    return Destination.fromJson(asJsonMap(response.data));
  });

  @override
  Future<Destination> update(Destination item) => guard(() async {
    final response = await _dio.patch<dynamic>(
      pbRecord('destinations', item.id),
      data: _body(item),
    );
    return Destination.fromJson(asJsonMap(response.data));
  });

  @override
  Future<void> softDelete(String id) => guard(
    () => _dio.patch<dynamic>(
      pbRecord('destinations', id),
      data: {'isDeleted': true},
    ),
  );

  @override
  Future<void> hardDelete(String id) =>
      guard(() => _dio.delete<dynamic>(pbRecord('destinations', id)));

  @override
  Future<void> restore(String id) => guard(
    () => _dio.patch<dynamic>(
      pbRecord('destinations', id),
      data: {'isDeleted': false},
    ),
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

class ApiCategoryRepository implements CategoryRepository {
  ApiCategoryRepository(this._dio);
  final Dio _dio;
  CancelToken? _findToken;

  @override
  Future<PageResult<TourCategory>> find(CatalogQuery q) {
    _findToken?.cancel();
    _findToken = CancelToken();
    final token = _findToken!;
    return guardRead(() async {
      final params = pbListQuery(
        search: q.search,
        sortField: q.sortField,
        sortAscending: q.sortAscending,
        page: q.page,
        size: q.size,
        includeDeleted: q.includeDeleted,
        searchFields: const ['name'],
      );
      await maybeDelay(params);
      final response = await _dio.get<dynamic>(
        pbRecords('categories'),
        queryParameters: params,
        cancelToken: token,
      );
      return parsePage(
        response.data,
        TourCategory.fromJson,
        fallbackSize: q.size,
      );
    });
  }

  @override
  Future<List<TourCategory>> findAll({bool includeDeleted = false}) =>
      guardRead(
        () => fetchAllRecords(
          _dio,
          'categories',
          TourCategory.fromJson,
          includeDeleted: includeDeleted,
        ),
      );

  @override
  Future<TourCategory?> findById(String id) => guardRead(() async {
    try {
      final response = await _dio.get<dynamic>(pbRecord('categories', id));
      return TourCategory.fromJson(asJsonMap(response.data));
    } on DioException catch (e) {
      final mapped = mapDioError(e);
      if (mapped is NotFoundException) return null;
      throw mapped;
    }
  });

  @override
  Future<TourCategory> create(TourCategory item) => guard(() async {
    final response = await _dio.post<dynamic>(
      pbRecords('categories'),
      data: {'name': item.name, 'isDeleted': false},
    );
    return TourCategory.fromJson(asJsonMap(response.data));
  });

  @override
  Future<TourCategory> update(TourCategory item) => guard(() async {
    final response = await _dio.patch<dynamic>(
      pbRecord('categories', item.id),
      data: {'name': item.name, 'isDeleted': item.isDeleted},
    );
    return TourCategory.fromJson(asJsonMap(response.data));
  });

  @override
  Future<void> softDelete(String id) => guard(
    () => _dio.patch<dynamic>(
      pbRecord('categories', id),
      data: {'isDeleted': true},
    ),
  );

  @override
  Future<void> hardDelete(String id) =>
      guard(() => _dio.delete<dynamic>(pbRecord('categories', id)));

  @override
  Future<void> restore(String id) => guard(
    () => _dio.patch<dynamic>(
      pbRecord('categories', id),
      data: {'isDeleted': false},
    ),
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
