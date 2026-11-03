import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../controller/nice_table_controller.dart';
import '../model/nice_column.dart';
import '../model/nice_density.dart';
import '../model/nice_filter.dart';
import '../theme/nice_table_theme.dart';
import 'nice_horizontal_scroll.dart';
import 'nice_layout.dart';

/// The sticky header row: labels, sort indicators, filter menus, the
/// select-all checkbox and resize handles.
class NiceTableHeader<T> extends StatelessWidget {
  /// Creates a header.
  const NiceTableHeader({
    required this.columns,
    required this.layout,
    required this.controller,
    required this.theme,
    required this.density,
    required this.offset,
    required this.showCheckbox,
    required this.showExpander,
    required this.selectAllState,
    required this.onSelectAll,
    required this.resizable,
    required this.filterOptionsFor,
    super.key,
  });

  /// Visible columns.
  final List<NiceColumn<T>> columns;

  /// Resolved widths.
  final NiceColumnLayout layout;

  /// The table controller.
  final NiceTableController<T> controller;

  /// Resolved theme.
  final NiceTableTheme theme;

  /// Row density.
  final NiceDensity density;

  /// Horizontal scroll offset.
  final ViewportOffset offset;

  /// Whether the multi-select checkbox is shown.
  final bool showCheckbox;

  /// Whether the expander gutter is reserved.
  final bool showExpander;

  /// `true` all page rows selected, `false` none, `null` some.
  final bool? selectAllState;

  /// Toggles page selection.
  final ValueChanged<bool> onSelectAll;

  /// Whether columns show resize handles.
  final bool resizable;

  /// Options for a column's filter menu (explicit or derived).
  final List<NiceFilterOption> Function(NiceColumn<T>) filterOptionsFor;

  @override
  Widget build(BuildContext context) {
    final pinned = layout.pinnedCount;
    final cells = <Widget>[
      for (var i = 0; i < columns.length; i++)
        _HeaderCell<T>(
          column: columns[i],
          width: layout.widths[i],
          controller: controller,
          theme: theme,
          resizable: resizable && columns[i].width.max != columns[i].width.min,
          filterOptions:
              columns[i].filterable ? filterOptionsFor(columns[i]) : null,
          showColumnDivider: theme.showColumnDividers && i < columns.length - 1,
        ),
    ];

    final gutter = SizedBox(
      width: layout.leadingWidth,
      child: Row(
        children: [
          if (showCheckbox)
            SizedBox(
              width: 48,
              child: Center(
                child: Checkbox(
                  value: selectAllState,
                  tristate: true,
                  activeColor: theme.accent,
                  checkColor: theme.onAccent,
                  side: BorderSide(color: theme.mutedForeground, width: 1.5),
                  visualDensity: VisualDensity.compact,
                  semanticLabel: 'Select all rows on this page',
                  onChanged: (_) => onSelectAll(selectAllState != true),
                ),
              ),
            ),
          if (showExpander) const SizedBox(width: 40),
        ],
      ),
    );

    return Container(
      height: density.headerHeight,
      decoration: BoxDecoration(
        color: theme.headerBackground,
        border: Border(bottom: BorderSide(color: theme.border)),
      ),
      child: Row(
        children: [
          SizedBox(width: theme.horizontalPadding),
          gutter,
          ...cells.take(pinned),
          if (pinned > 0)
            _PinnedEdge(offset: offset, theme: theme),
          Expanded(
            child: NiceHorizontalShift(
              offset: offset,
              contentWidth: layout.scrollingWidth,
              child: Row(children: cells.skip(pinned).toList()),
            ),
          ),
          SizedBox(width: theme.horizontalPadding),
        ],
      ),
    );
  }
}

/// Hairline plus a soft shadow on the trailing edge of the pinned block,
/// visible only once the table has scrolled horizontally.
class _PinnedEdge extends StatelessWidget {
  const _PinnedEdge({required this.offset, required this.theme});

  final ViewportOffset offset;
  final NiceTableTheme theme;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: offset,
        builder: (context, _) {
          final scrolled = offset.pixels > 0.5;
          return Container(
            width: 1,
            decoration: BoxDecoration(
              color: scrolled ? theme.border : theme.divider,
              boxShadow: scrolled
                  ? [
                      BoxShadow(
                        color: theme.foreground.withValues(alpha: 0.10),
                        blurRadius: 8,
                        offset: const Offset(3, 0),
                      ),
                    ]
                  : null,
            ),
          );
        },
      );
}

/// Exposed so rows can draw the same pinned edge.
Widget nicePinnedEdge(ViewportOffset offset, NiceTableTheme theme) =>
    _PinnedEdge(offset: offset, theme: theme);

class _HeaderCell<T> extends StatefulWidget {
  const _HeaderCell({
    required this.column,
    required this.width,
    required this.controller,
    required this.theme,
    required this.resizable,
    required this.filterOptions,
    required this.showColumnDivider,
  });

  final NiceColumn<T> column;
  final double width;
  final NiceTableController<T> controller;
  final NiceTableTheme theme;
  final bool resizable;
  final List<NiceFilterOption>? filterOptions;
  final bool showColumnDivider;

  @override
  State<_HeaderCell<T>> createState() => _HeaderCellState<T>();
}

