import 'package:flutter/material.dart';

import '../cells/nice_cells.dart';
import '../model/nice_column.dart';
import '../model/nice_density.dart';
import '../model/nice_status.dart';
import '../theme/nice_table_theme.dart';

/// Builds the content of a cell for [column] and [row].
///
/// Custom [NiceColumn.cell] builders win; otherwise status values become
/// chips, booleans become icons, and everything else is text (with an
/// optional subtitle outside compact density).
Widget buildNiceCellContent<T>(
  BuildContext context,
  NiceColumn<T> column,
  T row,
  NiceCellContext cell,
  NiceTableTheme theme,
  NiceDensity density,
) {
  if (column.cell != null) return column.cell!(context, row, cell);

  final value = column.value?.call(row);
  if (value is NiceStatusValue) {
    return Align(
      alignment: column.align.alignment,
      child: NiceStatusChip.fromValue(
        value,
        compact: density == NiceDensity.compact,
      ),
    );
  }
  if (value is bool) {
    return Align(
      alignment: column.align.alignment,
      child: Icon(
        value ? Icons.check_rounded : Icons.remove_rounded,
        size: 18,
        color: value
            ? theme.statusPalette.success.foreground
            : theme.mutedForeground.withValues(alpha: 0.5),
        semanticLabel: value ? 'Yes' : 'No',
      ),
    );
  }

  final text = column.displayText(row);
  var style = column.mono ? theme.monoTextStyle : theme.cellTextStyle;
  if (column.numeric) {
    style = style.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
  if (column.style != null) style = style.merge(column.style);

  Widget content = Text(
    text,
    style: style,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    softWrap: false,
    textAlign: column.align.textAlign,
  );

  final subtitle =
      density == NiceDensity.compact ? null : column.subtitle?.call(row);
  if (subtitle != null && subtitle.isNotEmpty) {
    content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: switch (column.align) {
        NiceAlign.start => CrossAxisAlignment.start,
        NiceAlign.center => CrossAxisAlignment.center,
        NiceAlign.end => CrossAxisAlignment.end,
      },
      children: [
        content,
        Text(
          subtitle,
          style: theme.subtitleTextStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          textAlign: column.align.textAlign,
        ),
      ],
    );
  }
  return Align(alignment: column.align.alignment, child: content);
}
