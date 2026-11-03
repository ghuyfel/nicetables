/// A filter applied to the rows of a table, keyed by a column id (or any
/// string for filters that are not tied to a column).
///
/// Filters are evaluated client-side by `NiceTableController.process`, and
/// are also part of `NiceQuery` so a server-side source can translate them.
class NiceFilter<T> {
  /// Creates a filter with a [predicate] and a human readable [label].
  const NiceFilter({
    required this.label,
    required this.predicate,
    this.value,
  });

  /// Keeps rows whose column value equals [value].
  ///
  /// `valueOf` is the column's value callback.
  factory NiceFilter.equals({
    required Object? value,
    required Object? Function(T row) valueOf,
    String? label,
  }) =>
      NiceFilter<T>(
        label: label ?? '$value',
        value: value,
        predicate: (row) => valueOf(row) == value,
      );

  /// Keeps rows whose column value is one of [values].
  factory NiceFilter.oneOf({
    required Iterable<Object?> values,
    required Object? Function(T row) valueOf,
    String? label,
  }) {
    final set = values.toSet();
    return NiceFilter<T>(
      label: label ?? set.join(', '),
      value: set,
      predicate: (row) => set.contains(valueOf(row)),
    );
  }

  /// Keeps rows whose column text contains [text] (case-insensitive).
  factory NiceFilter.contains({
    required String text,
    required Object? Function(T row) valueOf,
    String? label,
  }) {
    final needle = text.toLowerCase();
    return NiceFilter<T>(
      label: label ?? '"$text"',
      value: text,
      predicate: (row) =>
          (valueOf(row)?.toString().toLowerCase() ?? '').contains(needle),
    );
  }

  /// Keeps rows whose comparable column value lies in `[min, max]`.
  ///
  /// Either bound may be null to leave that side open.
  factory NiceFilter.range({
    required Comparable<Object?>? min,
    required Comparable<Object?>? max,
    required Object? Function(T row) valueOf,
    String? label,
  }) =>
      NiceFilter<T>(
        label: label ?? '${min ?? '...'} to ${max ?? '...'}',
        value: (min, max),
        predicate: (row) {
          final v = valueOf(row);
          if (v == null) return false;
          if (min != null && min.compareTo(v) > 0) return false;
          if (max != null && max.compareTo(v) < 0) return false;
          return true;
        },
      );

  /// Chip label shown in the toolbar.
  final String label;

  /// Returns true for rows that should stay visible.
  final bool Function(T row) predicate;

  /// Optional raw value, handy for server-side sources that translate
  /// filters into query parameters.
  final Object? value;
}

/// One choice in a column's filter menu.
class NiceFilterOption {
  /// Creates a filter option.
  const NiceFilterOption(this.value, {String? label}) : _label = label;

  /// The column value this option matches.
  final Object? value;
  final String? _label;

  /// Label to display; defaults to the value's string form.
  String get label => _label ?? '$value';
}
