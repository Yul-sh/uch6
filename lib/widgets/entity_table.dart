import 'package:flutter/material.dart';

class TableColumnSpec<T> {
  final String label;
  final String? sortField;
  final bool numeric;
  final Widget Function(T item) build;

  const TableColumnSpec({
    required this.label,
    required this.build,
    this.sortField,
    this.numeric = false,
  });
}

class EntityTable<T> extends StatelessWidget {
  final List<TableColumnSpec<T>> columns;
  final List<T> items;
  final String Function(T item) idOf;
  final Set<String> selected;
  final ValueChanged<String>? onToggleSelect;
  final String? sortField;
  final bool sortAscending;
  final void Function(String field)? onSort;
  final List<Widget> Function(T item)? actions;
  final bool Function(T item)? isDeleted;

  const EntityTable({
    super.key,
    required this.columns,
    required this.items,
    required this.idOf,
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
    final sortColumnIndex = columns.indexWhere((c) => c.sortField == sortField);
    final dataColumnOffset = onToggleSelect == null ? 0 : 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: SingleChildScrollView(
              primary: false,
              child: DataTable(
                sortColumnIndex: sortColumnIndex >= 0
                    ? sortColumnIndex + dataColumnOffset
                    : null,
                sortAscending: sortAscending,
                columns: [
                  if (onToggleSelect != null) const DataColumn(label: Text('')),
                  for (final column in columns)
                    DataColumn(
                      label: Text(column.label),
                      numeric: column.numeric,
                      onSort: column.sortField == null || onSort == null
                          ? null
                          : (_, _) => onSort!(column.sortField!),
                    ),
                  if (actions != null) const DataColumn(label: Text('')),
                ],
                rows: [
                  for (final item in items)
                    DataRow(
                      selected: selected.contains(idOf(item)),
                      color: isDeleted != null && isDeleted!(item)
                          ? WidgetStatePropertyAll(
                              Theme.of(context).colorScheme.errorContainer
                                  .withValues(alpha: 0.35),
                            )
                          : null,
                      cells: [
                        if (onToggleSelect != null)
                          DataCell(
                            Checkbox(
                              value: selected.contains(idOf(item)),
                              onChanged: (_) => onToggleSelect!(idOf(item)),
                            ),
                          ),
                        for (final column in columns)
                          DataCell(column.build(item)),
                        if (actions != null)
                          DataCell(Wrap(children: actions!(item))),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
