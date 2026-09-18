import 'package:flutter/foundation.dart';

import '../core/api_exceptions.dart';
import '../models/tour.dart';
import '../repositories/tour_repository.dart';
import 'load_status.dart';

class TourDetailNotifier extends ChangeNotifier {
  final TourRepository _repository;
  final String id;

  TourDetailNotifier(this._repository, this.id);

  Tour? _tour;
  LoadStatus _status = LoadStatus.idle;
  String? _error;

  Tour? get tour => _tour;
  LoadStatus get status => _status;
  String? get error => _error;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _tour = await _repository.findById(id);
      if (_tour == null) {
        _error = 'Тур $id не найден';
        _status = LoadStatus.error;
      } else {
        _status = LoadStatus.success;
      }
    } catch (e) {
      _error = loadErrorMessage(e);
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> softDelete() async {
    await _repository.softDelete(id);
    await load();
  }

  Future<void> hardDelete() async {
    await _repository.hardDelete(id);
    _tour = null;
    _error = 'Тур удалён навсегда';
    _status = LoadStatus.error;
    notifyListeners();
  }

  Future<void> restore() async {
    await _repository.restore(id);
    await load();
  }

  Future<void> book() async {
    _tour = await _repository.book(id);
    notifyListeners();
  }
}
