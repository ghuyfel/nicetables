import 'package:flutter/foundation.dart';

import '../model/nice_column.dart';
import '../model/nice_density.dart';
import '../model/nice_filter.dart';
import '../model/nice_query.dart';
import '../model/nice_sort.dart';

/// The outcome of client-side processing: the rows of the current page and
/// how many rows matched in total.
class NiceTableResult<T> {
  /// Creates a result.
  const NiceTableResult({
    required this.pageRows,
    required this.matchingRows,
  });

  /// Rows to display on the current page.
  final List<T> pageRows;

  /// Every row that passed search and filters, sorted.
  final List<T> matchingRows;

  /// Number of matching rows.
  int get total => matchingRows.length;
}

/// Owns everything the user can change about a table: sort, search,
/// filters, page, selection, expansion, column visibility and widths, row
/// density and keyboard focus.
///
/// A `NiceTable` creates one internally when you do not pass one. Pass
/// your own to read state (selected rows, the current [query]) or drive it
/// from outside (a search field in the app bar, a "clear filters" button).
///
/// Client-side processing is [process]; it is pure and cached, so calling
/// it on every build is fine.
class NiceTableController<T> extends ChangeNotifier {
  /// Creates a controller with optional initial state.
  NiceTableController({
    NiceSort? sort,
    String search = '',
    Map<String, NiceFilter<T>> filters = const {},
    int page = 0,
    int pageSize = 25,
    Iterable<Object> selectedKeys = const [],
    Iterable<String> hiddenColumns = const [],
    NiceDensity? density,
  })  : _query = NiceQuery<T>(
          sort: sort,
          search: search.trim(),
          filters: Map.unmodifiable(filters),
          page: page,
          pageSize: pageSize,
        ),
        _selected = {...selectedKeys},
        _hidden = {...hiddenColumns},
        _density = density;

  NiceQuery<T> _query;
  final Set<Object> _selected;
  final Set<Object> _expanded = {};
  final Set<String> _hidden;
  final Map<String, double> _widths = {};
  NiceDensity? _density;
  int? _focusedIndex;
  int _totalRows = 0;

  // ---------------------------------------------------------------------
  // Query
  // ---------------------------------------------------------------------

  /// Sort, search, filters and page as one immutable value.
  NiceQuery<T> get query => _query;

  void _setQuery(NiceQuery<T> next) {
    if (next == _query) return;
    _query = next;
    notifyListeners();
  }

  /// Active sort, if any.
  NiceSort? get sort => _query.sort;

  /// Sorts by [columnId] in [direction].
  void sortBy(
    String columnId, [
    NiceSortDirection direction = NiceSortDirection.ascending,
  ]) =>
      _setQuery(_query.copyWith(sort: NiceSort(columnId, direction), page: 0));

  /// Cycles the sort of [columnId]: ascending, descending, then none.
  void toggleSort(String columnId) {
    final current = _query.sort;
    if (current == null || current.columnId != columnId) {
      sortBy(columnId);
    } else if (current.ascending) {
      sortBy(columnId, NiceSortDirection.descending);
    } else {
      clearSort();
    }
  }

  /// Removes the sort.
  void clearSort() => _setQuery(_query.copyWith(clearSort: true, page: 0));

  /// Free text search.
  String get search => _query.search;

  /// Sets the free text search and returns to the first page.
  void setSearch(String text) {
    final trimmed = text.trim();
    if (trimmed == _query.search) return;
    _setQuery(_query.copyWith(search: trimmed, page: 0));
  }

  /// Active filters keyed by column id.
  Map<String, NiceFilter<T>> get filters => _query.filters;

  /// Sets (or with null, removes) the filter for [key] and returns to the
  /// first page.
  void setFilter(String key, NiceFilter<T>? filter) {
    final next = Map<String, NiceFilter<T>>.of(_query.filters);
    if (filter == null) {
      if (next.remove(key) == null) return;
    } else {
      next[key] = filter;
    }
    _setQuery(_query.copyWith(filters: Map.unmodifiable(next), page: 0));
  }

  /// Removes the filter for [key].
  void removeFilter(String key) => setFilter(key, null);

  /// Removes every filter and the search text.
  void clearFilters() {
    if (!_query.hasCriteria) return;
    _setQuery(_query.copyWith(search: '', filters: const {}, page: 0));
  }

  // ---------------------------------------------------------------------
  // Paging
  // ---------------------------------------------------------------------

  /// Zero-based current page.
  int get page => _query.page;

  /// Rows per page.
  int get pageSize => _query.pageSize;

  /// Total rows after search and filters. Set by the table after
  /// [process], or by a server-side source.
  int get totalRows => _totalRows;

  /// Number of pages (at least 1).
  int get pageCount =>
      _totalRows == 0 ? 1 : ((_totalRows + pageSize - 1) ~/ pageSize);

