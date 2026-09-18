import 'package:flutter/material.dart';

import '../core/breakpoints.dart';
import 'entity_card_list.dart';
import 'entity_table.dart';

class AdaptiveEntityList<T> extends StatelessWidget {
  final List<TableColumnSpec<T>> columns;
  final List<T> items;
  final String Function(T item) idOf;
  final String Function(T item) titleOf;
  final Set<String> selected;
  final ValueChanged<String>? onToggleSelect;
  final String? sortField;
  final bool sortAscending;
  final void Function(String field)? onSort;
  final List<Widget> Function(T item)? actions;
  final bool Function(T item)? isDeleted;

  const AdaptiveEntityList({
    super.key,
    required this.columns,
    required this.items,
    required this.idOf,
    required this.titleOf,
    this.selected = const {},
    this.onToggleSelect,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
    this.actions,
    this.isDeleted,
  });

  @override
  Widget build(BuildContext context) {
    if (!Breakpoints.useCards(context)) {
      return EntityTable<T>(
        columns: columns,
        items: items,
        idOf: idOf,
        selected: selected,
        onToggleSelect: onToggleSelect,
        sortField: sortField,
        sortAscending: sortAscending,
        onSort: onSort,
        actions: actions,
        isDeleted: isDeleted,
      );
    }
    return EntityCardList<T>(
      columns: columns,
      items: items,
      idOf: idOf,
      titleOf: titleOf,
      selected: selected,
      onToggleSelect: onToggleSelect,
      actions: actions,
      isDeleted: isDeleted,
      twoColumns: Breakpoints.twoColumnCards(context),
    );
  }
}
