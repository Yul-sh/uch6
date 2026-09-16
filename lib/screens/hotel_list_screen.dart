import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../models/role.dart';
import '../models/hotel.dart';
import '../models/hotel_query.dart';
import '../routing/query_navigation.dart';
import '../routing/reload_when_visible.dart';
import '../state/auth_notifier.dart';
import '../state/catalog_lookups.dart';
import '../state/hotel_list_notifier.dart';
import '../state/load_status.dart';
import '../widgets/adaptive_entity_list.dart';
import '../widgets/api_error_dialog.dart';
import '../widgets/can.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/entity_table.dart';
import '../widgets/list_status_views.dart';
import '../widgets/pagination_bar.dart';

class HotelListScreen extends StatefulWidget {
  final HotelQuery query;

  const HotelListScreen({super.key, required this.query});

  @override
  State<HotelListScreen> createState() => _HotelListScreenState();
}

class _HotelListScreenState extends State<HotelListScreen>
    with ReloadWhenVisible {
  bool _filtersOpen = false;

  @override
  String get visiblePath => '/hotels';

  @override
  void onBecameVisible() {
    context.read<CatalogLookups>().ensureLoaded();
    context.read<HotelListNotifier>().applyQuery(widget.query);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) onBecameVisible();
    });
  }

  @override
  void didUpdateWidget(HotelListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      context.read<HotelListNotifier>().applyQuery(widget.query);
    }
  }

  void _go(HotelQuery next) {
    goWithQuery(context, '/hotels', next.toQueryParameters());
  }

  Future<void> _confirmSoftDelete(Hotel hotel) async {
    final ok = await confirmAction(
      context,
      title: 'Скрыть отель',
      message: '«${hotel.name}» будет скрыт из каталога.',
      confirmLabel: 'Скрыть',
    );
    if (!ok || !mounted) return;
    await context.read<HotelListNotifier>().softDelete(hotel.id);
  }

  Future<void> _confirmHardDelete(Hotel hotel) async {
    final ok = await confirmAction(
      context,
      title: 'Удалить навсегда',
      message: '«${hotel.name}» будет стёрт из памяти.',
      confirmLabel: 'Удалить навсегда',
    );
    if (!ok || !mounted) return;
    try {
      await context.read<HotelListNotifier>().hardDelete(hotel.id);
    } on ApiException catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  Future<void> _confirmDeleteSelected(HotelListNotifier notifier) async {
    final count = notifier.selected.length;
    final ok = await confirmAction(
      context,
      title: 'Скрыть выбранные',
      message: 'Скрыть $count отел(я/ей) из каталога?',
      confirmLabel: 'Скрыть',
    );
    if (!ok || !mounted) return;
    await notifier.deleteSelected();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<HotelListNotifier>();
    final lookups = context.watch<CatalogLookups>();
    final auth = context.watch<AuthNotifier>();
    final countries = {
      for (final hotel in lookups.activeHotels) hotel.country,
    }.toList()..sort();
    final q = widget.query;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Каталог отелей'),
        actions: [
          if (auth.can(AppOp.softDelete) && notifier.hasSelection)
            IconButton(
              tooltip: 'Скрыть (${notifier.selected.length})',
              onPressed: () => _confirmDeleteSelected(notifier),
              icon: const Icon(Icons.delete_outline),
            ),
          PopupMenuButton<String>(
            tooltip: 'Демо ошибки загрузки',
            onSelected: (value) {
              if (value == 'fail') {
                _go(q.copyWith(search: '__fail__'));
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'fail',
                child: Text('Показать ошибку загрузки'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: auth.can(AppOp.manageCatalog)
          ? FloatingActionButton(
              onPressed: () => context.go('/hotels/new'),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: DebouncedSearchField(
              value: q.search == '__fail__' ? '' : q.search,
              hint: 'Поиск по названию или стране',
              onSubmit: (text) => _go(q.copyWith(search: text)),
            ),
          ),
          if (auth.can(AppOp.softDelete) || auth.can(AppOp.restore))
            SwitchListTile(
              title: const Text('Показывать скрытые отели'),
              value: q.includeDeleted,
              onChanged: (value) => _go(q.copyWith(includeDeleted: value)),
            ),
          ExpansionTile(
            title: const Text('Фильтры'),
            initiallyExpanded: _filtersOpen,
            onExpansionChanged: (open) => setState(() => _filtersOpen = open),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Builder(
                  builder: (context) {
                    final maxW = MediaQuery.sizeOf(context).width;
                    final countryW = maxW < 768
                        ? (maxW - 48).clamp(140.0, 220.0)
                        : 220.0;
                    final starsW = maxW < 768
                        ? (maxW - 48).clamp(120.0, 160.0)
                        : 160.0;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: countryW,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Страна',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String?>(
                                isExpanded: true,
                                value: q.country,
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('Все'),
                                  ),
                                  for (final country in countries)
                                    DropdownMenuItem(
                                      value: country,
                                      child: Text(country),
                                    ),
                                ],
                                onChanged: (value) =>
                                    _go(q.copyWith(country: value)),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: starsW,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Звёзды',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int?>(
                                isExpanded: true,
                                value: q.stars,
                                items: const [
                                  DropdownMenuItem(
                                    value: null,
                                    child: Text('Все'),
                                  ),
                                  DropdownMenuItem(value: 3, child: Text('3')),
                                  DropdownMenuItem(value: 4, child: Text('4')),
                                  DropdownMenuItem(value: 5, child: Text('5')),
                                ],
                                onChanged: (value) =>
                                    _go(q.copyWith(stars: value)),
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _go(HotelQuery(size: q.size)),
                          child: const Text('Сбросить'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          Expanded(child: _body(notifier, q, auth)),
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

  Widget _body(HotelListNotifier notifier, HotelQuery q, AuthNotifier auth) {
    return switch (notifier.status) {
      LoadStatus.idle || LoadStatus.loading => const LoadingView(),
      LoadStatus.error => ErrorResultView(
        message: notifier.error ?? 'Неизвестная ошибка',
        onRetry: notifier.load,
      ),
      LoadStatus.success when notifier.result.items.isEmpty =>
        const EmptyResultView(),
      LoadStatus.success => AdaptiveEntityList<Hotel>(
        items: notifier.result.items,
        idOf: (h) => h.id,
        titleOf: (h) => h.name,
        selected: notifier.selected,
        onToggleSelect: auth.can(AppOp.softDelete)
            ? notifier.toggleSelection
            : null,
        sortField: q.sortField,
        sortAscending: q.sortAscending,
        isDeleted: (h) => h.isDeleted,
        onSort: (field) => _go(
          q.copyWith(
            sortField: field,
            sortAscending: field == q.sortField ? !q.sortAscending : true,
          ),
        ),
        columns: [
          TableColumnSpec(
            label: 'Название',
            sortField: 'name',
            build: (h) =>
                Text(h.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          TableColumnSpec(
            label: 'Страна',
            sortField: 'country',
            build: (h) =>
                Text(h.country, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          TableColumnSpec(
            label: 'Город',
            sortField: 'city',
            build: (h) =>
                Text(h.city, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          TableColumnSpec(
            label: 'Звёзды',
            sortField: 'stars',
            numeric: true,
            build: (h) => Text('${h.stars}'),
          ),
        ],
        actions: (h) => [
          AuthRowActions(
            isDeleted: h.isDeleted,
            onView: () => context.go('/hotels/${h.id}'),
            onEdit: () => context.go('/hotels/${h.id}/edit'),
            onHideOrRestore: () =>
                h.isDeleted ? notifier.restore(h.id) : _confirmSoftDelete(h),
            onDelete: () => _confirmHardDelete(h),
          ),
        ],
      ),
    };
  }
}
