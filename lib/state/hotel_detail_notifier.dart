import 'package:flutter/foundation.dart';

import '../models/hotel.dart';
import '../repositories/hotel_repository.dart';
import 'load_status.dart';

class HotelDetailNotifier extends ChangeNotifier {
  final HotelRepository _repository;
  final String id;

  HotelDetailNotifier(this._repository, this.id);

  Hotel? _hotel;
  LoadStatus _status = LoadStatus.idle;
  String? _error;

  Hotel? get hotel => _hotel;
  LoadStatus get status => _status;
  String? get error => _error;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _hotel = await _repository.findById(id);
      if (_hotel == null) {
        _error = 'Отель $id не найден';
        _status = LoadStatus.error;
      } else {
        _status = LoadStatus.success;
      }
    } catch (e) {
      _error = 'Не удалось загрузить отель: $e';
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
    _hotel = null;
    _error = 'Отель удалён навсегда';
    _status = LoadStatus.error;
    notifyListeners();
  }

  Future<void> restore() async {
    await _repository.restore(id);
    await load();
  }
}
