import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../cells/nice_cells.dart';
import '../model/nice_column.dart';
import '../model/nice_density.dart';
import '../theme/nice_table_theme.dart';
import 'nice_default_cell.dart';
import 'nice_horizontal_scroll.dart';
import 'nice_layout.dart';
import 'nice_table_header.dart';

/// Per-row colour overrides returned by `NiceTable.rowStyle`.
class NiceRowStyle {
  /// Creates a row style.
  const NiceRowStyle({this.background, this.foreground, this.textStyle});

  /// Background colour (blended under hover and selection tints).
  final Color? background;

  /// Default text colour.
  final Color? foreground;

  /// Default text style merged over the theme's cell style.
  final TextStyle? textStyle;
}

/// Whether and how rows can be selected.
enum NiceSelectionMode {
  /// No selection.
  none,

  /// Exactly one row at a time; tapping a row selects it.
  single,

  /// Any number of rows via a checkbox column, shift-click ranges and
  /// ctrl/cmd-click toggles.
  multi,
}

/// One data row: hover, selection and focus visuals, the checkbox and
/// expander gutter, pinned cells and the shifted scrolling cells.
class NiceTableRow<T> extends StatefulWidget {
  /// Creates a row.
  const NiceTableRow({
    required this.row,
    required this.index,
    required this.columns,
    required this.layout,
    required this.theme,
    required this.density,
    required this.offset,
    required this.selectionMode,
    required this.selected,
    required this.focused,
    required this.expandable,
    required this.expanded,
    required this.onTap,
    required this.onDoubleTap,
    required this.onSecondaryTap,
    required this.onCheckbox,
    required this.onToggleExpand,
    required this.onHover,
    this.style,
    this.dimmed = false,
    super.key,
  });

  /// The row's data.
  final T row;

  /// Index within the page.
  final int index;

  /// Visible columns.
  final List<NiceColumn<T>> columns;

  /// Resolved widths.
  final NiceColumnLayout layout;

  /// Resolved theme.
  final NiceTableTheme theme;

  /// Row density.
  final NiceDensity density;

  /// Horizontal scroll offset.
  final ViewportOffset offset;

  /// Selection mode of the table.
  final NiceSelectionMode selectionMode;

  /// Whether this row is selected.
  final bool selected;

  /// Whether this row has keyboard focus.
  final bool focused;

  /// Whether the table has an expander gutter.
  final bool expandable;

  /// Whether this row's detail panel is open.
  final bool expanded;

  /// Row tap (receives the index; the table resolves modifiers).
  final VoidCallback? onTap;

  /// Row double tap.
  final VoidCallback? onDoubleTap;

  /// Right click / long press with the global position.
  final void Function(Offset globalPosition)? onSecondaryTap;

  /// Checkbox tap.
  final VoidCallback? onCheckbox;

  /// Expander tap.
  final VoidCallback? onToggleExpand;

  /// Pointer entered or left the row.
  final ValueChanged<bool>? onHover;

  /// Optional per-row overrides.
  final NiceRowStyle? style;

  /// Fade the row while a refresh is in flight.
  final bool dimmed;

  @override
  State<NiceTableRow<T>> createState() => _NiceTableRowState<T>();
}

class _NiceTableRowState<T> extends State<NiceTableRow<T>> {
  bool _hover = false;

  Color _background() {
    final theme = widget.theme;
    final base = widget.style?.background ??
        (theme.showStripes && widget.index.isOdd ? theme.stripe : null);
    Color? tint;
    if (widget.selected) {
      tint = _hover ? theme.selectedHover : theme.selected;
    } else if (_hover) {
      tint = theme.hover;
    }
    if (base == null && tint == null) return Colors.transparent;
    if (base == null) return tint!;
    if (tint == null) return base;
    return Color.alphaBlend(tint, base);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final layout = widget.layout;
    final pinned = layout.pinnedCount;
    final cellContext = NiceCellContext(
      rowIndex: widget.index,
      selected: widget.selected,
      hovered: _hover,
      focused: widget.focused,
      expanded: widget.expanded,
    );

    final cells = <Widget>[
      for (var i = 0; i < widget.columns.length; i++)
        SizedBox(
          width: layout.widths[i],
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: theme.cellPadding),
            child: buildNiceCellContent<T>(
              context,
              widget.columns[i],
              widget.row,
              cellContext,
              theme,
              widget.density,
            ),
          ),
        ),
    ];

    final gutter = SizedBox(
      width: layout.leadingWidth,
      child: Row(
        children: [
          if (widget.selectionMode == NiceSelectionMode.multi)
            SizedBox(
              width: 48,
              child: Center(
                child: Checkbox(
                  value: widget.selected,
                  activeColor: theme.accent,
                  checkColor: theme.onAccent,
                  side: BorderSide(color: theme.mutedForeground, width: 1.5),
                  // 32 px: fits every density, including 40 px compact rows.
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  semanticLabel: 'Select row ${widget.index + 1}',
                  onChanged: widget.onCheckbox == null
                      ? null
                      : (_) => widget.onCheckbox!(),
                ),
              ),
            ),
          if (widget.expandable)
            SizedBox(
              width: 40,
              child: Center(
                child: IconButton(
                  tooltip: widget.expanded ? 'Collapse' : 'Expand',
                  iconSize: 20,
                  style: niceSmallIconButtonStyle,
                  color: theme.mutedForeground,
                  onPressed: widget.onToggleExpand,
                  icon: AnimatedRotation(
                    duration: const Duration(milliseconds: 180),
                    turns: widget.expanded ? 0.25 : 0,
                    child: const Icon(Icons.chevron_right_rounded),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    final textStyle = theme.cellTextStyle
        .merge(widget.style?.textStyle)
        .copyWith(color: widget.style?.foreground);

    Widget content = Row(
      children: [
        SizedBox(width: theme.horizontalPadding),
        gutter,
        ...cells.take(pinned),
        if (pinned > 0) nicePinnedEdge(widget.offset, theme),
        Expanded(
          child: NiceHorizontalShift(
            offset: widget.offset,
            contentWidth: layout.scrollingWidth,
            child: Row(children: cells.skip(pinned).toList()),
          ),
        ),
        SizedBox(width: theme.horizontalPadding),
      ],
    );

    content = DefaultTextStyle.merge(style: textStyle, child: content);

    final interactive = widget.onTap != null ||
        widget.onDoubleTap != null ||
        widget.onSecondaryTap != null;

    return Semantics(
      selected: widget.selected,
      child: MouseRegion(
        cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) {
          setState(() => _hover = true);
          widget.onHover?.call(true);
        },
        onExit: (_) {
          setState(() => _hover = false);
          widget.onHover?.call(false);
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onDoubleTap: widget.onDoubleTap,
          onSecondaryTapUp: widget.onSecondaryTap == null
              ? null
              : (d) => widget.onSecondaryTap!(d.globalPosition),
          onLongPressStart: widget.onSecondaryTap == null
              ? null
              : (d) => widget.onSecondaryTap!(d.globalPosition),
          child: AnimatedOpacity(
            duration: theme.hoverDuration,
            opacity: widget.dimmed ? 0.55 : 1,
            child: AnimatedContainer(
              duration: theme.hoverDuration,
              height: widget.density.rowHeight,
              decoration: BoxDecoration(
                color: _background(),
                border: Border(
                  bottom: BorderSide(
                    color: theme.showRowDividers
                        ? theme.divider
                        : Colors.transparent,
                  ),
                  left: BorderSide(
                    color:
                        widget.focused ? theme.focusRing : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
