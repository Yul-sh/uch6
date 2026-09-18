import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/form_submit.dart';
import '../models/lookups.dart';
import '../repositories/lookup_repositories.dart';
import '../state/catalog_lookups.dart';
import '../validation/validators.dart';
import '../widgets/entity_form_scaffold.dart';
import '../widgets/list_status_views.dart';

class DestinationFormScreen extends StatefulWidget {
  final String? id;
  const DestinationFormScreen({super.key, this.id});
  bool get isEditing => id != null;

  @override
  State<DestinationFormScreen> createState() => _DestinationFormScreenState();
}

class _DestinationFormScreenState extends State<DestinationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _ready = false;
  bool _dirty = false;
  bool _saving = false;
  final _name = TextEditingController();
  final _country = TextEditingController();

  @override
  void initState() {
    super.initState();
    _name.addListener(() {
      if (!_dirty) setState(() => _dirty = true);
    });
    _country.addListener(() {
      if (!_dirty) setState(() => _dirty = true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (widget.id != null) {
      final item = await context.read<DestinationRepository>().findById(
        widget.id!,
      );
      if (item != null && mounted) {
        _name.text = item.name;
        _country.text = item.country;
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
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final item = Destination(
      id: widget.id ?? '',
      name: _name.text.trim(),
      country: _country.text.trim(),
    );
    final repo = context.read<DestinationRepository>();
    final ok = await runApiSave(
      context: context,
      action: () async {
        widget.isEditing ? await repo.update(item) : await repo.create(item);
      },
      onValidation: (_) {},
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) return;
    await context.read<CatalogLookups>().reload();
    if (!mounted) return;
    context.go('/destinations');
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const Scaffold(body: LoadingView());
    return EntityFormScaffold(
      title: widget.isEditing
          ? 'Редактирование направления'
          : 'Новое направление',
      saveLabel: widget.isEditing ? 'Сохранить' : 'Создать',
      leavePath: '/destinations',
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
      ],
    );
  }
}

class CategoryFormScreen extends StatefulWidget {
  final String? id;
  const CategoryFormScreen({super.key, this.id});
  bool get isEditing => id != null;

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _ready = false;
  bool _dirty = false;
  bool _saving = false;
  final _name = TextEditingController();

  @override
  void initState() {
    super.initState();
    _name.addListener(() {
      if (!_dirty) setState(() => _dirty = true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (widget.id != null) {
      final item = await context.read<CategoryRepository>().findById(
        widget.id!,
      );
      if (item != null && mounted) _name.text = item.name;
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
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final item = TourCategory(id: widget.id ?? '', name: _name.text.trim());
    final repo = context.read<CategoryRepository>();
    final ok = await runApiSave(
      context: context,
      action: () async {
        widget.isEditing ? await repo.update(item) : await repo.create(item);
      },
      onValidation: (_) {},
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) return;
    await context.read<CatalogLookups>().reload();
    if (!mounted) return;
    context.go('/categories');
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const Scaffold(body: LoadingView());
    return EntityFormScaffold(
      title: widget.isEditing ? 'Редактирование типа' : 'Новый тип тура',
      saveLabel: widget.isEditing ? 'Сохранить' : 'Создать',
      leavePath: '/categories',
      dirty: _dirty,
      loading: _saving,
      formKey: _formKey,
      onSave: _save,
      children: [
        TextFormField(
          controller: _name,
          decoration: const InputDecoration(
            labelText: 'Название типа',
            border: OutlineInputBorder(),
          ),
          validator: Validators.title,
        ),
      ],
    );
  }
}
