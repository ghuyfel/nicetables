import 'package:flutter/material.dart';

import '../controller/nice_table_controller.dart';
import '../model/nice_format.dart';
import '../theme/nice_table_theme.dart';

/// Pagination footer: rows-per-page picker, "1–25 of 1,204" and
/// first/previous/next/last buttons.
class NiceTableFooter<T> extends StatelessWidget {
  /// Creates a footer.
  const NiceTableFooter({
    required this.controller,
    required this.pageSizeOptions,
    this.paged = true,
    this.rowLabel = 'rows',
    super.key,
  });

  /// The table's controller.
  final NiceTableController<T> controller;

  /// Choices for rows per page.
  final List<int> pageSizeOptions;

  /// When false, only the row count is shown.
  final bool paged;

  /// Noun used in "N rows".
  final String rowLabel;

  @override
  Widget build(BuildContext context) {
    final theme = NiceTableTheme.of(context);
    final muted = theme.cellTextStyle.copyWith(
      color: theme.mutedForeground,
      fontSize: 13,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final total = controller.totalRows;
        return Container(
          height: 52,
          padding: EdgeInsets.symmetric(horizontal: theme.horizontalPadding),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: theme.border)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 520;
              if (!paged) {
                return Row(
                  children: [
                    Text('${NiceFormat.number(total)} $rowLabel', style: muted),
                  ],
                );
              }
              final options = {...pageSizeOptions, controller.pageSize}.toList()
                ..sort();
              // Three tiers: full (labels, page text, first/last), medium
              // (no labels), narrow (no first/last, terse range).
              final medium = constraints.maxWidth < 760;
              return Row(
                children: [
                  if (!medium) ...[
                    Text('Rows per page', style: muted),
                    const SizedBox(width: 8),
                  ],
                  _PageSizePicker(
                    value: controller.pageSize,
                    options: options,
                    onChanged: controller.setPageSize,
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      narrow && total > 0
                          ? '${NiceFormat.number(controller.firstRowNumber)}–'
                              '${NiceFormat.number(controller.lastRowNumber)}'
                              ' / ${NiceFormat.number(total)}'
                          : total == 0
                              ? '0 $rowLabel'
                              : '${NiceFormat.number(controller.firstRowNumber)}–'
                                  '${NiceFormat.number(controller.lastRowNumber)}'
                                  ' of ${NiceFormat.number(total)}',
                      style: muted,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!narrow)
                    _PageButton(
                      icon: Icons.first_page_rounded,
                      tooltip: 'First page',
                      onPressed: controller.hasPreviousPage
                          ? controller.firstPage
                          : null,
                    ),
                  _PageButton(
                    icon: Icons.chevron_left_rounded,
                    tooltip: 'Previous page',
                    onPressed: controller.hasPreviousPage
                        ? controller.previousPage
                        : null,
                  ),
                  if (!medium)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Page ${controller.page + 1} of ${controller.pageCount}',
                        style: muted,
                      ),
                    ),
                  _PageButton(
                    icon: Icons.chevron_right_rounded,
                    tooltip: 'Next page',
                    onPressed:
                        controller.hasNextPage ? controller.nextPage : null,
                  ),
                  if (!narrow)
                    _PageButton(
                      icon: Icons.last_page_rounded,
                      tooltip: 'Last page',
                      onPressed:
                          controller.hasNextPage ? controller.lastPage : null,
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = NiceTableTheme.of(context);
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      iconSize: 20,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 34, height: 34),
      visualDensity: VisualDensity.compact,
      color: theme.foreground,
      disabledColor: theme.mutedForeground.withValues(alpha: 0.35),
      icon: Icon(icon),
    );
  }
}

class _PageSizePicker extends StatelessWidget {
  const _PageSizePicker({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final int value;
  final List<int> options;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = NiceTableTheme.of(context);
    return Semantics(
      label: 'Rows per page',
      child: MenuAnchor(
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
              onPressed: () => onChanged(o),
              leadingIcon: Icon(
                o == value ? Icons.check_rounded : null,
                size: 16,
                color: theme.accent,
              ),
              child: Text('$o', style: theme.cellTextStyle),
            ),
        ],
        builder: (context, menu, _) => InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => menu.isOpen ? menu.close() : menu.open(),
          child: Container(
            height: 32,
            padding: const EdgeInsets.only(left: 10, right: 6),
            decoration: BoxDecoration(
              border: Border.all(color: theme.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$value',
                  style: theme.cellTextStyle.copyWith(
                    fontSize: 13,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 20,
                  color: theme.mutedForeground,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
