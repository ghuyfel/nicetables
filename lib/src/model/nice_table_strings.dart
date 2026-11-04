import 'package:flutter/widgets.dart';

import 'nice_density.dart';
import 'nice_format.dart';

/// Every piece of text a table draws on its own: tooltips, the footer,
/// the empty and error states, the search placeholder. English by default.
///
/// Hand a table one through `NiceTable.strings`, or put a
/// [NiceTableStringsScope] above every table (above your `MaterialApp`'s
/// pages, for instance) to translate them all at once:
///
/// ```dart
/// NiceTableStringsScope(
///   strings: NiceTableStrings(
///     search: 'Rechercher',
///     rowsPerPage: 'Lignes par page',
///     rowRange: (first, last, total) => '$first–$last sur $total',
///   ),
///   child: child,
/// )
/// ```
///
/// Counts are passed to the function-typed fields as numbers, so a
/// translation can place them where its grammar wants and format them as
/// its locale wants; the defaults use [NiceFormat.number].
@immutable
class NiceTableStrings {
  /// Creates a set of strings; every field defaults to its English text.
  const NiceTableStrings({
    this.search = 'Search',
    this.clearSearch = 'Clear search',
    this.rows = 'rows',
    this.rowCount = defaultRowCount,
    this.emptyTitle = 'Nothing here yet',
    this.noMatchTitle = defaultNoMatchTitle,
    this.noMatchMessage = 'Try a different search or remove some filters.',
    this.clearFilters = 'Clear filters',
    this.clearAll = 'Clear all',
    this.removeFilter = 'Remove filter',
    this.clearFilter = 'Clear filter',
    this.errorTitle = 'Could not load data',
    this.retry = 'Retry',
    this.loading = 'Loading',
    this.rowsPerPage = 'Rows per page',
    this.firstPage = 'First page',
    this.previousPage = 'Previous page',
    this.nextPage = 'Next page',
    this.lastPage = 'Last page',
    this.goTo = 'Go to',
    this.goToPage = 'Go to page',
    this.pageOfCount = defaultPageOfCount,
    this.rowRange = defaultRowRange,
    this.selectedCount = defaultSelectedCount,
    this.selectAllCount = defaultSelectAllCount,
    this.clearSelection = 'Clear selection',
    this.selectAllOnPage = 'Select all rows on this page',
    this.columns = 'Columns',
    this.density = 'Density',
    this.densityCompact = 'Compact',
    this.densityComfortable = 'Comfortable',
    this.densitySpacious = 'Spacious',
    this.exportCsv = 'Export CSV',
    this.copiedAsCsv = defaultCopiedAsCsv,
    this.refresh = 'Refresh',
    this.expand = 'Expand',
    this.collapse = 'Collapse',
    this.yes = 'Yes',
    this.no = 'No',
    this.copy = 'Copy',
    this.copied = 'Copied',
    this.moreActions = 'More actions',
    this.sort = 'sort',
    this.sortedAscending = 'sorted ascending',
    this.sortedDescending = 'sorted descending',
  });

  /// Search field placeholder.
  final String search;

  /// Tooltip of the button that empties the search field.
  final String clearSearch;

  /// Noun for counts when the table names none ("rows", "orders").
  final String rows;

  /// A count with its noun, e.g. "12 rows" (toolbar subtitle, unpaged
  /// footer).
  final String Function(int count, String rowLabel) rowCount;

  /// Empty-state title when the table has no rows at all.
  final String emptyTitle;

  /// Empty-state title when search or filters match nothing, e.g.
  /// "No matching rows".
  final String Function(String rowLabel) noMatchTitle;

  /// Empty-state message under [noMatchTitle].
  final String noMatchMessage;

  /// Button under [noMatchTitle] and label of the chip row's reset.
  final String clearFilters;

  /// Button that removes every active filter chip.
  final String clearAll;

  /// Tooltip of a filter chip's delete icon.
  final String removeFilter;

  /// Menu item that clears one column's filter.
  final String clearFilter;

  /// Error-state title.
  final String errorTitle;

  /// Error-state retry button.
  final String retry;

  /// Accessibility label of the skeleton rows.
  final String loading;

  /// Label before the rows-per-page picker, and its accessibility label.
  final String rowsPerPage;

  /// Tooltip of the first-page button.
  final String firstPage;

  /// Tooltip of the previous-page button.
  final String previousPage;

  /// Tooltip of the next-page button.
  final String nextPage;

  /// Tooltip of the last-page button.
  final String lastPage;

  /// Label before the "go to page" field.
  final String goTo;

