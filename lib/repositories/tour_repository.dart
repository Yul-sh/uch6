import '../models/page_result.dart';
import '../models/tour.dart';
import '../models/tour_query.dart';

abstract interface class TourRepository {
  Future<PageResult<Tour>> find(TourQuery query);
  Future<Tour?> findById(String id);
  Future<bool> codeExists(String code, {String? excludeId});
  Future<int> countByDestination(String destinationId);
  Future<int> countByCategory(String categoryId);
  Future<int> countByHotel(String hotelId);
  Future<Tour> create(Tour tour);
  Future<Tour> update(Tour tour);
  Future<Tour> book(String id);
  Future<void> softDelete(String id);
  Future<void> hardDelete(String id);
  Future<void> restore(String id);
  Future<int> deleteMany(List<String> ids);
}
