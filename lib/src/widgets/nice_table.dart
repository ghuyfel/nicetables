import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../controller/nice_table_controller.dart';
import '../export/nice_csv.dart';
import '../model/nice_column.dart';
import '../model/nice_density.dart';
import '../model/nice_filter.dart';
import '../model/nice_query.dart';
import '../theme/nice_table_theme.dart';
import 'nice_card_list.dart';
import 'nice_horizontal_scroll.dart';
import 'nice_layout.dart';
import 'nice_table_footer.dart';
import 'nice_table_header.dart';
import 'nice_table_row.dart';
import 'nice_table_states.dart';
import 'nice_table_toolbar.dart';

/// Where sorting, searching, filtering and paging happen.
enum NiceProcessing {
  /// The table does it, from the full [NiceTable.rows] list.
  client,

  /// Your source does it. [NiceTable.rows] is the current page and
  /// [NiceTable.totalRows] the matching count; [NiceTable.onQueryChanged]
  /// fires whenever the user changes the query.
  server,
}

/// Builds the detail panel under an expanded row.
typedef NiceExpandedBuilder<T> = Widget Function(BuildContext context, T row);

/// A beautiful, feature-complete data table.
///
/// ```dart
/// NiceTable<Order>(
///   title: 'Orders',
///   rows: orders,
///   columns: [
///     NiceColumn.text('id', 'Order', (o) => o.id, mono: true),
///     NiceColumn.text('customer', 'Customer', (o) => o.customer),
///     NiceColumn.status('status', 'Status', (o) => o.statusValue),
///     NiceColumn.money('total', 'Total', (o) => o.total),
///     NiceColumn.date('placed', 'Placed', (o) => o.placedAt),
///   ],
///   selectionMode: NiceSelectionMode.multi,
///   onRowTap: (o) => openOrder(o),
/// )
/// ```
///
/// Give it a bounded height (an `Expanded`, a `SizedBox`) and the rows
/// scroll inside a sticky header; give it none (inside a scroll view) and
/// it sizes to its rows.
class NiceTable<T> extends StatefulWidget {
  /// Creates a table.
  const NiceTable({
    required this.rows,
    required this.columns,
    this.controller,
    this.rowKey,
    this.processing = NiceProcessing.client,
    this.totalRows,
    this.onQueryChanged,
    this.loading = false,
    this.error,
    this.onRetry,
    this.title,
    this.subtitle,
    this.titleWidget,
    this.showToolbar = true,
    this.showSearch = true,
    this.searchHint = 'Search',
    this.actions = const [],
    this.showColumnPicker = true,
    this.showDensityToggle = false,
    this.showExport = false,
    this.onExport,
    this.onRefresh,
    this.bulkActions,
    this.selectionMode = NiceSelectionMode.none,
    this.selectOnTap,
    this.onSelectionChanged,
    this.onRowTap,
    this.onRowDoubleTap,
    this.onRowSecondaryTap,
    this.expandedBuilder,
    this.rowStyle,
    this.pinnedColumns = 0,
    this.resizableColumns = true,
    this.paged = true,
    this.pageSizeOptions = const [10, 25, 50, 100],
    this.showFooter = true,
    this.density,
    this.theme,
    this.compactBreakpoint = 600,
    this.cardBuilder,
    this.emptyState,
    this.emptyTitle = 'Nothing here yet',
    this.emptyMessage,
    this.rowLabel = 'rows',
    this.semanticLabel,
    super.key,
  }) : assert(pinnedColumns >= 0, 'pinnedColumns must not be negative');

  /// The rows: every row in client mode, the current page in server mode.
  final List<T> rows;

  /// Column definitions. Order is display order.
  final List<NiceColumn<T>> columns;

  /// State owner; one is created when omitted.
  final NiceTableController<T>? controller;

  /// Stable identity for a row, used by selection and expansion. Defaults
  /// to the row object itself (so value-equal rows share identity).
  final Object Function(T row)? rowKey;

  /// Client or server processing.
  final NiceProcessing processing;

  /// Matching row count in server mode.
  final int? totalRows;

