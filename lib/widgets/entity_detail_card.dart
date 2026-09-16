import 'package:flutter/material.dart';

import '../core/breakpoints.dart';

class EntityDetailCard extends StatelessWidget {
  final List<(String, String)> rows;
  final List<Widget>? actions;

  const EntityDetailCard({super.key, required this.rows, this.actions});

  static const _cardMaxWidth = 720.0;

  TextStyle _textStyle(ThemeData theme, {Color? color, double size = 15}) {
    return (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
      fontFamily: theme.textTheme.bodyMedium?.fontFamily,
      fontWeight: FontWeight.w400,
      fontSize: size,
      height: 1.35,
      color: color ?? theme.colorScheme.onSurface,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleRow = rows.where((r) => r.$1 == 'Название').firstOrNull;
    final fields = rows.where((r) => r.$1 != 'Название').toList();
    final muted = theme.colorScheme.onSurfaceVariant;

    return MaxWidthBody(
      maxWidth: _cardMaxWidth,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                children: [
                  if (titleRow != null) ...[
                    Text(
                      titleRow.$2,
                      textAlign: TextAlign.center,
                      style: _textStyle(theme, size: 20),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      titleRow.$1,
                      textAlign: TextAlign.center,
                      style: _textStyle(theme, color: muted),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: theme.colorScheme.outlineVariant),
                    const SizedBox(height: 8),
                  ],
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final twoCols = constraints.maxWidth >= 520;
                      if (!twoCols) {
                        return Column(
                          children: [
                            for (var i = 0; i < fields.length; i++) ...[
                              if (i > 0) const SizedBox(height: 10),
                              _FieldTile(
                                label: fields[i].$1,
                                value: fields[i].$2,
                                textStyle: _textStyle(theme),
                                mutedStyle: _textStyle(theme, color: muted),
                              ),
                            ],
                          ],
                        );
                      }

                      final left = <(String, String)>[];
                      final right = <(String, String)>[];
                      for (var i = 0; i < fields.length; i++) {
                        (i.isEven ? left : right).add(fields[i]);
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _FieldColumn(
                              rows: left,
                              textStyle: _textStyle(theme),
                              mutedStyle: _textStyle(theme, color: muted),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _FieldColumn(
                              rows: right,
                              textStyle: _textStyle(theme),
                              mutedStyle: _textStyle(theme, color: muted),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: actions!,
            ),
          ],
        ],
      ),
    );
  }
}

class _FieldColumn extends StatelessWidget {
  final List<(String, String)> rows;
  final TextStyle textStyle;
  final TextStyle mutedStyle;

  const _FieldColumn({
    required this.rows,
    required this.textStyle,
    required this.mutedStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _FieldTile(
            label: rows[i].$1,
            value: rows[i].$2,
            textStyle: textStyle,
            mutedStyle: mutedStyle,
          ),
        ],
      ],
    );
  }
}

class _FieldTile extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle textStyle;
  final TextStyle mutedStyle;

  const _FieldTile({
    required this.label,
    required this.value,
    required this.textStyle,
    required this.mutedStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, textAlign: TextAlign.center, style: mutedStyle),
          const SizedBox(height: 2),
          Text(value, textAlign: TextAlign.center, style: textStyle),
        ],
      ),
    );
  }
}
