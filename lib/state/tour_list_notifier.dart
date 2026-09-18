import 'package:flutter/foundation.dart';

import '../core/api_exceptions.dart';
import '../models/page_result.dart';
import '../models/tour.dart';
import '../models/tour_query.dart';
import '../repositories/tour_repository.dart';
import 'load_status.dart';

class TourListNotifier extends ChangeNotifier {
  final TourRepository _repository;

  TourListNotifier(this._repository);

  TourQuery _query = const TourQuery();
  PageResult<Tour> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<String> _selected = {};

  TourQuery get query => _query;
  PageResult<Tour> get result => _result;
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

  Future<void> applyQuery(TourQuery next) async {
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