  /// Fires with the new query whenever sort, search, filters or page
  /// change. In server mode, fetch here.
  final ValueChanged<NiceQuery<T>>? onQueryChanged;

  /// Shows skeleton rows (no rows yet) or a progress bar (refreshing).
  final bool loading;

  /// Shows the error state when non-null and there are no rows.
  final Object? error;

  /// Retry button in the error state.
  final VoidCallback? onRetry;

  /// Toolbar title.
  final String? title;

  /// Toolbar subtitle; defaults to the row count.
  final String? subtitle;

  /// Replaces the toolbar title block.
  final Widget? titleWidget;

  /// Whether the toolbar is shown at all.
  final bool showToolbar;

  /// Whether the search field is shown.
  final bool showSearch;

  /// Search placeholder.
  final String searchHint;

  /// Trailing toolbar widgets.
  final List<Widget> actions;

  /// Column visibility menu.
  final bool showColumnPicker;

  /// Density menu.
  final bool showDensityToggle;

  /// Export button; with no [onExport] it copies CSV to the clipboard.
  final bool showExport;

  /// Receives the CSV of the matching rows (client) or the page (server).
  final ValueChanged<String>? onExport;

  /// Refresh button.
  final VoidCallback? onRefresh;

  /// Buttons for the bulk bar shown while rows are selected.
  final NiceBulkActionsBuilder<T>? bulkActions;

  /// Selection behaviour.
  final NiceSelectionMode selectionMode;

  /// Whether a plain row tap changes selection. Defaults to true in single
  /// mode, and in multi mode to true only when [onRowTap] is null.
  final bool? selectOnTap;

  /// Fires with the selected rows (those present in [rows]).
  final ValueChanged<List<T>>? onSelectionChanged;

  /// Row tap.
  final void Function(T row)? onRowTap;

  /// Row double tap.
  final void Function(T row)? onRowDoubleTap;

  /// Right click or long press, with the global position for a menu.
  final void Function(T row, Offset globalPosition)? onRowSecondaryTap;

  /// Enables an expander gutter and builds the detail panel.
  final NiceExpandedBuilder<T>? expandedBuilder;

  /// Per-row colour overrides.
  final NiceRowStyle? Function(T row)? rowStyle;

  /// Number of leading columns that stay put when scrolling horizontally.
  final int pinnedColumns;

  /// Drag handles on header edges.
  final bool resizableColumns;

  /// Page the rows; when false, every matching row is shown.
  final bool paged;

  /// Rows-per-page choices.
  final List<int> pageSizeOptions;

  /// Whether the footer is shown.
  final bool showFooter;

  /// Density override.
  final NiceDensity? density;

  /// Theme override.
  final NiceTableTheme? theme;

  /// Below this width the card layout is used. Zero disables it.
  final double compactBreakpoint;

  /// Custom card for the compact layout.
  final NiceCardBuilder<T>? cardBuilder;

  /// Replaces the default empty state.
  final Widget? emptyState;

  /// Empty-state title when there are no rows at all.
  final String emptyTitle;

  /// Empty-state message when there are no rows at all.
  final String? emptyMessage;

  /// Noun for counts ("rows", "orders").
  final String rowLabel;

  /// Accessibility label for the table.
  final String? semanticLabel;

  @override
  State<NiceTable<T>> createState() => _NiceTableState<T>();
}

class _NiceTableState<T> extends State<NiceTable<T>> {
  NiceTableController<T>? _ownController;
  NiceTableController<T> get _controller =>
      widget.controller ?? (_ownController ??= NiceTableController<T>());

  final _hController = ScrollController();
  final _vController = ScrollController();
  final _focusNode = FocusNode(debugLabel: 'NiceTable');
  int? _anchorIndex;
  NiceQuery<T>? _lastQuery;
  List<T> _pageRows = const [];
  List<T> _matchingRows = const [];

