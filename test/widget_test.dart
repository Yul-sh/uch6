import 'package:flutter_test/flutter_test.dart';
import 'package:fly_y/models/page_result.dart';
import 'package:fly_y/models/tour_query.dart';

void main() {
  test('PageResult считает число страниц', () {
    const page = PageResult<int>(items: [1], page: 1, size: 10, total: 24);
    expect(page.totalPages, 3);
    expect(page.hasPrevious, isFalse);
    expect(page.hasNext, isTrue);
  });

  test('TourQuery сохраняется в адресе и читается обратно', () {
    const query = TourQuery(
      search: 'дубай',
      categoryId: 'cat00000000002',
      page: 3,
      sortField: 'year',
      sortAscending: false,
    );
    final parsed = TourQuery.fromUri(
      Uri(path: '/tours', queryParameters: query.toQueryParameters()),
    );
    expect(parsed, query);
  });
}
