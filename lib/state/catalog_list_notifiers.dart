import 'package:flutter/foundation.dart';

import '../core/api_exceptions.dart';
import '../models/catalog_query.dart';
import '../models/client.dart';
import '../models/lookups.dart';
import '../models/page_result.dart';
import '../repositories/client_repository.dart';
import '../repositories/lookup_repositories.dart';
import 'load_status.dart';

class DestinationListNotifier extends ChangeNotifier {
  DestinationListNotifier(this._repository);

  final DestinationRepository _repository;
  CatalogQuery _query = const CatalogQuery();
  PageResult<Destination> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<String> _selected = {};

  CatalogQuery get query => _query;
  PageResult get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<String> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _result = await _repository.find(_query);
      _status = LoadStatus.success;
    } on RequestCancelledException {
      return;
    } catch (e) {
      _error = loadErrorMessage(e);
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> applyQuery(CatalogQuery next) async {
    if (next != _query) _selected.clear();
    _query = next;
    await load();
  }

  void toggleSelection(String id) {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    await _repository.deleteMany(_selected.toList());
    _selected.clear();
    await load();
  }

  Future<void> softDelete(String id) async {
    await _repository.softDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> hardDelete(String id) async {
    await _repository.hardDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> restore(String id) async {
    await _repository.restore(id);
    await load();
  }
}

class CategoryListNotifier extends ChangeNotifier {
  CategoryListNotifier(this._repository);

  final CategoryRepository _repository;
  CatalogQuery _query = const CatalogQuery();
  PageResult<TourCategory> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<String> _selected = {};

  CatalogQuery get query => _query;
  PageResult get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<String> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _result = await _repository.find(_query);
      _status = LoadStatus.success;
    } on RequestCancelledException {
      return;
    } catch (e) {
      _error = loadErrorMessage(e);
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> applyQuery(CatalogQuery next) async {
    if (next != _query) _selected.clear();
    _query = next;
    await load();
  }

  void toggleSelection(String id) {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    await _repository.deleteMany(_selected.toList());
    _selected.clear();
    await load();
  }

  Future<void> softDelete(String id) async {
    await _repository.softDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> hardDelete(String id) async {
    await _repository.hardDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> restore(String id) async {
    await _repository.restore(id);
    await load();
  }
}

class ClientListNotifier extends ChangeNotifier {
  ClientListNotifier(this._repository);

  final ClientRepository _repository;
  CatalogQuery _query = const CatalogQuery(sortField: 'lastName');
  PageResult<Client> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<String> _selected = {};

  CatalogQuery get query => _query;
  PageResult get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<String> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _result = await _repository.find(_query);
      _status = LoadStatus.success;
    } on RequestCancelledException {
      return;
    } catch (e) {
      _error = loadErrorMessage(e);
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> applyQuery(CatalogQuery next) async {
    if (next != _query) _selected.clear();
    _query = next;
    await load();
  }

  void toggleSelection(String id) {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    await _repository.deleteMany(_selected.toList());
    _selected.clear();
    await load();
  }

  Future<void> softDelete(String id) async {
    await _repository.softDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> hardDelete(String id) async {
    await _repository.hardDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> restore(String id) async {
    await _repository.restore(id);
    await load();
  }
}
