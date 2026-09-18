class TourQuery {
  final String search;
  final String? categoryId;
  final String? destinationId;
  final int? yearFrom;
  final int? yearTo;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const TourQuery({
    this.search = '',
    this.categoryId,
    this.destinationId,
    this.yearFrom,
    this.yearTo,
    this.sortField = 'title',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  TourQuery copyWith({
    String? search,
    Object? categoryId = _unset,
    Object? destinationId = _unset,
    Object? yearFrom = _unset,
    Object? yearTo = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return TourQuery(
      search: search ?? this.search,
      categoryId: categoryId == _unset
          ? this.categoryId
          : categoryId as String?,
      destinationId: destinationId == _unset
          ? this.destinationId
          : destinationId as String?,
      yearFrom: yearFrom == _unset ? this.yearFrom : yearFrom as int?,
      yearTo: yearTo == _unset ? this.yearTo : yearTo as int?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  factory TourQuery.fromUri(Uri uri) {
    final q = uri.queryParameters;
    final sort = q['sort'] ?? 'title,asc';
    final parts = sort.split(',');
    final category = q['categoryId'];
    final destination = q['destinationId'];
    return TourQuery(
      search: q['search'] ?? '',
      categoryId: (category == null || category.isEmpty) ? null : category,
      destinationId: (destination == null || destination.isEmpty)
          ? null
          : destination,
      yearFrom: int.tryParse(q['yearFrom'] ?? ''),
      yearTo: int.tryParse(q['yearTo'] ?? ''),
      sortField: parts.isEmpty || parts.first.isEmpty ? 'title' : parts.first,
      sortAscending: parts.length < 2 || parts[1] != 'desc',
      page: int.tryParse(q['page'] ?? '') ?? 1,
      size: int.tryParse(q['size'] ?? '') ?? 10,
      includeDeleted:
          q['includeDeleted'] == '1' || q['includeDeleted'] == 'true',
    );
  }

  Map<String, String> toQueryParameters() {
    final m = <String, String>{};
    if (search.isNotEmpty) m['search'] = search;
    if (categoryId != null) m['categoryId'] = categoryId!;
    if (destinationId != null) m['destinationId'] = destinationId!;
    if (yearFrom != null) m['yearFrom'] = '$yearFrom';
    if (yearTo != null) m['yearTo'] = '$yearTo';
    if (sortField != 'title' || !sortAscending) {
      m['sort'] = '$sortField,${sortAscending ? 'asc' : 'desc'}';
    }
    if (page != 1) m['page'] = '$page';
    if (size != 10) m['size'] = '$size';
    if (includeDeleted) m['includeDeleted'] = '1';
    return m;
  }

  @override
  bool operator ==(Object other) {
    return other is TourQuery &&
        other.search == search &&
        other.categoryId == categoryId &&
        other.destinationId == destinationId &&
        other.yearFrom == yearFrom &&
        other.yearTo == yearTo &&
        other.sortField == sortField &&
        other.sortAscending == sortAscending &&
        other.page == page &&
        other.size == size &&
        other.includeDeleted == includeDeleted;
  }

  @override
  int get hashCode => Object.hash(
    search,
    categoryId,
    destinationId,
    yearFrom,
    yearTo,
    sortField,
    sortAscending,
    page,
    size,
    includeDeleted,
  );

  static const _unset = Object();
}
