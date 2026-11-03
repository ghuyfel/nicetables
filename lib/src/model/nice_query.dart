import 'package:meta/meta.dart';

import 'nice_filter.dart';
import 'nice_sort.dart';

/// An immutable snapshot of everything that determines which rows are
/// visible: sort, search, filters and the current page.
///
/// Server-side sources receive one of these whenever the user changes any of
/// them and translate it into a request.
@immutable
class NiceQuery<T> {
  /// Creates a query.
  const NiceQuery({
    this.sort,
    this.search = '',
    this.filters = const {},
    this.page = 0,
    this.pageSize = 25,
  });

  /// Active sort, if any.
  final NiceSort? sort;

  /// Free text search, trimmed.
  final String search;

  /// Active filters keyed by column id (or any string).
  final Map<String, NiceFilter<T>> filters;

  /// Zero-based page index.
  final int page;

  /// Rows per page.
  final int pageSize;

  /// Offset of the first row of this page.
  int get offset => page * pageSize;

  /// Whether any search text or filter is active.
  bool get hasCriteria => search.isNotEmpty || filters.isNotEmpty;

  /// Returns a copy with the given fields replaced.
  NiceQuery<T> copyWith({
    NiceSort? sort,
    bool clearSort = false,
    String? search,
    Map<String, NiceFilter<T>>? filters,
    int? page,
    int? pageSize,
  }) =>
      NiceQuery<T>(
        sort: clearSort ? null : (sort ?? this.sort),
        search: search ?? this.search,
        filters: filters ?? this.filters,
        page: page ?? this.page,
        pageSize: pageSize ?? this.pageSize,
      );

  @override
  bool operator ==(Object other) =>
      other is NiceQuery<T> &&
      other.sort == sort &&
      other.search == search &&
      other.page == page &&
      other.pageSize == pageSize &&
      _sameFilters(other.filters);

  bool _sameFilters(Map<String, NiceFilter<T>> other) {
    if (other.length != filters.length) return false;
    for (final entry in filters.entries) {
      if (!identical(other[entry.key], entry.value)) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(sort, search, page, pageSize, Object.hashAll(filters.keys));

  @override
  String toString() =>
      'NiceQuery(sort: $sort, search: "$search", filters: ${filters.keys}, '
      'page: $page, pageSize: $pageSize)';
}
