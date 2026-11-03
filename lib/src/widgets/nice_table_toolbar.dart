import 'dart:async';

import 'package:flutter/material.dart';

import '../controller/nice_table_controller.dart';
import '../model/nice_column.dart';
import '../model/nice_density.dart';
import '../model/nice_format.dart';
import '../theme/nice_table_theme.dart';

/// Builds bulk action widgets for the current selection.
typedef NiceBulkActionsBuilder<T> = List<Widget> Function(
  BuildContext context,
  List<T> selectedRows,
);

/// The strip above the rows: title and count, search, actions, column
/// picker, density toggle, export and refresh, with an active-filter chip
/// row and a bulk-action bar that replaces the title while rows are
/// selected.
class NiceTableToolbar<T> extends StatefulWidget {
  /// Creates a toolbar.
  const NiceTableToolbar({
    required this.controller,
    required this.columns,
    required this.theme,
    required this.totalRows,
    required this.selectedRows,
    required this.pageKeys,
    required this.allMatchingKeys,
    this.title,
    this.subtitle,
    this.titleWidget,
    this.showSearch = true,
    this.searchHint = 'Search',
    this.actions = const [],
    this.showColumnPicker = true,
    this.showDensityToggle = false,
    this.onExport,
    this.onRefresh,
    this.bulkActions,
    this.loading = false,
    this.rowLabel = 'rows',
    super.key,
  });

  /// The table controller.
  final NiceTableController<T> controller;

  /// Every column, for the column picker.
  final List<NiceColumn<T>> columns;

  /// Resolved theme.
  final NiceTableTheme theme;

  /// Rows matching the current criteria.
  final int totalRows;

  /// Currently selected rows (that are known to the table).
  final List<T> selectedRows;

  /// Keys of the rows on this page.
  final List<Object> pageKeys;

  /// Keys of every matching row, when known (client mode), for
  /// "Select all N".
  final List<Object>? allMatchingKeys;

  /// Title text.
  final String? title;

  /// Subtitle; defaults to the row count.
  final String? subtitle;

  /// Replaces the title and subtitle.
  final Widget? titleWidget;

  /// Whether to show the search field.
  final bool showSearch;

  /// Placeholder for the search field.
  final String searchHint;

  /// Trailing widgets (buttons).
  final List<Widget> actions;

  /// Whether to show the column visibility menu.
  final bool showColumnPicker;

  /// Whether to show the density menu.
  final bool showDensityToggle;

  /// Shows an export button when set.
  final VoidCallback? onExport;

  /// Shows a refresh button when set.
  final VoidCallback? onRefresh;

  /// Builds buttons for the bulk bar.
  final NiceBulkActionsBuilder<T>? bulkActions;

  /// Spins the refresh icon.
  final bool loading;

  /// Noun for counts.
  final String rowLabel;

  @override
  State<NiceTableToolbar<T>> createState() => _NiceTableToolbarState<T>();
}