class _HeaderCellState<T> extends State<_HeaderCell<T>> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final column = widget.column;
    final theme = widget.theme;
    final sort = widget.controller.sort;
    final sorted = sort?.columnId == column.id;
    final filter = widget.controller.filters[column.id];
    final labelStyle = sorted
        ? theme.headerTextStyle.copyWith(color: theme.foreground)
        : theme.headerTextStyle;

    final label = column.headerBuilder?.call(context) ??
        Text(
          column.label.toUpperCase(),
          style: labelStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          textAlign: column.align.textAlign,
        );

    final sortIcon = column.sortable
        ? AnimatedOpacity(
            duration: theme.hoverDuration,
            opacity: sorted ? 1 : (_hover ? 0.5 : 0),
            child: AnimatedRotation(
              duration: const Duration(milliseconds: 160),
              turns: sorted && !sort!.ascending ? 0.5 : 0,
              child: Icon(
                Icons.arrow_upward_rounded,
                size: 14,
                color: sorted ? theme.accent : theme.headerForeground,
              ),
            ),
          )
        : null;

    final filterButton = widget.filterOptions == null
        ? null
        : _FilterMenu<T>(
            column: column,
            options: widget.filterOptions!,
            controller: widget.controller,
            theme: theme,
            active: filter != null,
            visible: _hover || filter != null,
          );

    final end = column.align == NiceAlign.end;
    final children = <Widget>[
      if (end && sortIcon != null) ...[sortIcon, const SizedBox(width: 4)],
      Flexible(child: label),
      if (!end && sortIcon != null) ...[const SizedBox(width: 4), sortIcon],
      if (filterButton != null) ...[const SizedBox(width: 2), filterButton],
    ];

    Widget cell = Padding(
      padding: EdgeInsets.symmetric(horizontal: theme.cellPadding),
      child: Row(
        mainAxisAlignment: switch (column.align) {
          NiceAlign.start => MainAxisAlignment.start,
          NiceAlign.center => MainAxisAlignment.center,
          NiceAlign.end => MainAxisAlignment.end,
        },
        children: children,
      ),
    );

    if (column.sortable) {
      cell = Semantics(
        button: true,
        label: sorted
            ? '${column.label}, sorted ${sort!.ascending ? 'ascending' : 'descending'}'
            : '${column.label}, sort',
        child: InkWell(
          onTap: () => widget.controller.toggleSort(column.id),
          hoverColor: theme.hover,
          child: cell,
        ),
      );
    }

    if (column.tooltip != null) {
      cell = Tooltip(message: column.tooltip!, child: cell);
    }

    return SizedBox(
      width: widget.width,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: [
            cell,
            if (widget.showColumnDivider)
              Positioned(
                right: 0,
                top: 10,
                bottom: 10,
                child: Container(width: 1, color: theme.divider),
              ),
            if (widget.resizable)
              Positioned(
                right: -5,
                top: 0,
                bottom: 0,
                width: 10,
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onDoubleTap: () =>
                        widget.controller.clearColumnWidth(column.id),
                    // The handle moves with the column edge, so the
                    // per-event delta accumulates into the new width.
                    onHorizontalDragUpdate: (d) =>
                        widget.controller.setColumnWidth(
                      column.id,
                      (widget.width + (d.primaryDelta ?? 0))
                          .clamp(48.0, 1200.0),
                    ),
                    child: Center(
                      child: AnimatedContainer(
                        duration: theme.hoverDuration,
                        width: 2,
                        height: _hover ? 18 : 0,
                        decoration: BoxDecoration(
                          color: theme.border,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterMenu<T> extends StatelessWidget {
  const _FilterMenu({
    required this.column,
    required this.options,
    required this.controller,
    required this.theme,
    required this.active,
    required this.visible,
  });

  final NiceColumn<T> column;
  final List<NiceFilterOption> options;
  final NiceTableController<T> controller;
  final NiceTableTheme theme;
  final bool active;
  final bool visible;

  Set<Object?> _selectedValues() {
    final current = controller.filters[column.id]?.value;
    if (current is Set<Object?>) return current;
    return const {};
  }

  void _toggle(Object? value) {
    final next = {..._selectedValues()};
    if (!next.remove(value)) next.add(value);
    if (next.isEmpty) {
      controller.removeFilter(column.id);
      return;
    }
    final labels = options
        .where((o) => next.contains(o.value))
        .map((o) => o.label)
        .join(', ');
    controller.setFilter(
      column.id,
      NiceFilter<T>.oneOf(
        values: next,
        valueOf: (row) => column.value?.call(row),
        label: '${column.label}: $labels',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedValues();
    return MenuAnchor(
      style: MenuStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: theme.border),
          ),
        ),
      ),
      menuChildren: [
        for (final o in options)
          MenuItemButton(
            closeOnActivate: false,
            onPressed: () => _toggle(o.value),
            leadingIcon: Icon(
              selected.contains(o.value)
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 18,
              color: selected.contains(o.value)
                  ? theme.accent
                  : theme.mutedForeground,
            ),
            child: Text(o.label, style: theme.cellTextStyle),
          ),
        if (selected.isNotEmpty) ...[
          const Divider(height: 8),
          MenuItemButton(
            onPressed: () => controller.removeFilter(column.id),
            leadingIcon: Icon(
              Icons.clear_rounded,
              size: 18,
              color: theme.mutedForeground,
            ),
            child: Text(
              'Clear filter',
              style: theme.cellTextStyle.copyWith(color: theme.mutedForeground),
            ),
          ),
        ],
      ],
      builder: (context, menu, _) => AnimatedOpacity(
        duration: theme.hoverDuration,
        opacity: visible || menu.isOpen ? 1 : 0,
        child: Tooltip(
          message: 'Filter ${column.label}',
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => menu.isOpen ? menu.close() : menu.open(),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Icon(
                active ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
                size: 15,
                color: active ? theme.accent : theme.headerForeground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
