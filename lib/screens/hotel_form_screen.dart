import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/form_submit.dart';
import '../models/hotel.dart';
import '../repositories/hotel_repository.dart';
import '../state/catalog_lookups.dart';
import '../validation/validators.dart';
import '../widgets/entity_form_scaffold.dart';
import '../widgets/list_status_views.dart';

class HotelFormScreen extends StatefulWidget {
  final String? id;
  const HotelFormScreen({super.key, this.id});
  bool get isEditing => id != null;

  @override
  State<HotelFormScreen> createState() => _HotelFormScreenState();
}

class _HotelFormScreenState extends State<HotelFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _ready = false;
  bool _dirty = false;
  bool _saving = false;
  final _name = TextEditingController();
  final _country = TextEditingController();
  final _city = TextEditingController();
  final _stars = TextEditingController(text: '4');

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _country, _city, _stars]) {
      c.addListener(() {
        if (!_dirty) setState(() => _dirty = true);
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (widget.id != null) {
      final hotel = await context.read<HotelRepository>().findById(widget.id!);
      if (hotel != null && mounted) {
        _name.text = hotel.name;
        _country.text = hotel.country;
        _city.text = hotel.city;
        _stars.text = '${hotel.stars}';
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
    _name.dispose();
    _country.dispose();
    _city.dispose();
    _stars.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final hotel = Hotel(
      id: widget.id ?? '',
      name: _name.text.trim(),
      country: _country.text.trim(),
      city: _city.text.trim(),
      stars: int.parse(_stars.text.trim()),
    );
    final repo = context.read<HotelRepository>();
    final ok = await runApiSave(
      context: context,
      action: () async {
        widget.isEditing ? await repo.update(hotel) : await repo.create(hotel);
      },
      onValidation: (_) {},
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) return;
    await context.read<CatalogLookups>().reload();
    if (!mounted) return;
    context.go('/hotels');
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const Scaffold(body: LoadingView());
    return EntityFormScaffold(
      title: widget.isEditing ? 'Редактирование отеля' : 'Новый отель',
      saveLabel: widget.isEditing ? 'Сохранить' : 'Создать',
      leavePath: '/hotels',
      dirty: _dirty,
      loading: _saving,
      formKey: _formKey,
      onSave: _save,
      children: [
        TextFormField(
          controller: _name,
          decoration: const InputDecoration(
            labelText: 'Название',
            border: OutlineInputBorder(),
          ),
          validator: Validators.title,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _country,
          decoration: const InputDecoration(
            labelText: 'Страна',
            border: OutlineInputBorder(),
          ),
          validator: (v) => Validators.personName(v, label: 'Страна'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _city,
          decoration: const InputDecoration(
            labelText: 'Город',
            border: OutlineInputBorder(),
          ),
          validator: (v) => Validators.personName(v, label: 'Город'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _stars,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Звёзды',
            border: OutlineInputBorder(),
          ),
          validator: (v) =>
              Validators.intRange(v, min: 1, max: 5, label: 'Звёзды'),
        ),
      ],
    );
  }
}
