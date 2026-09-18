import '../models/hotel.dart';
import '../models/hotel_query.dart';
import '../models/page_result.dart';

abstract interface class HotelRepository {
  Future<PageResult<Hotel>> find(HotelQuery query);
  Future<List<Hotel>> findAll({bool includeDeleted = false});
  Future<Hotel?> findById(String id);
  Future<Hotel> create(Hotel hotel);
  Future<Hotel> update(Hotel hotel);
  Future<void> softDelete(String id);
  Future<void> hardDelete(String id);
  Future<void> restore(String id);
  Future<int> deleteMany(List<String> ids);
}
