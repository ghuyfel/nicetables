import 'package:flutter/widgets.dart';

import 'nice_filter.dart';
import 'nice_format.dart';
import 'nice_status.dart';

/// Horizontal alignment of a cell's content.
enum NiceAlign {
  /// Leading edge (left in LTR).
  start,

  /// Centred.
  center,

  /// Trailing edge (right in LTR). The default for numeric columns.
  end;

  /// The [Alignment] equivalent, resolved for LTR.
  AlignmentGeometry get alignment => switch (this) {
        NiceAlign.start => AlignmentDirectional.centerStart,
        NiceAlign.center => AlignmentDirectional.center,
        NiceAlign.end => AlignmentDirectional.centerEnd,
      };

  /// The [TextAlign] equivalent.
  TextAlign get textAlign => switch (this) {
        NiceAlign.start => TextAlign.start,
        NiceAlign.center => TextAlign.center,
        NiceAlign.end => TextAlign.end,
      };
}

/// How a column shares the table's width.
///
/// Flex columns divide whatever is left after fixed columns, never going
/// below [min]. When the minimums do not fit, the table scrolls
/// horizontally.
class NiceColumnWidth {
  /// A column that grows with [flex] weight, at least [min] px wide.
  const NiceColumnWidth.flex(this.flex, {this.min = 96, this.max})
      : fixed = null;

  /// A column that is always [px] wide.
  const NiceColumnWidth.fixed(double px)
      : fixed = px,
        flex = 0,
        min = px,
        max = px;

  /// Fixed width in px, or null for a flex column.
  final double? fixed;

  /// Flex weight; 0 for fixed columns.
  final double flex;

  /// Minimum width in px.
  final double min;

  /// Optional maximum width in px.
  final double? max;

  /// Whether this is a fixed-width column.
  bool get isFixed => fixed != null;

  /// Clamps [width] into this column's bounds.
  double clamp(double width) {
    if (fixed != null) return fixed!;
    var w = width < min ? min : width;
    if (max != null && w > max!) w = max!;
    return w;
  }
}

/// Information about the row a cell is being built for.
class NiceCellContext {
  /// Creates a cell context.
  const NiceCellContext({
    required this.rowIndex,
    required this.selected,
    required this.hovered,
    required this.focused,
    required this.expanded,
  });

  /// Index of the row within the visible page.
  final int rowIndex;

  /// Whether the row is selected.
  final bool selected;

  /// Whether the pointer is over the row.
  final bool hovered;

  /// Whether the row has keyboard focus.
  final bool focused;

  /// Whether the row's detail panel is open.
  final bool expanded;
}

/// Builds a cell widget for [row].
typedef NiceCellBuilder<T> = Widget Function(
  BuildContext context,
  T row,
  NiceCellContext cell,
);

/// Describes one column of a `NiceTable`: how to read a value from a row,
/// how to show it, and how it sorts, searches and exports.
///
/// Everything derives from [value] by default. Give a column a [value] and
/// it is sortable, searchable and exportable with no further code; give it
/// a [cell] builder to render anything you like while keeping that
/// behaviour.
class NiceColumn<T> {
  /// Creates a column.
  ///
  /// [id] must be unique within a table; it keys sort, filters, widths and
  /// visibility in the controller.
  const NiceColumn({
    required this.id,
    required this.label,
    this.value,
    this.text,
    this.subtitle,
    this.cell,
    this.width = const NiceColumnWidth.flex(1),
    NiceAlign? align,
    this.numeric = false,
    this.mono = false,
    bool? sortable,
    this.comparator,
    bool? searchable,
    this.filterOptions,
    this.tooltip,
    this.headerBuilder,
    this.visible = true,
    this.hideable = true,
    this.exportText,
    this.primary = false,
    this.showInCard = true,
    this.style,
  })  : _align = align,
        _sortable = sortable,
        _searchable = searchable;

  /// A plain text column.
  const NiceColumn.text(
    String id,
    String label,
    Object? Function(T row) value, {
    String Function(T row)? subtitle,
    NiceColumnWidth width = const NiceColumnWidth.flex(1),
    NiceAlign? align,
    bool mono = false,
    bool? sortable,
    bool? searchable,
    List<NiceFilterOption>? filterOptions,
    String? tooltip,
    bool visible = true,
    bool hideable = true,
    bool primary = false,
    TextStyle? style,
  }) : this(
          id: id,
          label: label,
          value: value,
          subtitle: subtitle,
          width: width,
          align: align,
          mono: mono,
          sortable: sortable,
          searchable: searchable,
          filterOptions: filterOptions,
          tooltip: tooltip,
          visible: visible,
          hideable: hideable,
          primary: primary,
          style: style,
        );

