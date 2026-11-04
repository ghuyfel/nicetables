import 'package:flutter/material.dart';

import '../controller/nice_table_controller.dart';
import '../model/nice_column.dart';
import '../model/nice_density.dart';
import '../model/nice_query.dart';
import '../model/nice_table_strings.dart';
import '../theme/nice_table_theme.dart';
import 'nice_card_list.dart';
import 'nice_table.dart';
import 'nice_table_row.dart';
import 'nice_table_toolbar.dart';

/// One page of results from a server-side source.
class NicePage<T> {
  /// Creates a page.
  const NicePage({required this.rows, required this.total});

  /// Rows of this page.
  final List<T> rows;

  /// Total rows matching the query across all pages.
  final int total;
}

/// Fetches a page for a query.
typedef NiceFetch<T> = Future<NicePage<T>> Function(NiceQuery<T> query);

/// A [NiceTable] driven by an async [fetch]: it calls [fetch] on first
/// build and whenever the query changes, and shows skeleton, progress,
/// error and retry states for you.
///
/// ```dart
/// NiceAsyncTable<Order>(
///   fetch: (q) async {
///     final page = await api.orders(
///       offset: q.offset, limit: q.pageSize,
///       sort: q.sort?.columnId, desc: q.sort?.ascending == false,
///       search: q.search,
///     );
///     return NicePage(rows: page.items, total: page.total);
///   },
///   columns: [...],
/// )
/// ```
///
/// Responses that arrive out of order are dropped, so a slow earlier page
/// never overwrites a newer one.
class NiceAsyncTable<T> extends StatefulWidget {
  /// Creates an async table. See [NiceTable] for the shared parameters.
  const NiceAsyncTable({
    required this.fetch,
    required this.columns,
    this.controller,
    this.rowKey,
    this.title,
    this.subtitle,
    this.titleWidget,
    this.showToolbar = true,
    this.showSearch = true,
    this.searchHint,
    this.actions = const [],
    this.showColumnPicker = true,
    this.showDensityToggle = false,
    this.showExport = false,
    this.onExport,
    this.showRefresh = true,
    this.refreshIndicator,
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
    this.pageSizeOptions = const [10, 25, 50, 100],
    this.showFooter = true,
    this.showPageJump = true,
    this.density,
    this.theme,
    this.compactBreakpoint = 600,
    this.cardBuilder,
    this.emptyState,
    this.emptyTitle,
    this.emptyMessage,
    this.rowLabel,
    this.semanticLabel,
    this.strings,
    super.key,
  });

  /// Loads a page for a query.
  final NiceFetch<T> fetch;

  /// Column definitions.
  final List<NiceColumn<T>> columns;

  /// Optional controller.
  final NiceTableController<T>? controller;

  /// Row identity for selection.
  final Object Function(T row)? rowKey;

  /// Toolbar title.
  final String? title;

  /// Toolbar subtitle.
  final String? subtitle;

  /// Replaces the title block.
  final Widget? titleWidget;

  /// Whether to show the toolbar.
  final bool showToolbar;

  /// Whether to show the search field.
  final bool showSearch;

  /// Search placeholder.
  final String? searchHint;

  /// Trailing toolbar widgets.
  final List<Widget> actions;

  /// Column visibility menu.
  final bool showColumnPicker;

  /// Density menu.
  final bool showDensityToggle;

  /// Export button.
  final bool showExport;

  /// Receives the CSV of the current page.
  final ValueChanged<String>? onExport;

  /// Refresh button that re-runs the current query.
  final bool showRefresh;

  /// See [NiceTable.refreshIndicator].
  final Widget? refreshIndicator;

  /// Bulk bar buttons.
  final NiceBulkActionsBuilder<T>? bulkActions;

  /// Selection behaviour.
  final NiceSelectionMode selectionMode;

  /// Whether a row tap selects.
  final bool? selectOnTap;

  /// Selection callback.
  final ValueChanged<List<T>>? onSelectionChanged;

  /// Row tap.
  final void Function(T row)? onRowTap;

  /// Row double tap.
  final void Function(T row)? onRowDoubleTap;

