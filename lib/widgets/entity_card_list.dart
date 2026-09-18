import 'package:flutter/material.dart';

import 'entity_table.dart';

class EntityCardList<T> extends StatelessWidget {
  final List<TableColumnSpec<T>> columns;
  final List<T> items;
  final String Function(T item) idOf;
  final Set<String> selected;
  final ValueChanged<String>? onToggleSelect;
  final List<Widget> Function(T item)? actions;
  final bool Function(T item)? isDeleted;
  final String Function(T item) titleOf;
  final bool twoColumns;

  const EntityCardList({
    super.key,
    required this.columns,
    required this.items,
    required this.idOf,
    required this.titleOf,
    this.selected = const {},
    this.onToggleSelect,
    this.actions,
    this.isDeleted,
    this.twoColumns = false,
  });

  Widget _card(BuildContext context, T item) {
    final deleted = isDeleted != null && isDeleted!(item);
    final theme = Theme.of(context);
    return Card(
      color: deleted
          ? theme.colorScheme.errorContainer.withValues(alpha: 0.4)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (onToggleSelect != null)
                  Checkbox(
                    value: selected.contains(idOf(item)),
                    onChanged: (_) => onToggleSelect!(idOf(item)),
                  ),
                Expanded(
                  child: Text(
                    titleOf(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final column in columns)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        column.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    Expanded(
                      child: DefaultTextStyle(
                        style: theme.textTheme.bodyMedium!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        child: column.build(item),
                      ),
                    ),
                  ],
                ),
              ),
            if (actions != null)
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 0,
                  runSpacing: 0,
                  children: actions!(item),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!twoColumns) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _card(context, items[index]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: (items.length + 1) ~/ 2,
      itemBuilder: (context, rowIndex) {
        final left = items[rowIndex * 2];
        final rightIndex = rowIndex * 2 + 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _card(context, left)),
              const SizedBox(width: 8),
              Expanded(
                child: rightIndex < items.length
                    ? _card(context, items[rightIndex])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }
}
