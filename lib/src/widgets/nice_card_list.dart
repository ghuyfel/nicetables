import 'package:flutter/material.dart';

import '../model/nice_column.dart';
import '../model/nice_density.dart';
import '../theme/nice_table_theme.dart';
import 'nice_default_cell.dart';
import 'nice_table_row.dart';

/// Builds a whole card for [row] in the compact layout.
typedef NiceCardBuilder<T> = Widget Function(BuildContext context, T row);

/// The narrow-screen rendering: one card per row with the primary column
/// as the title, the next text column as a subtitle, status chips and
/// actions in the header, and the remaining columns as a key/value list.
class NiceCardList<T> extends StatelessWidget {
  /// Creates a card list.
  const NiceCardList({
    required this.rows,
    required this.columns,
    required this.theme,
    required this.selectionMode,
    required this.isSelected,
    required this.onToggleSelected,
    required this.onTap,
    required this.shrinkWrap,
    this.cardBuilder,
    this.scrollController,
    this.dimmed = false,
    super.key,
  });

  /// Rows on this page.
  final List<T> rows;

  /// Visible columns.
  final List<NiceColumn<T>> columns;

  /// Resolved theme.
  final NiceTableTheme theme;

  /// Selection mode.
  final NiceSelectionMode selectionMode;

  /// Whether a row is selected.
  final bool Function(T row) isSelected;

  /// Toggles a row's selection.
  final void Function(T row) onToggleSelected;

  /// Row tap.
  final void Function(T row)? onTap;

  /// Size to content instead of filling.
  final bool shrinkWrap;

  /// Replaces the default card.
  final NiceCardBuilder<T>? cardBuilder;

  /// Vertical scroll controller.
  final ScrollController? scrollController;

  /// Fade while refreshing.
  final bool dimmed;

  @override
  Widget build(BuildContext context) => ListView.separated(
        controller: scrollController,
        shrinkWrap: shrinkWrap,
        physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
        padding: EdgeInsets.symmetric(
          horizontal: theme.horizontalPadding,
          vertical: 12,
        ),
        itemCount: rows.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final row = rows[i];
          final selected = isSelected(row);
          return AnimatedOpacity(
            duration: theme.hoverDuration,
            opacity: dimmed ? 0.55 : 1,
            child: cardBuilder?.call(context, row) ??
                _DefaultCard<T>(
                  row: row,
                  index: i,
                  columns: columns,
                  theme: theme,
                  selected: selected,
                  selectionMode: selectionMode,
                  onToggleSelected: () => onToggleSelected(row),
                  onTap: onTap == null ? null : () => onTap!(row),
                ),
          );
        },
      );
}

class _DefaultCard<T> extends StatelessWidget {
  const _DefaultCard({
    required this.row,
    required this.index,
    required this.columns,
    required this.theme,
    required this.selected,
    required this.selectionMode,
    required this.onToggleSelected,
    required this.onTap,
  });

  final T row;
  final int index;
  final List<NiceColumn<T>> columns;
  final NiceTableTheme theme;
  final bool selected;
  final NiceSelectionMode selectionMode;
  final VoidCallback onToggleSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cellContext = NiceCellContext(
      rowIndex: index,
      selected: selected,
      hovered: false,
      focused: false,
      expanded: false,
    );
    final shown = columns.where((c) => c.showInCard).toList();
    final primary = shown.where((c) => c.primary).firstOrNull ??
        shown.where((c) => c.cell == null && c.value != null).firstOrNull ??
        shown.firstOrNull;
    final actions = columns.where((c) => !c.showInCard && c.cell != null);
    final rest = shown.where((c) => c != primary).toList();

    Widget content(NiceColumn<T> c) => buildNiceCellContent<T>(
        context, c, row, cellContext, theme, NiceDensity.comfortable);

    return Material(
      color: selected ? theme.selected : theme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap ??
            (selectionMode == NiceSelectionMode.none ? null : onToggleSelected),
        onLongPress:
            selectionMode == NiceSelectionMode.multi ? onToggleSelected : null,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? theme.accent : theme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (selectionMode == NiceSelectionMode.multi)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: selected,
                          activeColor: theme.accent,
                          checkColor: theme.onAccent,
                          side: BorderSide(
                            color: theme.mutedForeground,
                            width: 1.5,
                          ),
                          visualDensity: VisualDensity.compact,
                          onChanged: (_) => onToggleSelected(),
                        ),
                      ),
                    ),
                  if (primary != null)
                    Expanded(
                      child: DefaultTextStyle.merge(
                        style: theme.cellTextStyle.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.foreground,
                          fontSize: 15,
                        ),
                        child: content(primary),
                      ),
                    ),
                  for (final a in actions) content(a),
                ],
              ),
              if (rest.isNotEmpty) ...[
                const SizedBox(height: 10),
                for (final c in rest)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 112,
                          child: Text(
                            c.label,
                            style: theme.headerTextStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: DefaultTextStyle.merge(
                              style: theme.cellTextStyle,
                              child: content(
                                // Card values read left to right.
                                c.align != NiceAlign.start
                                    ? NiceColumn<T>(
                                        id: c.id,
                                        label: c.label,
                                        value: c.value,
                                        text: c.text,
                                        subtitle: c.subtitle,
                                        cell: c.cell,
                                        numeric: c.numeric,
                                        mono: c.mono,
                                        style: c.style,
                                        align: NiceAlign.start,
                                      )
                                    : c,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