  /// Whether a next page exists.
  bool get hasNextPage => page < pageCount - 1;

  /// Whether a previous page exists.
  bool get hasPreviousPage => page > 0;

  /// One-based index of the first row on this page (0 when empty).
  int get firstRowNumber => _totalRows == 0 ? 0 : page * pageSize + 1;

  /// One-based index of the last row on this page.
  int get lastRowNumber =>
      _totalRows == 0 ? 0 : ((page + 1) * pageSize).clamp(0, _totalRows);

  /// Records the total row count; clamps the page into range.
  ///
  /// Called by the table. Only notifies when something changed.
  void setTotalRows(int total) {
    if (total == _totalRows && page < pageCount) return;
    _totalRows = total;
    final maxPage = pageCount - 1;
    if (page > maxPage) {
      _query = _query.copyWith(page: maxPage);
    }
    notifyListeners();
  }

  /// Goes to [index], clamped to the known page range.
  void goToPage(int index) {
    final clamped = index.clamp(0, pageCount - 1);
    _setQuery(_query.copyWith(page: clamped));
  }

  /// Goes to the next page if there is one.
  void nextPage() {
    if (hasNextPage) goToPage(page + 1);
  }

  /// Goes to the previous page if there is one.
  void previousPage() {
    if (hasPreviousPage) goToPage(page - 1);
  }

  /// Goes to the first page.
  void firstPage() => goToPage(0);

  /// Goes to the last page.
  void lastPage() => goToPage(pageCount - 1);

  /// Changes the rows per page, keeping the first visible row on screen.
  void setPageSize(int size) {
    assert(size > 0, 'pageSize must be positive');
    if (size == pageSize) return;
    final firstRow = page * pageSize;
    _setQuery(_query.copyWith(pageSize: size, page: firstRow ~/ size));
  }

  // ---------------------------------------------------------------------
  // Selection
  // ---------------------------------------------------------------------

  /// Keys of the selected rows (see `NiceTable.rowKey`).
  Set<Object> get selectedKeys => Set.unmodifiable(_selected);

  /// Number of selected rows.
  int get selectedCount => _selected.length;

  /// Whether any row is selected.
  bool get hasSelection => _selected.isNotEmpty;

  /// Whether [key] is selected.
  bool isSelected(Object key) => _selected.contains(key);

  /// Selects or deselects [key].
  void setSelected(Object key, bool selected) {
    final changed = selected ? _selected.add(key) : _selected.remove(key);
    if (changed) notifyListeners();
  }

  /// Flips the selection of [key].
  void toggleSelected(Object key) => setSelected(key, !isSelected(key));

  /// Selects exactly [key], deselecting everything else.
  void selectOnly(Object key) {
    if (_selected.length == 1 && _selected.contains(key)) return;
    _selected
      ..clear()
      ..add(key);
    notifyListeners();
  }

  /// Adds every key in [keys] to the selection.
  void selectAll(Iterable<Object> keys) {
    final before = _selected.length;
    _selected.addAll(keys);
    if (_selected.length != before) notifyListeners();
  }

  /// Removes every key in [keys] from the selection.
  void deselectAll(Iterable<Object> keys) {
    final before = _selected.length;
    _selected.removeAll(keys);
    if (_selected.length != before) notifyListeners();
  }

