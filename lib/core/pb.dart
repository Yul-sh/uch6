/// PocketBase helpers for Dio paths under `/api`.
library;

String pbRecords(String collection) => '/collections/$collection/records';

String pbRecord(String collection, String id) =>
    '/collections/$collection/records/$id';

String pbEscape(String value) =>
    value.replaceAll('\\', '\\\\').replaceAll('"', '\\"');

/// Builds PocketBase list query: `filter`, `sort`, `page`, `perPage`, `expand`.
Map<String, dynamic> pbListQuery({
  required String search,
  required String sortField,
  required bool sortAscending,
  required int page,
  required int size,
  required bool includeDeleted,
  List<String> searchFields = const ['name'],
  List<String> extraFilters = const [],
  String? expand,
  bool hasSoftDelete = true,
}) {
  final filters = <String>[];
  if (hasSoftDelete && !includeDeleted) {
    filters.add('(isDeleted = false || isDeleted = null)');
  }
  final q = search.trim();
  if (q == '__fail__') {
    filters.add('id = "__fail__"');
  } else if (q.isNotEmpty && q != '__delay__') {
    final escaped = pbEscape(q);
    filters.add('(${searchFields.map((f) => '$f ~ "$escaped"').join(' || ')})');
  }
  filters.addAll(extraFilters);

  return {
    'page': page,
    'perPage': size,
    'sort': '${sortAscending ? '' : '-'}$sortField',
    if (filters.isNotEmpty) 'filter': filters.join(' && '),
    if (expand != null && expand.isNotEmpty) 'expand': expand,
    if (q == '__delay__') '_delay': 1500,
  };
}

/// Honours demo `_delay` from [pbListQuery] (search `__delay__`).
Future<void> maybeDelay(Map<String, dynamic> params) async {
  final delay = params.remove('_delay');
  if (delay is int && delay > 0) {
    await Future<void>.delayed(Duration(milliseconds: delay));
  }
}
