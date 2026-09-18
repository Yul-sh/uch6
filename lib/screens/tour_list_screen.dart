import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/breakpoints.dart';
import '../models/role.dart';
import '../models/tour.dart';
import '../models/tour_query.dart';
import '../routing/query_navigation.dart';
import '../routing/reload_when_visible.dart';
import '../state/auth_notifier.dart';
import '../state/catalog_lookups.dart';
import '../state/load_status.dart';
import '../state/tour_list_notifier.dart';
import '../widgets/adaptive_entity_list.dart';
import '../widgets/api_error_dialog.dart';
import '../widgets/can.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/entity_table.dart';
import '../widgets/list_status_views.dart';
import '../widgets/pagination_bar.dart';

class TourListScreen extends StatefulWidget {
  final TourQuery query;

  const TourListScreen({super.key, required this.query});

  @override
  State<TourListScreen> createState() => _TourListScreenState();
}

class _TourListScreenState extends State<TourListScreen>
    with ReloadWhenVisible {
  bool _filtersOpen = false;

  @override
  String get visiblePath => '/tours';

  @override
  void onBecameVisible() {
    context.read<CatalogLookups>().ensureLoaded();
    context.read<TourListNotifier>().applyQuery(widget.query);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) onBecameVisible();
    });
  }

  @override
  void didUpdateWidget(TourListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      context.read<TourListNotifier>().applyQuery(widget.query);
    }
  }

  void _go(TourQuery next) {
    goWithQuery(context, '/tours', next.toQueryParameters());
  }

  Future<void> _confirmSoftDelete(Tour tour) async {
    final ok = await confirmAction(
      context,
      title: 'Скрыть тур',
      message: '«${tour.title}» будет скрыт из каталога (логическое удаление).',
      confirmLabel: 'Скрыть',
    );
    if (!ok || !mounted) return;
    await context.read<TourListNotifier>().softDelete(tour.id);
  }

  Future<void> _confirmHardDelete(Tour tour) async {
    final ok = await confirmAction(
      context,
      title: 'Удалить навсегда',
      message: '«${tour.title}» будет стёрт из памяти. Отменить нельзя.',
      confirmLabel: 'Удалить навсегда',
    );
    if (!ok || !mounted) return;
    try {
      await context.read<TourListNotifier>().hardDelete(tour.id);
    } on ApiException catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  Future<void> _confirmDeleteSelected(TourListNotifier notifier) async {
    final count = notifier.selected.length;
    final ok = await confirmAction(
      context,
      title: 'Скрыть выбранные',
      message: 'Скрыть $count тур(а) из каталога?',
      confirmLabel: 'Скрыть',
    );
    if (!ok || !mounted) return;
    await notifier.deleteSelected();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<TourListNotifier>();
    final lookups = context.watch<CatalogLookups>();
    final auth = context.watch<AuthNotifier>();
    final q = widget.query;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Каталог туров'),
        actions: [
          if (auth.can(AppOp.softDelete) && notifier.hasSelection)
            IconButton(
              tooltip: 'Скрыть (${notifier.selected.length})',
              onPressed: () => _confirmDeleteSelected(notifier),
              icon: const Icon(Icons.delete_outline),
            ),
          PopupMenuButton<String>(
            tooltip: 'Проверка сети',
            onSelected: (value) {
              if (value == 'fail') _go(q.copyWith(search: '__fail__'));
              if (value == 'delay') _go(q.copyWith(search: '__delay__'));
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'fail',
                child: Text('Ошибка сервера (__fail=500)'),
              ),
              PopupMenuItem(
                value: 'delay',
                child: Text('Задержка 1.5 с (__delay)'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: auth.can(AppOp.manageCatalog)
          ? FloatingActionButton(
              onPressed: () => context.go('/tours/new'),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: DebouncedSearchField(
              value: q.search == '__fail__' || q.search == '__delay__'
                  ? ''
                  : q.search,
              hint: 'Поиск по названию или коду тура',
              onSubmit: (text) => _go(q.copyWith(search: text)),
            ),
          ),
          if (auth.can(AppOp.softDelete) || auth.can(AppOp.restore))
            SwitchListTile(
              title: const Text('Показывать скрытые туры'),
              value: q.includeDeleted,
              onChanged: (value) => _go(q.copyWith(includeDeleted: value)),
            ),
          ExpansionTile(
            title: const Text('Фильтры'),
            subtitle: Text(_filterSummary(q, lookups)),
            initiallyExpanded: _filtersOpen,
            onExpansionChanged: (open) => setState(() => _filtersOpen = open),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _dropdown<String?>(
                      label: 'Тип тура',
                      value: q.categoryId,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Все')),
                        for (final item in lookups.activeCategories)
                          DropdownMenuItem(
                            value: item.id,
                            child: Text(item.name),
                          ),
                      ],
                      onChanged: (value) => _go(q.copyWith(categoryId: value)),
                    ),
                    _dropdown<String?>(
                      label: 'Направление',
                      value: q.destinationId,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Все')),
                        for (final item in lookups.activeDestinations)
                          DropdownMenuItem(
                            value: item.id,
                            child: Text('${item.name}, ${item.country}'),
                          ),
                      ],
                      onChanged: (value) =>
                          _go(q.copyWith(destinationId: value)),
                    ),
                    _dropdown<int?>(
                      label: 'Год от',
                      value: q.yearFrom,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Любой'),
                        ),
                        for (final year in const [2023, 2024, 2025, 2026, 2027])
                          DropdownMenuItem(value: year, child: Text('$year')),
                      ],
                      onChanged: (value) => _go(q.copyWith(yearFrom: value)),
                    ),
                    _dropdown<int?>(
                      label: 'Год до',
                      value: q.yearTo,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Любой'),
                        ),
                        for (final year in const [2023, 2024, 2025, 2026, 2027])
                          DropdownMenuItem(value: year, child: Text('$year')),
                      ],
                      onChanged: (value) => _go(q.copyWith(yearTo: value)),
                    ),
                    TextButton(
                      onPressed: () => _go(TourQuery(size: q.size)),
                      child: const Text('Сбросить'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Expanded(child: _body(notifier, q, lookups, auth)),
          if (notifier.status == LoadStatus.success)
            PaginationBar(
              page: notifier.result.page,
              totalPages: notifier.result.totalPages,
              total: notifier.result.total,
              size: notifier.result.size,
              hasPrevious: notifier.result.hasPrevious,
              hasNext: notifier.result.hasNext,
              onPage: (page) => _go(q.copyWith(page: page)),
              onSize: (size) => _go(q.copyWith(size: size)),
            ),
        ],
      ),
    );
  }

  Widget _body(
    TourListNotifier notifier,
    TourQuery q,
    CatalogLookups lookups,
    AuthNotifier auth,
  ) {
    return switch (notifier.status) {
      LoadStatus.idle || LoadStatus.loading => const LoadingView(),
      LoadStatus.error => ErrorResultView(
        message: notifier.error ?? 'Неизвестная ошибка',
        onRetry: notifier.load,
      ),
      LoadStatus.success when notifier.result.items.isEmpty =>
        const EmptyResultView(),
      LoadStatus.success => AdaptiveEntityList<Tour>(
        items: notifier.result.items,
        idOf: (t) => t.id,
        titleOf: (t) => t.title,
        selected: notifier.selected,
        onToggleSelect: auth.can(AppOp.softDelete)
            ? notifier.toggleSelection
            : null,
        sortField: q.sortField,
        sortAscending: q.sortAscending,
        isDeleted: (t) => t.isDeleted,
        onSort: (field) => _go(
          q.copyWith(
            sortField: field,
            sortAscending: field == q.sortField ? !q.sortAscending : true,
          ),
        ),
        columns: [
          TableColumnSpec(
            label: 'Название',
            sortField: 'title',
            build: (t) =>
                Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          TableColumnSpec(
            label: 'Код',
            sortField: 'code',
            build: (t) =>
                Text(t.code, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          TableColumnSpec(
            label: 'Год',
            sortField: 'year',
            numeric: true,
            build: (t) => Text('${t.year}'),
          ),
          TableColumnSpec(
            label: 'Дней',
            sortField: 'durationDays',
            numeric: true,
            build: (t) => Text('${t.durationDays}'),
          ),
          TableColumnSpec(
            label: 'Цена',
            sortField: 'price',
            numeric: true,
            build: (t) => Text('${t.price} ₽'),
          ),
          TableColumnSpec(
            label: 'Направление',
            build: (t) => Text(
              lookups.destinationName(
                t.destinationId,
                fallback: t.destinationLabel,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        actions: (t) => [
          AuthRowActions(
            isDeleted: t.isDeleted,
            onView: () => context.go('/tours/${t.id}'),
            onEdit: () => context.go('/tours/${t.id}/edit'),
            onHideOrRestore: () =>
                t.isDeleted ? notifier.restore(t.id) : _confirmSoftDelete(t),
            onDelete: () => _confirmHardDelete(t),
          ),
        ],
      ),
    };
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    double width = 220,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = MediaQuery.sizeOf(context).width;
        final fieldW = maxW < Breakpoints.medium
            ? (maxW - 48).clamp(140.0, width)
            : width;
        return SizedBox(
          width: fieldW,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                isExpanded: true,
                value: value,
                items: items,
                onChanged: onChanged,
              ),
            ),
          ),
        );
      },
    );
  }

  String _filterSummary(TourQuery q, CatalogLookups lookups) {
    final parts = <String>[];
    if (q.categoryId != null) {
      parts.add(lookups.categoryNames([q.categoryId!]));
    }
    if (q.destinationId != null) {
      parts.add(lookups.destinationName(q.destinationId!));
    }
    if (q.yearFrom != null) parts.add('с ${q.yearFrom}');
    if (q.yearTo != null) parts.add('по ${q.yearTo}');
    return parts.isEmpty ? 'Не заданы' : parts.join(' · ');
  }
}