class _NiceTableToolbarState<T> extends State<NiceTableToolbar<T>> {
  late final TextEditingController _search =
      TextEditingController(text: widget.controller.search);
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncSearch);
  }

  @override
  void didUpdateWidget(covariant NiceTableToolbar<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncSearch);
      widget.controller.addListener(_syncSearch);
      _syncSearch();
    }
  }

  void _syncSearch() {
    if (!mounted) return;
    final s = widget.controller.search;
    if (_search.text.trim() != s) {
      _search.text = s;
    }
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () {
      widget.controller.setSearch(text);
    });
    setState(() {});
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_syncSearch);
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final c = widget.controller;
    final selecting = c.hasSelection && widget.selectedRows.isNotEmpty;
    final filters = c.filters;

    return Container(
      padding: EdgeInsets.fromLTRB(
        theme.horizontalPadding,
        12,
        theme.horizontalPadding,
        12,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 640;
              final leading = selecting ? _bulkBar(context) : _titleBlock();
              final trailing = _trailing(narrow);
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    leading,
                    if (trailing.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(children: trailing),
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: leading),
                  const SizedBox(width: 12),
                  ...trailing,
                ],
              );
            },
          ),
          if (filters.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final entry in filters.entries)
                  InputChip(
                    label: Text(entry.value.label),
                    labelStyle: theme.cellTextStyle.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.accent,
                    ),
                    deleteIconColor: theme.accent,
                    backgroundColor: theme.selected,
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onDeleted: () => c.removeFilter(entry.key),
                    deleteButtonTooltipMessage: 'Remove filter',
                  ),
                TextButton(
                  onPressed: c.clearFilters,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.mutedForeground,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Clear all'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _titleBlock() {
    final theme = widget.theme;
    if (widget.titleWidget != null) return widget.titleWidget!;
    if (widget.title == null && widget.subtitle == null) {
      return const SizedBox.shrink();
    }
    final subtitle = widget.subtitle ??
        '${NiceFormat.number(widget.totalRows)} ${widget.rowLabel}';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null)
          Text(
            widget.title!,
            style: theme.cellTextStyle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.foreground,
              height: 1.25,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        Text(
          subtitle,
          style: theme.subtitleTextStyle.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _bulkBar(BuildContext context) {
    final theme = widget.theme;
    final c = widget.controller;
    final count = c.selectedCount;
    final all = widget.allMatchingKeys;
    final pageFullySelected =
        widget.pageKeys.isNotEmpty && widget.pageKeys.every(c.isSelected);
    final canSelectAll = all != null &&
        pageFullySelected &&
        all.length > count &&
        all.length > widget.pageKeys.length;
    final actions = widget.bulkActions?.call(context, widget.selectedRows) ??
        const <Widget>[];
    return Container(
      height: 40,
      padding: const EdgeInsets.only(left: 4, right: 4),
      decoration: BoxDecoration(
        color: theme.selected,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Clear selection',
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            color: theme.accent,
            onPressed: c.clearSelection,
            icon: const Icon(Icons.close_rounded),
          ),
          Text(
            '${NiceFormat.number(count)} selected',
            style: theme.cellTextStyle.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (canSelectAll) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => c.selectAll(all),
              style: TextButton.styleFrom(
                foregroundColor: theme.accent,
                visualDensity: VisualDensity.compact,
              ),
              child: Text('Select all ${NiceFormat.number(all.length)}'),
            ),
          ],
          const Spacer(),
          for (final a in actions)
            Padding(padding: const EdgeInsets.only(left: 4), child: a),
        ],
      ),
    );
  }

  List<Widget> _trailing(bool narrow) {
    final theme = widget.theme;
    final c = widget.controller;
    final items = <Widget>[];

    if (widget.showSearch) {
      items.add(
        narrow
            ? Expanded(child: _searchField())
            : ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280, minWidth: 180),
                child: _searchField(),
              ),
      );
    }
    for (final a in widget.actions) {
      items
        ..add(const SizedBox(width: 8))
        ..add(a);
    }

    final iconColor = theme.mutedForeground;
    if (widget.showColumnPicker &&
        widget.columns.any((col) => col.hideable)) {
      items
        ..add(const SizedBox(width: 4))
        ..add(
          MenuAnchor(
            style: _menuStyle(theme),
            menuChildren: [
              for (final col in widget.columns.where((col) => col.hideable))
                MenuItemButton(
                  closeOnActivate: false,
                  onPressed: () => c.toggleColumn(col),
                  leadingIcon: Icon(
                    c.isColumnVisible(col)
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    size: 18,
                    color: c.isColumnVisible(col) ? theme.accent : iconColor,
                  ),
                  child: Text(col.label, style: theme.cellTextStyle),
                ),
            ],
            builder: (context, menu, _) => IconButton(
              tooltip: 'Columns',
              color: iconColor,
              onPressed: () => menu.isOpen ? menu.close() : menu.open(),
              icon: const Icon(Icons.view_column_outlined, size: 20),
            ),
          ),
        );
    }

    if (widget.showDensityToggle) {
      final current = c.density ?? theme.density;
      items.add(
        MenuAnchor(
          style: _menuStyle(theme),
          menuChildren: [
            for (final d in NiceDensity.values)
              MenuItemButton(
                onPressed: () => c.setDensity(d),
                leadingIcon: Icon(
                  d == current ? Icons.check_rounded : null,
                  size: 16,
                  color: theme.accent,
                ),
                child: Text(
                  '${d.name[0].toUpperCase()}${d.name.substring(1)}',
                  style: theme.cellTextStyle,
                ),
              ),
          ],
          builder: (context, menu, _) => IconButton(
            tooltip: 'Density',
            color: iconColor,
            onPressed: () => menu.isOpen ? menu.close() : menu.open(),
            icon: const Icon(Icons.density_medium_rounded, size: 20),
          ),
        ),
      );
    }

    if (widget.onExport != null) {
      items.add(
        IconButton(
          tooltip: 'Export CSV',
          color: iconColor,
          onPressed: widget.onExport,
          icon: const Icon(Icons.download_outlined, size: 20),
        ),
      );
    }

    if (widget.onRefresh != null) {
      items.add(
        IconButton(
          tooltip: 'Refresh',
          color: iconColor,
          onPressed: widget.loading ? null : widget.onRefresh,
          icon: widget.loading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.accent,
                  ),
                )
              : const Icon(Icons.refresh_rounded, size: 20),
        ),
      );
    }
    return items;
  }

  MenuStyle _menuStyle(NiceTableTheme theme) => MenuStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: theme.border),
          ),
        ),
      );

  Widget _searchField() {
    final theme = widget.theme;
    return SizedBox(
      height: 36,
      child: TextField(
        controller: _search,
        onChanged: _onSearchChanged,
        style: theme.cellTextStyle,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: widget.searchHint,
          hintStyle: theme.cellTextStyle.copyWith(color: theme.mutedForeground),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18,
            color: theme.mutedForeground,
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 36, minHeight: 36),
          suffixIcon: _search.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  iconSize: 16,
                  color: theme.mutedForeground,
                  onPressed: () {
                    _search.clear();
                    _debounce?.cancel();
                    widget.controller.setSearch('');
                    setState(() {});
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
          suffixIconConstraints:
              const BoxConstraints(minWidth: 32, minHeight: 32),
          isDense: true,
          filled: true,
          fillColor: theme.headerBackground,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.accent, width: 1.5),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.border),
          ),
        ),
      ),
    );
  }
}
