import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controller/nice_table_controller.dart';
import '../model/nice_table_strings.dart';
import '../theme/nice_table_theme.dart';

/// The page buttons to show for [pageCount] pages when [page] (1-based) is
/// current: page numbers, with `null` where an ellipsis goes.
///
/// The first and last [boundary] pages and [siblings] pages either side of
/// the current one are always shown, and the window keeps the same size
/// near the edges, so the row of buttons never changes width while paging.
/// For example `1 … 4 5 [6] 7 8 … 20`.
List<int?> nicePaginationItems(
  int pageCount,
  int page, {
  int siblings = 1,
  int boundary = 1,
}) {
  final count = math.max(pageCount, 1);
  final current = page.clamp(1, count);
  final visible = 2 * boundary + 2 * siblings + 3;
  if (count <= visible) return [for (var i = 1; i <= count; i++) i];

  final startPages = [for (var i = 1; i <= boundary; i++) i];
  final endPages = [for (var i = count - boundary + 1; i <= count; i++) i];

  final siblingsStart = math.max(
    math.min(current - siblings, count - boundary - siblings * 2 - 1),
    boundary + 2,
  );
  final siblingsEnd = math.min(
    math.max(current + siblings, boundary + siblings * 2 + 2),
    endPages.first - 2,
  );

  return [
    ...startPages,
    if (siblingsStart > boundary + 2)
      null
    else if (boundary + 1 < count - boundary)
      boundary + 1,
    for (var i = siblingsStart; i <= siblingsEnd; i++) i,
    if (siblingsEnd < count - boundary - 1)
      null
    else if (count - boundary > boundary)
      count - boundary,
    ...endPages,
  ];
}

