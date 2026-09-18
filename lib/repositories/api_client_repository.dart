import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/pb.dart';
import '../models/catalog_query.dart';
import '../models/client.dart';
import '../models/page_result.dart';
import 'api_tour_repository.dart';
import 'client_repository.dart';

class ApiClientRepository implements ClientRepository {
  ApiClientRepository(this._dio);
  final Dio _dio;
  CancelToken? _findToken;

  Map<String, dynamic> _clientBody(Client item) => {
    'firstName': item.firstName,
    'lastName': item.lastName,
    'email': item.email,
    'phone': item.phone,
    'isDeleted': item.isDeleted,
  };

  Future<Client> _withCard(Map<String, dynamic> clientJson) async {
    final id = asJsonMap(clientJson)['id']?.toString() ?? '';
    if (id.isEmpty) return Client.fromJson(clientJson);
    try {
      final cards = await _dio.get<dynamic>(
        pbRecords('loyalty_cards'),
        queryParameters: {
          'filter': 'client = "${pbEscape(id)}"',
          'perPage': 1,
          'page': 1,
        },
      );
      final items = asJsonMap(cards.data)['items'] as List? ?? [];
      if (items.isNotEmpty && items.first is Map) {
        clientJson = {
          ...clientJson,
          'card': Map<String, dynamic>.from(items.first as Map),
        };
      }
    } catch (_) {}
    return Client.fromJson(clientJson);
  }

  @override
  Future<PageResult<Client>> find(CatalogQuery q) {
    _findToken?.cancel();
    _findToken = CancelToken();
    final token = _findToken!;
    return guardRead(() async {
      final extra = <String>[];
      if (q.status != null && q.status!.isNotEmpty) {
        // status lives on loyalty card — filter clients after load if needed
      }
      final params = pbListQuery(
        search: q.search,
        sortField: q.sortField == 'fullName' ? 'lastName' : q.sortField,
        sortAscending: q.sortAscending,
        page: q.page,
        size: q.size,
        includeDeleted: q.includeDeleted,
        searchFields: const ['firstName', 'lastName', 'email', 'phone'],
        extraFilters: extra,
      );
      await maybeDelay(params);
      final response = await _dio.get<dynamic>(
        pbRecords('clients'),
        queryParameters: params,
        cancelToken: token,
      );
      final page = parsePage(response.data, (m) => m, fallbackSize: q.size);
      final items = <Client>[];
      for (final raw in page.items) {
        items.add(await _withCard(Map<String, dynamic>.from(raw)));
      }
      var filtered = items;
      if (q.status != null && q.status!.isNotEmpty) {
        filtered = [
          for (final c in items)
            if (c.card.status == q.status) c,
        ];
      }
      return PageResult(
        items: filtered,
        page: page.page,
        size: page.size,
        total: q.status == null ? page.total : filtered.length,
      );
    });
  }

  @override
  Future<Client?> findById(String id) => guardRead(() async {
    try {
      final response = await _dio.get<dynamic>(pbRecord('clients', id));
      return await _withCard(asJsonMap(response.data));
    } on DioException catch (e) {
      final mapped = mapDioError(e);
      if (mapped is NotFoundException) return null;
      throw mapped;
    }
  });

  @override
  Future<bool> emailExists(String email, {String? excludeId}) =>
      guardRead(() async {
        final escaped = pbEscape(email.trim());
        final response = await _dio.get<dynamic>(
          pbRecords('clients'),
          queryParameters: {
            'filter': 'email = "$escaped"',
            'perPage': 5,
            'page': 1,
          },
        );
        final page = parsePage(response.data, Client.fromJson);
        return page.items.any((c) => c.id != excludeId);
      });

  Future<void> _upsertCard(String clientId, Client item) async {
    final existing = await _dio.get<dynamic>(
      pbRecords('loyalty_cards'),
      queryParameters: {
        'filter': 'client = "${pbEscape(clientId)}"',
        'perPage': 1,
        'page': 1,
      },
    );
    final items = asJsonMap(existing.data)['items'] as List? ?? [];
    final body = {
      'number': item.card.number,
      'status': item.card.status,
      'issuedAt': item.card.issuedAt.toUtc().toIso8601String(),
      if (item.card.expiresAt != null)
        'expiresAt': item.card.expiresAt!.toUtc().toIso8601String(),
      'client': clientId,
    };
    if (items.isEmpty) {
      await _dio.post<dynamic>(pbRecords('loyalty_cards'), data: body);
    } else {
      final cardId = (items.first as Map)['id'].toString();
      await _dio.patch<dynamic>(pbRecord('loyalty_cards', cardId), data: body);
    }
  }

  @override
  Future<Client> create(Client item) => guard(() async {
    final response = await _dio.post<dynamic>(
      pbRecords('clients'),
      data: {..._clientBody(item), 'isDeleted': false},
    );
    final created = asJsonMap(response.data);
    final id = created['id']?.toString() ?? '';
    if (id.isNotEmpty && item.card.number.isNotEmpty) {
      await _upsertCard(id, item);
    }
    return await _withCard(created);
  });

  @override
  Future<Client> update(Client item) => guard(() async {
    final response = await _dio.patch<dynamic>(
      pbRecord('clients', item.id),
      data: _clientBody(item),
    );
    if (item.card.number.isNotEmpty) {
      await _upsertCard(item.id, item);
    }
    return await _withCard(asJsonMap(response.data));
  });

  @override
  Future<void> softDelete(String id) => guard(
    () =>
        _dio.patch<dynamic>(pbRecord('clients', id), data: {'isDeleted': true}),
  );

  @override
  Future<void> hardDelete(String id) => guard(() async {
    final cards = await _dio.get<dynamic>(
      pbRecords('loyalty_cards'),
      queryParameters: {
        'filter': 'client = "${pbEscape(id)}"',
        'perPage': 10,
        'page': 1,
      },
    );
    for (final item in asJsonMap(cards.data)['items'] as List? ?? []) {
      if (item is Map) {
        await _dio.delete<dynamic>(pbRecord('loyalty_cards', '${item['id']}'));
      }
    }
    await _dio.delete<dynamic>(pbRecord('clients', id));
  });

  @override
  Future<void> restore(String id) => guard(
    () => _dio.patch<dynamic>(
      pbRecord('clients', id),
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
