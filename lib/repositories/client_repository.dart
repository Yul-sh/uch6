import '../models/catalog_query.dart';
import '../models/client.dart';
import '../models/page_result.dart';

abstract interface class ClientRepository {
  Future<PageResult<Client>> find(CatalogQuery query);
  Future<Client?> findById(String id);
  Future<bool> emailExists(String email, {String? excludeId});
  Future<Client> create(Client item);
  Future<Client> update(Client item);
  Future<void> softDelete(String id);
  Future<void> hardDelete(String id);
  Future<void> restore(String id);
  Future<int> deleteMany(List<String> ids);
}