  /// A right-aligned number column with tabular figures and thousands
  /// separators.
  NiceColumn.number(
    String id,
    String label,
    num? Function(T row) value, {
    int? decimals,
    String prefix = '',
    String suffix = '',
    NiceColumnWidth width = const NiceColumnWidth.flex(1, min: 96),
    NiceAlign align = NiceAlign.end,
    bool? sortable,
    bool searchable = false,
    String? tooltip,
    bool visible = true,
    bool hideable = true,
    TextStyle? style,
  }) : this(
          id: id,
          label: label,
          value: value,
          text: (row) {
            final v = value(row);
            if (v == null) return '';
            return '$prefix${NiceFormat.number(v, decimals: decimals)}$suffix';
          },
          width: width,
          align: align,
          numeric: true,
          sortable: sortable,
          searchable: searchable,
          tooltip: tooltip,
          visible: visible,
          hideable: hideable,
          style: style,
        );

  /// A money column: a [symbol] prefix, two decimals, right-aligned,
  /// tabular figures.
  NiceColumn.money(
    String id,
    String label,
    num? Function(T row) value, {
    String symbol = r'$',
    int decimals = 2,
    NiceColumnWidth width = const NiceColumnWidth.flex(1, min: 112),
    bool? sortable,
    String? tooltip,
    bool visible = true,
    bool hideable = true,
  }) : this.number(
          id,
          label,
          value,
          decimals: decimals,
          prefix: symbol,
          width: width,
          sortable: sortable,
          tooltip: tooltip,
          visible: visible,
          hideable: hideable,
        );

  /// A date/time column, formatted with [format] (defaults to
  /// `yyyy-MM-dd HH:mm`) and sorted chronologically.
  NiceColumn.date(
    String id,
    String label,
    DateTime? Function(T row) value, {
    String Function(DateTime date)? format,
    NiceColumnWidth width = const NiceColumnWidth.flex(1, min: 136),
    NiceAlign? align,
    bool? sortable,
    bool searchable = false,
    String? tooltip,
    bool visible = true,
    bool hideable = true,
    bool mono = true,
  }) : this(
          id: id,
          label: label,
          value: value,
          text: (row) {
            final v = value(row);
            if (v == null) return '';
            return (format ?? NiceFormat.dateTime)(v);
          },
          width: width,
          align: align,
          mono: mono,
          sortable: sortable,
          searchable: searchable,
          tooltip: tooltip,
          visible: visible,
          hideable: hideable,
        );

  /// A status column rendered as a coloured chip.
  ///
  /// [value] returns the label and semantic status for the row. Pass
  /// [filterOptions] (or let the table derive them) to get a filter menu
  /// in the header.
  const NiceColumn.status(
    String id,
    String label,
    NiceStatusValue? Function(T row) value, {
    NiceColumnWidth width = const NiceColumnWidth.flex(1, min: 120),
    NiceAlign? align,
    bool? sortable,
    List<NiceFilterOption>? filterOptions,
    String? tooltip,
    bool visible = true,
    bool hideable = true,
  }) : this(
          id: id,
          label: label,
          value: value,
          width: width,
          align: align,
          sortable: sortable,
          filterOptions: filterOptions,
          tooltip: tooltip,
          visible: visible,
          hideable: hideable,
        );

  /// A yes/no column rendered as a check or a dash.
  const NiceColumn.boolean(
    String id,
    String label,
    bool? Function(T row) value, {
    NiceColumnWidth width = const NiceColumnWidth.fixed(108),
    NiceAlign align = NiceAlign.center,
    bool? sortable,
    String? tooltip,
    bool visible = true,
    bool hideable = true,
  }) : this(
          id: id,
          label: label,
          value: value,
          width: width,
          align: align,
          sortable: sortable,
          searchable: false,
          tooltip: tooltip,
          visible: visible,
          hideable: hideable,
        );

  /// A trailing actions column: not sortable, not searchable, not exported,
  /// fixed width, hidden from the card layout's key/value list.
  NiceColumn.actions(
    String id,
    NiceCellBuilder<T> cell, {
    String label = '',
    double width = 56,
    NiceAlign align = NiceAlign.end,
  }) : this(
          id: id,
          label: label,
          cell: cell,
          width: NiceColumnWidth.fixed(width),
          align: align,
          sortable: false,
          searchable: false,
          hideable: false,
          showInCard: false,
        );