  Object _keyOf(T row) => widget.rowKey?.call(row) ?? row as Object;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _lastQuery = _controller.query;
  }

  @override
  void didUpdateWidget(covariant NiceTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownController)?.removeListener(
        _onControllerChanged,
      );
      if (widget.controller != null) {
        _ownController?.dispose();
        _ownController = null;
      }
      _controller.addListener(_onControllerChanged);
      _lastQuery = _controller.query;
    }
  }

  void _onControllerChanged() {
    final q = _controller.query;
    if (q != _lastQuery) {
      _lastQuery = q;
      widget.onQueryChanged?.call(q);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _ownController?.dispose();
    _hController.dispose();
    _vController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------
  // Selection
  // -------------------------------------------------------------------

  bool get _selectOnTap =>
      widget.selectOnTap ??
      switch (widget.selectionMode) {
        NiceSelectionMode.none => false,
        NiceSelectionMode.single => true,
        NiceSelectionMode.multi => widget.onRowTap == null,
      };

  void _notifySelection() {
    final cb = widget.onSelectionChanged;
    if (cb == null) return;
    final source =
        widget.processing == NiceProcessing.client ? widget.rows : _pageRows;
    cb([
      for (final r in source)
        if (_controller.isSelected(_keyOf(r))) r
    ]);
  }

  void _toggleRow(int index, {bool fromCheckbox = false}) {
    final c = _controller;
    final key = _keyOf(_pageRows[index]);
    final keyboard = HardwareKeyboard.instance;
    final shift = keyboard.isShiftPressed;
    final ctrl = keyboard.isControlPressed || keyboard.isMetaPressed;

    switch (widget.selectionMode) {
      case NiceSelectionMode.none:
        return;
      case NiceSelectionMode.single:
        if (c.isSelected(key) && (fromCheckbox || ctrl)) {
          c.clearSelection();
        } else {
          c.selectOnly(key);
        }
      case NiceSelectionMode.multi:
        if (shift && _anchorIndex != null) {
          final lo = math.min(_anchorIndex!, index);
          final hi = math.max(_anchorIndex!, index);
          c.selectAll([
            for (var i = lo; i <= hi; i++) _keyOf(_pageRows[i]),
          ]);
        } else {
          c.toggleSelected(key);
          _anchorIndex = index;
        }
    }
    _notifySelection();
  }

  void _selectAllOnPage(bool select) {
    final keys = _pageRows.map(_keyOf);
    if (select) {
      _controller.selectAll(keys);
    } else {
      _controller.deselectAll(keys);
    }
    _notifySelection();
  }

  bool? _selectAllState() {
    if (_pageRows.isEmpty) return false;
    var count = 0;
    for (final r in _pageRows) {
      if (_controller.isSelected(_keyOf(r))) count++;
    }
    if (count == 0) return false;
    if (count == _pageRows.length) return true;
    return null;
  }

  void _onRowTap(int index) {
    _focusNode.requestFocus();
    _controller.setFocusedIndex(index);
    final row = _pageRows[index];
    final keyboard = HardwareKeyboard.instance;
    final modifier = keyboard.isShiftPressed ||
        keyboard.isControlPressed ||
        keyboard.isMetaPressed;
    if (widget.selectionMode != NiceSelectionMode.none &&
        (_selectOnTap || modifier)) {
      _toggleRow(index);
      if (modifier) return;
    }
    widget.onRowTap?.call(row);
  }

  // -------------------------------------------------------------------
  // Keyboard
  // -------------------------------------------------------------------

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final c = _controller;
    final count = _pageRows.length;
    final focused = c.focusedIndex;
    final key = event.logicalKey;

    void focus(int i) {
      if (count == 0) return;
      final clamped = i.clamp(0, count - 1);
      c.setFocusedIndex(clamped);
      _revealRow(clamped);
    }

    if (key == LogicalKeyboardKey.arrowDown) {
      focus((focused ?? -1) + 1);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      focus((focused ?? count) - 1);
    } else if (key == LogicalKeyboardKey.home) {
      focus(0);
    } else if (key == LogicalKeyboardKey.end) {
      focus(count - 1);
    } else if (key == LogicalKeyboardKey.pageDown) {
      c.nextPage();
    } else if (key == LogicalKeyboardKey.pageUp) {
      c.previousPage();
    } else if (key == LogicalKeyboardKey.space && focused != null) {
      _toggleRow(focused, fromCheckbox: true);
    } else if ((key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter) &&
        focused != null &&
        focused < count) {
      widget.onRowTap?.call(_pageRows[focused]);
    } else if (key == LogicalKeyboardKey.arrowRight &&
        widget.expandedBuilder != null &&
        focused != null &&
        focused < count) {
      c.setExpanded(_keyOf(_pageRows[focused]), true);
    } else if (key == LogicalKeyboardKey.arrowLeft &&
        widget.expandedBuilder != null &&
        focused != null &&
        focused < count) {
      c.setExpanded(_keyOf(_pageRows[focused]), false);
    } else if (key == LogicalKeyboardKey.escape) {
      c
        ..clearSelection()
        ..setFocusedIndex(null);
      _notifySelection();
    } else if (key == LogicalKeyboardKey.keyA &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed) &&
        widget.selectionMode == NiceSelectionMode.multi) {
      _selectAllOnPage(true);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  void _revealRow(int index) {
    if (!_vController.hasClients) return;
    final position = _vController.position;
    final rowHeight = _density().rowHeight;
    final top = index * rowHeight;
    final bottom = top + rowHeight;
    if (top < position.pixels) {
      _vController.jumpTo(top);
    } else if (bottom > position.pixels + position.viewportDimension) {
      _vController.jumpTo(bottom - position.viewportDimension);
    }
  }

  // -------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------

  NiceDensity _density() =>
      _controller.density ?? widget.density ?? _theme().density;

  NiceTableTheme _theme() => widget.theme ?? NiceTableTheme.of(context);

  List<NiceFilterOption> _filterOptionsFor(NiceColumn<T> column) {
    final explicit = column.filterOptions;
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final source =
        widget.processing == NiceProcessing.client ? widget.rows : _pageRows;
    final seen = <Object?, NiceFilterOption>{};
    for (final row in source) {
      final v = column.value?.call(row);
      if (v == null) continue;
      seen.putIfAbsent(v, () => NiceFilterOption(v, label: v.toString()));
    }
    final options = seen.values.toList()
      ..sort((a, b) => a.label.compareTo(b.label));
    return options;
  }

  void _export() {
    final rows =
        widget.processing == NiceProcessing.client ? _matchingRows : _pageRows;
    final csv = NiceCsv.encode<T>(
      rows,
      _controller.visibleColumns(widget.columns),
    );
    if (widget.onExport != null) {
      widget.onExport!(csv);
    } else {
      Clipboard.setData(ClipboardData(text: csv));
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(
          content: Text('Copied ${rows.length} ${widget.rowLabel} as CSV'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // -------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = _theme();
    final c = _controller;

    // Resolve the page.
    if (widget.processing == NiceProcessing.client) {
      final result = c.process(widget.rows, widget.columns);
      _matchingRows = result.matchingRows;
      _pageRows = widget.paged ? result.pageRows : result.matchingRows;
      _syncTotal(result.total);
    } else {
      _pageRows = widget.rows;
      _matchingRows = widget.rows;
      _syncTotal(widget.totalRows ?? widget.rows.length);
    }

    final visibleColumns = c.visibleColumns(widget.columns);
    final selectedRows = [
      for (final r in widget.processing == NiceProcessing.client
          ? widget.rows
          : _pageRows)
        if (c.isSelected(_keyOf(r))) r,
    ];

    return NiceTableThemeScope(
      theme: theme,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bounded = constraints.hasBoundedHeight;
          final compact = widget.compactBreakpoint > 0 &&
              constraints.maxWidth < widget.compactBreakpoint;

          final toolbar = widget.showToolbar
              ? NiceTableToolbar<T>(
                  controller: c,
                  columns: widget.columns,
                  theme: theme,
                  totalRows: c.totalRows,
                  selectedRows: selectedRows,
                  pageKeys: _pageRows.map(_keyOf).toList(),
                  allMatchingKeys: widget.processing == NiceProcessing.client
                      ? _matchingRows.map(_keyOf).toList()
                      : null,
                  title: widget.title,
                  subtitle: widget.subtitle,
                  titleWidget: widget.titleWidget,
                  showSearch: widget.showSearch,
                  searchHint: widget.searchHint,
                  actions: widget.actions,
                  showColumnPicker: widget.showColumnPicker && !compact,
                  showDensityToggle: widget.showDensityToggle && !compact,
                  onExport: widget.showExport || widget.onExport != null
                      ? _export
                      : null,
                  onRefresh: widget.onRefresh,
                  bulkActions: widget.bulkActions,
                  loading: widget.loading,
                  rowLabel: widget.rowLabel,
                )
              : null;

          final footer = widget.showFooter
              ? NiceTableFooter<T>(
                  controller: c,
                  pageSizeOptions: widget.pageSizeOptions,
                  paged: widget.paged,
                  rowLabel: widget.rowLabel,
                )
              : null;

          var body = compact
              ? _buildCards(theme, visibleColumns, bounded)
              : _buildTable(
                  context, theme, visibleColumns, constraints, bounded);

          if (widget.loading && _pageRows.isNotEmpty) {
            body = Stack(
              children: [
                body,
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    backgroundColor: Colors.transparent,
                    color: theme.accent,
                  ),
                ),
              ],
            );
          }

          final column = Column(
            mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (toolbar != null) toolbar,
              if (bounded) Expanded(child: body) else body,
              if (footer != null) footer,
            ],
          );

          return Semantics(
            label: widget.semanticLabel ?? widget.title,
            container: true,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: theme.borderRadius,
                border:
                    theme.showBorder ? Border.all(color: theme.border) : null,
                boxShadow: theme.shadow,
              ),
              child: column,
            ),
          );
        },
      ),
    );
  }

  void _syncTotal(int total) {
    if (_controller.totalRows == total) return;
    // The controller clamps the page and notifies; do it after this frame
    // so we never notify during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.setTotalRows(total);
    });
  }

  Widget _buildCards(
    NiceTableTheme theme,
    List<NiceColumn<T>> columns,
    bool bounded,
  ) {
    final c = _controller;
    final state = _stateWidget(theme);
    if (state != null) return state;
    return NiceCardList<T>(
      rows: _pageRows,
      columns: columns,
      theme: theme,
      selectionMode: widget.selectionMode,
      isSelected: (r) => c.isSelected(_keyOf(r)),
      onToggleSelected: (r) =>
          _toggleRow(_pageRows.indexOf(r), fromCheckbox: true),
      onTap: widget.onRowTap == null && !_selectOnTap
          ? null
          : (r) => _onRowTap(_pageRows.indexOf(r)),
      shrinkWrap: !bounded,
      cardBuilder: widget.cardBuilder,
      scrollController: _vController,
      dimmed: widget.loading,
    );
  }

  /// Error, skeleton or empty state, or null when rows should render.
  Widget? _stateWidget(NiceTableTheme theme) {
    if (_pageRows.isNotEmpty) return null;
    if (widget.error != null) {
      return NiceErrorState(
        message: widget.error.toString(),
        onRetry: widget.onRetry,
      );
    }
    if (widget.loading) return null; // skeleton is built by the caller
    if (widget.emptyState != null) return widget.emptyState;
    final c = _controller;
    if (c.query.hasCriteria) {
      return NiceEmptyState(
        icon: Icons.search_off_rounded,
        title: 'No matching ${widget.rowLabel}',
        message: 'Try a different search or remove some filters.',
        action: TextButton.icon(
          onPressed: c.clearFilters,
          icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
          label: const Text('Clear filters'),
        ),
      );
    }
    return NiceEmptyState(
      title: widget.emptyTitle,
      message: widget.emptyMessage,
    );
  }

  Widget _buildTable(
    BuildContext context,
    NiceTableTheme theme,
    List<NiceColumn<T>> columns,
    BoxConstraints constraints,
    bool bounded,
  ) {
    final c = _controller;
    final density = _density();
    final expandable = widget.expandedBuilder != null;
    final leading =
        (widget.selectionMode == NiceSelectionMode.multi ? 48.0 : 0.0) +
            (expandable ? 40.0 : 0.0);
    final available = constraints.maxWidth - 2 * theme.horizontalPadding;
    final layout = NiceColumnLayout.resolve<T>(
      columns: columns,
      available: available,
      overrides: c.columnWidths,
      pinnedCount: widget.pinnedColumns,
      leadingWidth: leading,
    );
    final totalWidth = layout.totalWidth + 2 * theme.horizontalPadding;
    final state = _stateWidget(theme);
    final skeleton = state == null && _pageRows.isEmpty && widget.loading;

    return NiceHorizontalScroller(
      controller: _hController,
      contentWidth: totalWidth,
      builder: (context, offset) {
        final header = NiceTableHeader<T>(
          columns: columns,
          layout: layout,
          controller: c,
          theme: theme,
          density: density,
          offset: offset,
          showCheckbox: widget.selectionMode == NiceSelectionMode.multi,
          showExpander: expandable,
          selectAllState: _selectAllState(),
          onSelectAll: _selectAllOnPage,
          resizable: widget.resizableColumns,
          filterOptionsFor: _filterOptionsFor,
        );

        Widget rows;
        if (state != null) {
          rows = state;
        } else if (skeleton) {
          rows = NiceSkeletonRows(
            columnWidths: layout.widths,
            leadingWidth: layout.leadingWidth,
            density: density,
          );
        } else {
          rows = _buildRows(theme, columns, layout, density, offset, bounded);
        }

        final content = Column(
          mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            if (bounded) Expanded(child: rows) else rows,
          ],
        );

        return Scrollbar(
          controller: _hController,
          notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
          child: content,
        );
      },
    );
  }

  Widget _buildRows(
    NiceTableTheme theme,
    List<NiceColumn<T>> columns,
    NiceColumnLayout layout,
    NiceDensity density,
    ViewportOffset offset,
    bool bounded,
  ) {
    final c = _controller;
    final expandable = widget.expandedBuilder != null;

    Widget rowAt(BuildContext context, int i) {
      final row = _pageRows[i];
      final key = _keyOf(row);
      final expanded = expandable && c.isExpanded(key);
      final rowWidget = NiceTableRow<T>(
        key: ValueKey(key),
        row: row,
        index: i,
        columns: columns,
        layout: layout,
        theme: theme,
        density: density,
        offset: offset,
        selectionMode: widget.selectionMode,
        selected: c.isSelected(key),
        focused: c.focusedIndex == i,
        expandable: expandable,
        expanded: expanded,
        onTap: () => _onRowTap(i),
        onDoubleTap: widget.onRowDoubleTap == null
            ? null
            : () => widget.onRowDoubleTap!(row),
        onSecondaryTap: widget.onRowSecondaryTap == null
            ? null
            : (pos) => widget.onRowSecondaryTap!(row, pos),
        onCheckbox: widget.selectionMode == NiceSelectionMode.none
            ? null
            : () => _toggleRow(i, fromCheckbox: true),
        onToggleExpand: expandable ? () => c.toggleExpanded(key) : null,
        onHover: null,
        style: widget.rowStyle?.call(row),
        dimmed: widget.loading,
      );
      if (!expandable) return rowWidget;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          rowWidget,
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: expanded
                ? Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.headerBackground,
                      border: Border(bottom: BorderSide(color: theme.divider)),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      theme.horizontalPadding + layout.leadingWidth,
                      12,
                      theme.horizontalPadding,
                      16,
                    ),
                    child: widget.expandedBuilder!(context, row),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      );
    }

    final list = ListView.builder(
      controller: _vController,
      shrinkWrap: !bounded,
      physics: bounded ? null : const NeverScrollableScrollPhysics(),
      itemCount: _pageRows.length,
      itemExtent: expandable ? null : density.rowHeight,
      itemBuilder: rowAt,
    );

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _onKey,
      child: bounded
          ? Scrollbar(
              controller: _vController,
              notificationPredicate: (n) => n.metrics.axis == Axis.vertical,
              child: list,
            )
          : list,
    );
  }
}
