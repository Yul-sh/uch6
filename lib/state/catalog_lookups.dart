import 'package:flutter/foundation.dart';

import '../models/hotel.dart';
import '../models/lookups.dart';
import '../repositories/hotel_repository.dart';
import '../repositories/lookup_repositories.dart';

class CatalogLookups extends ChangeNotifier {
  CatalogLookups({
    required this._destinations,
    required this._hotels,
    required this._categories,
  });

  final DestinationRepository _destinations;
  final HotelRepository _hotels;
  final CategoryRepository _categories;

  List<Destination> destinations = [];
  List<Hotel> hotels = [];
  List<TourCategory> categories = [];

  List<Destination> get activeDestinations =>
      destinations.where((d) => !d.isDeleted).toList();
  List<Hotel> get activeHotels => hotels.where((h) => !h.isDeleted).toList();
  List<TourCategory> get activeCategories =>
      categories.where((c) => !c.isDeleted).toList();

  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded && destinations.isNotEmpty) return;
    await reload();
  }

  Future<void> reload() async {
    try {
      destinations = await _destinations.findAll(includeDeleted: true);
    } catch (_) {
      destinations = [];
    }
    try {
      hotels = await _hotels.findAll(includeDeleted: true);
    } catch (_) {
      hotels = [];
    }
    try {
      categories = await _categories.findAll(includeDeleted: true);
    } catch (_) {
      categories = [];
    }
    _loaded = true;
    notifyListeners();
  }

  String destinationName(String id, {String? fallback}) {
    for (final item in destinations) {
      if (item.id == id) return item.name;
    }
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return '—';
  }

  String categoryNames(List<String> ids, {String? fallback}) {
    final names = <String>[];
    for (final id in ids) {
      for (final item in categories) {
        if (item.id == id) names.add(item.name);
      }
    }
    if (names.isNotEmpty) return names.join(', ');
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return '—';
  }

  String hotelNames(List<String> ids, {String? fallback}) {
    final names = <String>[];
    for (final id in ids) {
      for (final item in hotels) {
        if (item.id == id) names.add(item.name);
      }
    }
    if (names.isNotEmpty) return names.join(', ');
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return '—';
  }
}