  /// Right click / long press.
  final void Function(T row, Offset globalPosition)? onRowSecondaryTap;

  /// Expanded detail builder.
  final NiceExpandedBuilder<T>? expandedBuilder;

  /// Per-row style.
  final NiceRowStyle? Function(T row)? rowStyle;

  /// Pinned leading columns.
  final int pinnedColumns;

  /// Resizable columns.
  final bool resizableColumns;

  /// Rows-per-page choices.
  final List<int> pageSizeOptions;

  /// Footer visibility.
  final bool showFooter;

  /// "Go to page" field in the footer.
  final bool showPageJump;

  /// Density override.
  final NiceDensity? density;

  /// Theme override.
  final NiceTableTheme? theme;

  /// Card layout breakpoint.
  final double compactBreakpoint;

  /// Custom card.
  final NiceCardBuilder<T>? cardBuilder;

  /// Custom empty state.
  final Widget? emptyState;

  /// Empty title.
  final String? emptyTitle;

  /// Empty message.
  final String? emptyMessage;

  /// Noun for counts.
  final String? rowLabel;

  /// The text the table draws itself; see [NiceTable.strings].
  final NiceTableStrings? strings;

  /// Accessibility label.
  final String? semanticLabel;

  @override
  State<NiceAsyncTable<T>> createState() => _NiceAsyncTableState<T>();
}

class _NiceAsyncTableState<T> extends State<NiceAsyncTable<T>> {
  NiceTableController<T>? _own;
  NiceTableController<T> get _controller =>
      widget.controller ?? (_own ??= NiceTableController<T>());

  List<T> _rows = const [];
  int _total = 0;
  bool _loading = true;
  Object? _error;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _load(_controller.query);
  }

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  Future<void> _load(NiceQuery<T> query) async {
    final id = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.fetch(query);
      if (!mounted || id != _requestId) return;
      setState(() {
        _rows = page.rows;
        _total = page.total;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _error = e;
        _loading = false;
        if (query.page == 0) _rows = const [];
      });
    }
  }

  void _refresh() => _load(_controller.query);

  @override
  Widget build(BuildContext context) => NiceTable<T>(
        rows: _rows,
        columns: widget.columns,
        controller: _controller,
        rowKey: widget.rowKey,
        processing: NiceProcessing.server,
        totalRows: _total,
        onQueryChanged: _load,
        loading: _loading,
        error: _error,
        onRetry: _refresh,
        title: widget.title,
        subtitle: widget.subtitle,
        titleWidget: widget.titleWidget,
        showToolbar: widget.showToolbar,
        showSearch: widget.showSearch,
        searchHint: widget.searchHint,
        actions: widget.actions,
        showColumnPicker: widget.showColumnPicker,
        showDensityToggle: widget.showDensityToggle,
        showExport: widget.showExport,
        onExport: widget.onExport,
        onRefresh: widget.showRefresh ? _refresh : null,
        refreshIndicator: widget.refreshIndicator,
        bulkActions: widget.bulkActions,
        selectionMode: widget.selectionMode,
        selectOnTap: widget.selectOnTap,
        onSelectionChanged: widget.onSelectionChanged,
        onRowTap: widget.onRowTap,
        onRowDoubleTap: widget.onRowDoubleTap,
        onRowSecondaryTap: widget.onRowSecondaryTap,
        expandedBuilder: widget.expandedBuilder,
        rowStyle: widget.rowStyle,
        pinnedColumns: widget.pinnedColumns,
        resizableColumns: widget.resizableColumns,
        pageSizeOptions: widget.pageSizeOptions,
        showFooter: widget.showFooter,
        showPageJump: widget.showPageJump,
        strings: widget.strings,
        density: widget.density,
        theme: widget.theme,
        compactBreakpoint: widget.compactBreakpoint,
        cardBuilder: widget.cardBuilder,
        emptyState: widget.emptyState,
        emptyTitle: widget.emptyTitle,
        emptyMessage: widget.emptyMessage,
        rowLabel: widget.rowLabel,
        semanticLabel: widget.semanticLabel,
      );
}