/// Pagination footer: rows-per-page picker, row range and selection count,
/// numbered page buttons with the current page highlighted, first /
/// previous / next / last, and a "go to page" field on long tables.
///
/// Adapts to its width: full above 880 px, numbered pages without labels
/// above 560 px, and previous / "6 of 10" / next below that.
class NiceTableFooter<T> extends StatelessWidget {
  /// Creates a footer.
  const NiceTableFooter({
    required this.controller,
    required this.pageSizeOptions,
    this.paged = true,
    this.rowLabel = 'rows',
    this.siblingCount = 1,
    this.showPageJump = true,
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

  /// Page buttons either side of the current page (at full width).
  final int siblingCount;

  /// Whether to show the "go to page" field when pages are elided.
  final bool showPageJump;

  @override
  Widget build(BuildContext context) {
    final strings = NiceTableStrings.of(context);
    final theme = NiceTableTheme.of(context);
    // Footer type is one step smaller and lighter than cell text, with a
    // unit line height so every label centres on the 32 px controls.
    final muted = theme.cellTextStyle.copyWith(
      color: theme.mutedForeground,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final total = controller.totalRows;
        final selected = controller.selectedCount;
        return Container(
          height: 52,
          padding: EdgeInsets.symmetric(horizontal: theme.horizontalPadding),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: theme.border)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final narrow = w < 560;
              final medium = w < 880;

              if (!paged) {
                return Row(
                  children: [
                    Text(
                      strings.rowCount(total, rowLabel) +
                          (selected > 0
                              ? ', ${strings.selectedCount(selected)}'
                              : ''),
                      style: muted,
                    ),
                  ],
                );
              }

              final options = {...pageSizeOptions, controller.pageSize}.toList()
                ..sort();
              final range = total == 0
                  ? strings.rowCount(0, rowLabel)
                  : strings.rowRange(
                      controller.firstRowNumber,
                      controller.lastRowNumber,
                      total,
                      w < 1000 ? '' : rowLabel,
                    );
              final selection = selected > 0 && !narrow
                  ? ', ${strings.selectedCount(selected)}'
                  : '';

              return Row(
                children: [
                  if (!medium) ...[
                    Text(strings.rowsPerPage, style: muted),
                    const SizedBox(width: 8),
                  ],
                  _PageSizePicker(
                    value: controller.pageSize,
                    options: options,
                    onChanged: controller.setPageSize,
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text(
                      '$range$selection',
                      style: muted,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Spacer(),
                  if (narrow)
                    _CompactPager<T>(controller: controller, style: muted)
                  else
                    _Pager<T>(
                      controller: controller,
                      siblings: medium ? 0 : siblingCount,
                      showEnds: !medium,
                      showJump: showPageJump && !medium,
                      style: muted,
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

/// Previous, "6 of 10", next.
class _CompactPager<T> extends StatelessWidget {
  const _CompactPager({required this.controller, required this.style});

  final NiceTableController<T> controller;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NavButton(
            icon: Icons.chevron_left_rounded,
            tooltip: NiceTableStrings.of(context).previousPage,
            onPressed:
                controller.hasPreviousPage ? controller.previousPage : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              NiceTableStrings.of(context)
                  .pageOfCount(controller.page + 1, controller.pageCount),
              style: style,
            ),
          ),
          _NavButton(
            icon: Icons.chevron_right_rounded,
            tooltip: NiceTableStrings.of(context).nextPage,
            onPressed: controller.hasNextPage ? controller.nextPage : null,
          ),
        ],
      );
}

/// First, previous, numbered pages with ellipses, next, last, and the
/// optional jump field.
class _Pager<T> extends StatelessWidget {
  const _Pager({
    required this.controller,
    required this.siblings,
    required this.showEnds,
    required this.showJump,
    required this.style,
  });

  final NiceTableController<T> controller;
  final int siblings;
  final bool showEnds;
  final bool showJump;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final strings = NiceTableStrings.of(context);
    final theme = NiceTableTheme.of(context);
    final count = controller.pageCount;
    final current = controller.page + 1;
    final items = nicePaginationItems(count, current, siblings: siblings);
    final elided = items.contains(null);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showEnds)
          _NavButton(
            icon: Icons.first_page_rounded,
            tooltip: strings.firstPage,
            onPressed: controller.hasPreviousPage ? controller.firstPage : null,
          ),
        _NavButton(
          icon: Icons.chevron_left_rounded,
          tooltip: strings.previousPage,
          onPressed:
              controller.hasPreviousPage ? controller.previousPage : null,
        ),
        const SizedBox(width: 4),
        for (final item in items)
          item == null
              ? SizedBox(
                  width: 24,
                  child: Center(
                    child: Text(
                      '…',
                      style: style.copyWith(
                        color: theme.mutedForeground.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                )
              : _PageButton(
                  page: item,
                  current: item == current,
                  onPressed: () => controller.goToPage(item - 1),
                ),
        const SizedBox(width: 4),
        _NavButton(
          icon: Icons.chevron_right_rounded,
          tooltip: strings.nextPage,
          onPressed: controller.hasNextPage ? controller.nextPage : null,
        ),
        if (showEnds)
          _NavButton(
            icon: Icons.last_page_rounded,
            tooltip: strings.lastPage,
            onPressed: controller.hasNextPage ? controller.lastPage : null,
          ),
        if (showJump && elided) ...[
          const SizedBox(width: 12),
          _PageJump<T>(controller: controller, style: style),
        ],
      ],
    );
  }
}

/// A numbered page button; the current page is a filled accent pill.
class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.page,
    required this.current,
    required this.onPressed,
  });

  final int page;
  final bool current;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = NiceTableTheme.of(context);
    final label = '$page';
    final width = math.max(32.0, 16.0 + label.length * 8.0);
    // One semantics node per button, so screen readers hear "Page 3"
    // rather than the bare digit.
    return Semantics(
      button: true,
      selected: current,
      label: current ? 'Page $page, current page' : 'Page $page',
      onTap: current ? null : onPressed,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: current ? theme.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            hoverColor: current ? Colors.transparent : theme.hover,
            onTap: current ? null : onPressed,
            child: AnimatedContainer(
              duration: theme.hoverDuration,
              width: width,
              height: 32,
              alignment: Alignment.center,
              child: Text(
                label,
                style: theme.cellTextStyle.copyWith(
                  fontSize: 12,
                  height: 1,
                  fontWeight: current ? FontWeight.w600 : FontWeight.w400,
                  color: current ? theme.onAccent : theme.foreground,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
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
      style: IconButton.styleFrom(
        minimumSize: const Size(32, 32),
        fixedSize: const Size(32, 32),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        foregroundColor: theme.foreground,
        disabledForegroundColor: theme.mutedForeground.withValues(alpha: 0.35),
        hoverColor: theme.hover,
      ),
      icon: Icon(icon),
    );
  }
}

/// "Go to" field: type a page number and press Enter.
class _PageJump<T> extends StatefulWidget {
  const _PageJump({required this.controller, required this.style});

  final NiceTableController<T> controller;
  final TextStyle style;

  @override
  State<_PageJump<T>> createState() => _PageJumpState<T>();
}

class _PageJumpState<T> extends State<_PageJump<T>> {
  final _text = TextEditingController();
  final _focus = FocusNode(debugLabel: 'Go to page');

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() => setState(() {});

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocus)
      ..dispose();
    _text.dispose();
    super.dispose();
  }

  void _submit(String value) {
    final page = int.tryParse(value.trim());
    if (page != null) {
      widget.controller.goToPage(page - 1);
    }
    _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    final strings = NiceTableStrings.of(context);
    final theme = NiceTableTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(strings.goTo, style: widget.style),
        const SizedBox(width: 6),
        // The box is drawn here and the bare field is centred inside it:
        // an input decorator sizes itself to its text, so it cannot fill
        // and centre within a fixed-height box.
        AnimatedContainer(
          duration: theme.hoverDuration,
          width: 60,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _focus.hasFocus ? theme.accent : theme.border,
              width: _focus.hasFocus ? 1.5 : 1,
            ),
          ),
          child: Semantics(
            label: strings.goToPage,
            textField: true,
            child: TextField(
              controller: _text,
              focusNode: _focus,
              onSubmitted: _submit,
              textAlign: TextAlign.center,
              textInputAction: TextInputAction.go,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              cursorHeight: 14,
              style: widget.style.copyWith(
                color: theme.foreground,
                height: 1.2,
              ),
              // Every border slot is set: the app's InputDecorationTheme
              // may draw an outline for the slots `collapsed` leaves null,
              // which would sit inside the box drawn above.
              decoration: InputDecoration.collapsed(
                hintText: '${widget.controller.page + 1}',
                hintStyle: widget.style.copyWith(
                  color: theme.mutedForeground.withValues(alpha: 0.5),
                  height: 1.2,
                ),
              ).copyWith(
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Rows-per-page dropdown.
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
    final strings = NiceTableStrings.of(context);
    final theme = NiceTableTheme.of(context);
    return Semantics(
      label: strings.rowsPerPage,
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
                    fontSize: 12,
                    height: 1,
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