  /// A fully custom cell, with an optional [value] so it still sorts,
  /// searches and exports.
  const NiceColumn.custom(
    String id,
    String label,
    NiceCellBuilder<T> cell, {
    Object? Function(T row)? value,
    NiceColumnWidth width = const NiceColumnWidth.flex(1),
    NiceAlign? align,
    bool? sortable,
    Comparator<T>? comparator,
    bool? searchable,
    List<NiceFilterOption>? filterOptions,
    String? tooltip,
    bool visible = true,
    bool hideable = true,
    bool primary = false,
    bool showInCard = true,
    String Function(T row)? exportText,
  }) : this(
          id: id,
          label: label,
          cell: cell,
          value: value,
          width: width,
          align: align,
          sortable: sortable,
          comparator: comparator,
          searchable: searchable,
          filterOptions: filterOptions,
          tooltip: tooltip,
          visible: visible,
          hideable: hideable,
          primary: primary,
          showInCard: showInCard,
          exportText: exportText,
        );

  /// Unique id used by the controller for sort, filters, widths and
  /// visibility.
  final String id;

  /// Header label.
  final String label;

  /// Reads the raw value for sorting, searching, filtering and export.
  final Object? Function(T row)? value;

  /// Display text. Defaults to a sensible rendering of [value].
  final String Function(T row)? text;

  /// A second, muted line under the text (shown in comfortable and spacious
  /// densities).
  final String Function(T row)? subtitle;

  /// Custom cell builder. When set, [text] and [subtitle] are ignored for
  /// display but [value] still drives behaviour.
  final NiceCellBuilder<T>? cell;

  /// Width policy.
  final NiceColumnWidth width;

  final NiceAlign? _align;

  /// Right-align and use tabular figures.
  final bool numeric;

  /// Render with the theme's monospace style (ids, hashes, timestamps).
  final bool mono;

  final bool? _sortable;

  /// Custom comparator; defaults to comparing [value]s, nulls last.
  final Comparator<T>? comparator;

  final bool? _searchable;

  /// Options for a header filter menu. An empty list (not null) lets the
  /// table derive options from the distinct values in the data.
  final List<NiceFilterOption>? filterOptions;

  /// Header tooltip; defaults to [label] when it is ellipsised.
  final String? tooltip;

  /// Replaces the header label widget.
  final WidgetBuilder? headerBuilder;

  /// Initial visibility.
  final bool visible;

  /// Whether the column picker may hide this column.
  final bool hideable;

  /// Text used by the CSV exporter; defaults to [text] then [value].
  final String Function(T row)? exportText;

  /// Marks the column whose text becomes the title in the card layout.
  final bool primary;

  /// Whether the card layout lists this column.
  final bool showInCard;

  /// Text style override for default cells.
  final TextStyle? style;

  /// Effective alignment: explicit, else end for numeric, else start.
  NiceAlign get align =>
      _align ?? (numeric ? NiceAlign.end : NiceAlign.start);

  /// Whether the header toggles sorting.
  bool get sortable => _sortable ?? (value != null || comparator != null);

  /// Whether free-text search looks at this column.
  bool get searchable => _searchable ?? value != null;

  /// Whether a filter menu is shown in the header.
  bool get filterable => filterOptions != null;

  /// Display text for [row].
  String displayText(T row) {
    if (text != null) return text!(row);
    final v = value?.call(row);
    return switch (v) {
      null => '',
      final num n => NiceFormat.number(n),
      final DateTime d => NiceFormat.dateTime(d),
      final bool b => b ? 'Yes' : 'No',
      _ => v.toString(),
    };
  }

  /// Text used for CSV export: [exportText], else raw numbers and ISO
  /// dates (so spreadsheets parse them), else [text], else [value].
  String exportValue(T row) {
    if (exportText != null) return exportText!(row);
    final v = value?.call(row);
    if (v is num) return v.toString();
    if (v is DateTime) return v.toIso8601String();
    if (text != null) return text!(row);
    return v?.toString() ?? '';
  }

  /// Compares two rows for sorting, ascending.
  int compare(T a, T b) {
    if (comparator != null) return comparator!(a, b);
    final va = value?.call(a);
    final vb = value?.call(b);
    if (va == null && vb == null) return 0;
    if (va == null) return 1;
    if (vb == null) return -1;
    if (va is num && vb is num) return va.compareTo(vb);
    if (va is String && vb is String) {
      return va.toLowerCase().compareTo(vb.toLowerCase());
    }
    if (va is bool && vb is bool) return (va ? 1 : 0) - (vb ? 1 : 0);
    if (va is Comparable<Object?> && vb.runtimeType == va.runtimeType) {
      return va.compareTo(vb);
    }
    return va.toString().compareTo(vb.toString());
  }
}
