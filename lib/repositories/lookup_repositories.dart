import '../models/catalog_query.dart';
import '../models/lookups.dart';
import '../models/page_result.dart';

abstract interface class DestinationRepository {
  Future<PageResult<Destination>> find(CatalogQuery query);
  Future<List<Destination>> findAll({bool includeDeleted = false});
  Future<Destination?> findById(String id);
  Future<Destination> create(Destination item);
  Future<Destination> update(Destination item);
  Future<void> softDelete(String id);
  Future<void> hardDelete(String id);
  Future<void> restore(String id);
  Future<int> deleteMany(List<String> ids);
}

abstract interface class CategoryRepository {
  Future<PageResult<TourCategory>> find(CatalogQuery query);
  Future<List<TourCategory>> findAll({bool includeDeleted = false});
  Future<TourCategory?> findById(String id);
  Future<TourCategory> create(TourCategory item);
  Future<TourCategory> update(TourCategory item);
  Future<void> softDelete(String id);
  Future<void> hardDelete(String id);
  Future<void> restore(String id);
  Future<int> deleteMany(List<String> ids);
}