  /// Accessibility label of the "go to page" field.
  final String goToPage;

  /// The narrow pager's position, e.g. "3 of 12" (one-based).
  final String Function(int page, int pageCount) pageOfCount;

  /// The visible row range, e.g. "1–25 of 300"; [rowLabel] is empty when
  /// the footer is too narrow to name the rows.
  final String Function(int first, int last, int total, String rowLabel)
      rowRange;

  /// A selection count, e.g. "3 selected".
  final String Function(int count) selectedCount;

  /// The bulk bar's button that extends the selection to every matching
  /// row, e.g. "Select all 300".
  final String Function(int count) selectAllCount;

  /// Tooltip of the bulk bar's close button.
  final String clearSelection;

  /// Accessibility label of the header checkbox.
  final String selectAllOnPage;

  /// Tooltip of the column picker.
  final String columns;

  /// Tooltip of the density menu.
  final String density;

  /// Density menu item for [NiceDensity.compact].
  final String densityCompact;

  /// Density menu item for [NiceDensity.comfortable].
  final String densityComfortable;

  /// Density menu item for [NiceDensity.spacious].
  final String densitySpacious;

  /// Tooltip of the export button.
  final String exportCsv;

  /// Snack bar after an export copied the CSV to the clipboard, e.g.
  /// "Copied 12 rows as CSV".
  final String Function(int count, String rowLabel) copiedAsCsv;

  /// Tooltip of the refresh button.
  final String refresh;

  /// Tooltip of a collapsed row's expander.
  final String expand;

  /// Tooltip of an expanded row's expander.
  final String collapse;

  /// Text of a true boolean cell (its accessibility label, search text
  /// and export value).
  final String yes;

  /// Text of a false boolean cell.
  final String no;

  /// Tooltip of a copyable cell's copy icon.
  final String copy;

  /// Tooltip of a copyable cell's copy icon right after copying.
  final String copied;

  /// Tooltip of the row actions overflow menu.
  final String moreActions;

  /// Accessibility suffix of an unsorted sortable header ("Name, sort").
  final String sort;

  /// Accessibility suffix of a header sorted ascending.
  final String sortedAscending;

  /// Accessibility suffix of a header sorted descending.
  final String sortedDescending;

  /// The menu label for [density].
  String densityLabel(NiceDensity density) => switch (density) {
        NiceDensity.compact => densityCompact,
        NiceDensity.comfortable => densityComfortable,
        NiceDensity.spacious => densitySpacious,
      };

  /// The strings of the nearest [NiceTableStringsScope], else the English
  /// defaults.
  static NiceTableStrings of(BuildContext context) =>
      NiceTableStringsScope.maybeOf(context) ?? const NiceTableStrings();

  /// Default for [rowCount].
  static String defaultRowCount(int count, String rowLabel) =>
      '${NiceFormat.number(count)} $rowLabel';

  /// Default for [noMatchTitle].
  static String defaultNoMatchTitle(String rowLabel) => 'No matching $rowLabel';

  /// Default for [pageOfCount].
  static String defaultPageOfCount(int page, int pageCount) =>
      '$page of $pageCount';

  /// Default for [rowRange].
  static String defaultRowRange(
    int first,
    int last,
    int total,
    String rowLabel,
  ) =>
      '${NiceFormat.number(first)}–${NiceFormat.number(last)}'
      ' of ${NiceFormat.number(total)}'
      '${rowLabel.isEmpty ? '' : ' $rowLabel'}';

  /// Default for [selectedCount].
  static String defaultSelectedCount(int count) =>
      '${NiceFormat.number(count)} selected';

  /// Default for [selectAllCount].
  static String defaultSelectAllCount(int count) =>
      'Select all ${NiceFormat.number(count)}';

  /// Default for [copiedAsCsv].
  static String defaultCopiedAsCsv(int count, String rowLabel) =>
      'Copied ${NiceFormat.number(count)} $rowLabel as CSV';
}

/// Provides [NiceTableStrings] to every table (and every nicetables cell)
/// in [child]. A table's own `strings` argument wins over the scope.
class NiceTableStringsScope extends InheritedWidget {
  /// Creates a strings scope.
  const NiceTableStringsScope({
    required this.strings,
    required super.child,
    super.key,
  });

  /// The strings to use.
  final NiceTableStrings strings;

  /// The nearest scoped strings, if any.
  static NiceTableStrings? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<NiceTableStringsScope>()
      ?.strings;

  @override
  bool updateShouldNotify(NiceTableStringsScope oldWidget) =>
      oldWidget.strings != strings;
}