  /// Clears the selection.
  void clearSelection() {
    if (_selected.isEmpty) return;
    _selected.clear();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Expansion
  // ---------------------------------------------------------------------

  /// Keys of rows whose detail panel is open.
  Set<Object> get expandedKeys => Set.unmodifiable(_expanded);

  /// Whether [key]'s detail panel is open.
  bool isExpanded(Object key) => _expanded.contains(key);

  /// Opens or closes [key]'s detail panel.
  void setExpanded(Object key, bool expanded) {
    final changed = expanded ? _expanded.add(key) : _expanded.remove(key);
    if (changed) notifyListeners();
  }

  /// Flips [key]'s detail panel.
  void toggleExpanded(Object key) => setExpanded(key, !isExpanded(key));

  /// Closes every detail panel.
  void collapseAll() {
    if (_expanded.isEmpty) return;
    _expanded.clear();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Columns
  // ---------------------------------------------------------------------

  /// Ids of hidden columns.
  Set<String> get hiddenColumns => Set.unmodifiable(_hidden);

  /// Whether [columnId] is visible, given the column's own default.
  bool isColumnVisible(NiceColumn<T> column) => column.visible
      ? !_hidden.contains(column.id)
      : _shown.contains(column.id);
  final Set<String> _shown = {};

  /// Shows or hides [column].
  void setColumnVisible(NiceColumn<T> column, bool visible) {
    bool changed;
    if (column.visible) {
      changed = visible ? _hidden.remove(column.id) : _hidden.add(column.id);
    } else {
      changed = visible ? _shown.add(column.id) : _shown.remove(column.id);
    }
    if (changed) notifyListeners();
  }

  /// Flips [column]'s visibility.
  void toggleColumn(NiceColumn<T> column) =>
      setColumnVisible(column, !isColumnVisible(column));

  /// The visible subset of [columns], in order.
  List<NiceColumn<T>> visibleColumns(List<NiceColumn<T>> columns) => [
        for (final c in columns)
          if (isColumnVisible(c)) c
      ];

  /// User-resized column widths in px, keyed by column id.
  Map<String, double> get columnWidths => Map.unmodifiable(_widths);

  /// Width override for [columnId], if the user resized it.
  double? columnWidth(String columnId) => _widths[columnId];

  /// Sets a width override for [columnId].
  void setColumnWidth(String columnId, double width) {
    if (_widths[columnId] == width) return;
    _widths[columnId] = width;
    notifyListeners();
  }

  /// Removes the width override for [columnId].
  void clearColumnWidth(String columnId) {
    if (_widths.remove(columnId) == null) return;
    notifyListeners();
  }

  /// Removes every width override.
  void resetColumnWidths() {
    if (_widths.isEmpty) return;
    _widths.clear();
    notifyListeners();
  }

  /// Density override; null uses the theme's density.
  NiceDensity? get density => _density;

  /// Sets the density override.
  void setDensity(NiceDensity? density) {
    if (density == _density) return;
    _density = density;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Keyboard focus
  // ---------------------------------------------------------------------

  /// Index (within the page) of the keyboard-focused row.
  int? get focusedIndex => _focusedIndex;

  /// Sets the keyboard-focused row index.
  void setFocusedIndex(int? index) {
    if (index == _focusedIndex) return;
    _focusedIndex = index;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Processing
  // ---------------------------------------------------------------------

  List<T>? _cacheRows;
  NiceQuery<T>? _cacheQuery;
  List<T>? _cacheMatching;

  /// Applies search, filters and sort to [rows] using [columns], then slices
  /// the current page.
  ///
  /// Pure with respect to inputs; the sorted result is cached until [rows]
  /// (by identity), the sort, the search or the filters change.
  NiceTableResult<T> process(List<T> rows, List<NiceColumn<T>> columns) {
    final q = _query;
    final reuse = identical(rows, _cacheRows) &&
        _cacheQuery != null &&
        _cacheQuery!.sort == q.sort &&
        _cacheQuery!.search == q.search &&
        identical(_cacheQuery!.filters, q.filters);
    final matching = reuse ? _cacheMatching! : _compute(rows, columns, q);
    _cacheRows = rows;
    _cacheQuery = q;
    _cacheMatching = matching;

    final start = (q.page * q.pageSize).clamp(0, matching.length);
    final end = (start + q.pageSize).clamp(0, matching.length);
    return NiceTableResult<T>(
      pageRows: matching.sublist(start, end),
      matchingRows: matching,
    );
  }

  /// Forgets the cached result so the next [process] recomputes, for when
  /// rows were mutated in place.
  void invalidate() {
    _cacheRows = null;
    notifyListeners();
  }

  List<T> _compute(List<T> rows, List<NiceColumn<T>> columns, NiceQuery<T> q) {
    Iterable<T> result = rows;

    if (q.filters.isNotEmpty) {
      final predicates = q.filters.values.map((f) => f.predicate).toList();
      result = result.where((row) => predicates.every((p) => p(row)));
    }

    if (q.search.isNotEmpty) {
      final tokens = q.search.toLowerCase().split(RegExp(r'\s+'));
      final searchable = columns.where((c) => c.searchable).toList();
      result = result.where((row) {
        final haystack = searchable
            .map((c) => c.displayText(row).toLowerCase())
            .join('\u0000');
        return tokens.every(haystack.contains);
      });
    }

    final list = result.toList();
    final sort = q.sort;
    if (sort != null) {
      NiceColumn<T>? column;
      for (final c in columns) {
        if (c.id == sort.columnId) {
          column = c;
          break;
        }
      }
      if (column != null) {
        final sign = sort.ascending ? 1 : -1;
        final indexed = List.generate(list.length, (i) => i);
        // Stable sort: ties keep source order.
        indexed.sort((a, b) {
          final c = column!.compare(list[a], list[b]) * sign;
          return c != 0 ? c : a.compareTo(b);
        });
        return [for (final i in indexed) list[i]];
      }
    }
    return list;
  }

  /// Restores sort, search, filters, page, selection, expansion, hidden
  /// columns and widths to their defaults.
  void reset({int? pageSize}) {
    _query = NiceQuery<T>(pageSize: pageSize ?? _query.pageSize);
    _selected.clear();
    _expanded.clear();
    _hidden.clear();
    _shown.clear();
    _widths.clear();
    _focusedIndex = null;
    _cacheRows = null;
    notifyListeners();
  }
}
