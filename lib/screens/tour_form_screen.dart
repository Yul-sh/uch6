import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/form_submit.dart';
import '../core/breakpoints.dart';
import '../models/hotel.dart';
import '../models/lookups.dart';
import '../models/tour.dart';
import '../repositories/tour_repository.dart';
import '../state/catalog_lookups.dart';
import '../validation/validators.dart';
import '../widgets/entity_form_scaffold.dart';
import '../widgets/list_status_views.dart';

class TourFormScreen extends StatefulWidget {
  final String? id;

  const TourFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<TourFormScreen> createState() => _TourFormScreenState();
}

class _TourFormScreenState extends State<TourFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _ready = false;
  bool _dirty = false;
  bool _saving = false;
  bool _codeTaken = false;
  Map<String, String> _serverErrors = {};

  late final TextEditingController _title;
  late final TextEditingController _code;
  late final TextEditingController _year;
  late final TextEditingController _days;
  late final TextEditingController _seatsTotal;
  late final TextEditingController _seatsAvailable;
  late final TextEditingController _price;

  String? _destinationId;
  List<String> _hotelIds = [];
  List<String> _categoryIds = [];

  @override
  void initState() {
    super.initState();
    _title = TextEditingController();
    _code = TextEditingController(
      text: widget.isEditing ? '' : Validators.suggestTourCode(),
    );
    _year = TextEditingController(text: '${DateTime.now().year}');
    _days = TextEditingController(text: '7');
    _seatsTotal = TextEditingController(text: '20');
    _seatsAvailable = TextEditingController(text: '20');
    _price = TextEditingController(text: '89000');
    for (final c in [
      _title,
      _code,
      _year,
      _days,
      _seatsTotal,
      _seatsAvailable,
      _price,
    ]) {
      c.addListener(_markDirty);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _load() async {
    final lookups = context.read<CatalogLookups>();
    await lookups.ensureLoaded();
    if (!mounted) return;
    if (widget.id != null) {
      final tour = await context.read<TourRepository>().findById(widget.id!);
      if (tour != null && mounted) {
        _title.text = tour.title;
        _code.text = tour.code;
        _year.text = '${tour.year}';
        _days.text = '${tour.durationDays}';
        _seatsTotal.text = '${tour.seatsTotal}';
        _seatsAvailable.text = '${tour.seatsAvailable}';
        _price.text = '${tour.price}';
        _destinationId = tour.destinationId;
        _hotelIds = [...tour.hotelIds];
        _categoryIds = [...tour.categoryIds];
      }
    }
    if (mounted) {
      setState(() {
        _ready = true;
        _dirty = false;
      });
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _code.dispose();
    _year.dispose();
    _days.dispose();
    _seatsTotal.dispose();
    _seatsAvailable.dispose();
    _price.dispose();
    super.dispose();
  }

  List<Hotel> _hotelsForDestination(CatalogLookups lookups) {
    if (_destinationId == null) return lookups.activeHotels;
    Destination? dest;
    for (final item in lookups.destinations) {
      if (item.id == _destinationId) dest = item;
    }
    if (dest == null) return lookups.activeHotels;
    return lookups.activeHotels
        .where((h) => h.country == dest!.country)
        .toList();
  }

  Future<void> _save() async {
    _serverErrors = {};
    _codeTaken = false;
    if (!mounted) return;
    final seatsOk =
        (int.tryParse(_seatsAvailable.text) ?? 0) <=
        (int.tryParse(_seatsTotal.text) ?? 0);
    if (!_formKey.currentState!.validate() || !seatsOk) {
      if (!seatsOk && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Доступных мест не может быть больше общего числа'),
          ),
        );
      }
      setState(() {});
      return;
    }

    setState(() => _saving = true);
    final tour = Tour(
      id: widget.id ?? '',
      title: _title.text.trim(),
      code: _code.text.trim().toUpperCase(),
      year: int.parse(_year.text.trim()),
      durationDays: int.parse(_days.text.trim()),
      destinationId: _destinationId!,
      hotelIds: _hotelIds,
      categoryIds: _categoryIds,
      seatsTotal: int.parse(_seatsTotal.text.trim()),
      seatsAvailable: int.parse(_seatsAvailable.text.trim()),
      price: int.parse(_price.text.trim()),
    );
    final repo = context.read<TourRepository>();
    final ok = await runApiSave(
      context: context,
      action: () async {
        if (widget.isEditing) {
          await repo.update(tour);
        } else {
          await repo.create(tour);
        }
      },
      onValidation: (errors) {
        _serverErrors = errors;
        _codeTaken = errors['code'] != null;
        _formKey.currentState?.validate();
      },
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) return;
    context.go('/tours');
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const Scaffold(body: LoadingView());
    final lookups = context.watch<CatalogLookups>();
    final hotels = _hotelsForDestination(lookups);

    return EntityFormScaffold(
      title: widget.isEditing ? 'Редактирование тура' : 'Новый тур',
      saveLabel: widget.isEditing ? 'Сохранить' : 'Создать',
      leavePath: '/tours',
      dirty: _dirty,
      loading: _saving,
      formKey: _formKey,
      onSave: _save,
      children: [
        TextFormField(
          controller: _title,
          decoration: const InputDecoration(
            labelText: 'Название',
            border: OutlineInputBorder(),
          ),
          validator: Validators.title,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _code,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
          ],
          decoration: InputDecoration(
            labelText: 'Код тура',
            border: const OutlineInputBorder(),
            helperText:
                'Подставляется сам. Только английские буквы, цифры и дефис.',
            suffixIcon: IconButton(
              tooltip: 'Новый код',
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _code.text = Validators.suggestTourCode();
                _markDirty();
              },
            ),
          ),
          validator: (value) {
            final base = Validators.tourCode(value);
            if (base != null) return base;
            if (_serverErrors['code'] != null) return _serverErrors['code'];
            if (_codeTaken) return 'Код тура уже занят';
            return null;
          },
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: Breakpoints.yearFieldMaxWidth,
            ),
            child: TextFormField(
              controller: _year,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Год',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  Validators.intRange(v, min: 2020, max: 2030, label: 'Год'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _days,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Длительность, дней',
            border: OutlineInputBorder(),
          ),
          validator: (v) => Validators.positiveInt(v, label: 'Длительность'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey(_destinationId),
          initialValue: _destinationId,
          decoration: const InputDecoration(
            labelText: 'Направление',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final item in lookups.activeDestinations)
              DropdownMenuItem(
                value: item.id,
                child: Text('${item.name}, ${item.country}'),
              ),
          ],
          onChanged: (value) {
            setState(() {
              _destinationId = value;
              _dirty = true;
              final allowed = _hotelsForDestination(lookups)
                  .map((h) => h.id)
                  .toSet();
              _hotelIds = _hotelIds.where(allowed.contains).toList();
            });
          },
          validator: (value) => value == null ? 'Выберите направление' : null,
        ),
        const SizedBox(height: 12),
        FormField<List<String>>(
          initialValue: _categoryIds,
          validator: (value) => (value == null || value.isEmpty)
              ? 'Выберите хотя бы один тип'
              : null,
          builder: (field) {
            return InputDecorator(
              decoration: InputDecoration(
                labelText: 'Типы тура',
                border: const OutlineInputBorder(),
                errorText: field.errorText,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in lookups.activeCategories)
                    FilterChip(
                      label: Text(item.name),
                      selected: field.value!.contains(item.id),
                      onSelected: (_) {
                        final next = [...field.value!];
                        next.contains(item.id)
                            ? next.remove(item.id)
                            : next.add(item.id);
                        field.didChange(next);
                        setState(() {
                          _categoryIds = next;
                          _dirty = true;
                        });
                      },
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        FormField<List<String>>(
          initialValue: _hotelIds,
          validator: (value) => (value == null || value.isEmpty)
              ? 'Выберите хотя бы один отель'
              : null,
          builder: (field) {
            return InputDecorator(
              decoration: InputDecoration(
                labelText: 'Отели',
                border: const OutlineInputBorder(),
                helperText: 'Список сужается по стране направления',
                errorText: field.errorText,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final hotel in hotels)
                    FilterChip(
                      label: Text('${hotel.name} ★${hotel.stars}'),
                      selected: field.value!.contains(hotel.id),
                      onSelected: (_) {
                        final next = [...field.value!];
                        next.contains(hotel.id)
                            ? next.remove(hotel.id)
                            : next.add(hotel.id);
                        field.didChange(next);
                        setState(() {
                          _hotelIds = next;
                          _dirty = true;
                        });
                      },
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _seatsTotal,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Всего мест',
            border: OutlineInputBorder(),
          ),
          validator: (v) => Validators.positiveInt(v, label: 'Всего мест'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _seatsAvailable,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Доступно мест',
            border: OutlineInputBorder(),
          ),
          validator: (v) =>
              Validators.nonNegativeInt(v, label: 'Доступно мест'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _price,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Цена, ₽',
            helperText: 'Не больше 300 000',
            border: OutlineInputBorder(),
          ),
          validator: Validators.price,
        ),
      ],
    );
  }
}
