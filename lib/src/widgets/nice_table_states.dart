import 'package:flutter/material.dart';

import '../model/nice_density.dart';
import '../model/nice_table_strings.dart';
import '../theme/nice_table_theme.dart';

/// Shown when a table has no rows to display.
class NiceEmptyState extends StatelessWidget {
  /// Creates an empty state.
  const NiceEmptyState({
    this.icon = Icons.inbox_outlined,
    this.title,
    this.message,
    this.action,
    super.key,
  });

  /// Leading icon.
  final IconData icon;

  /// Short headline; defaults to [NiceTableStrings.emptyTitle].
  final String? title;

  /// Optional supporting sentence.
  final String? message;

  /// Optional button, e.g. "Clear filters" or "Create".
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = NiceTableTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.skeleton,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 26, color: theme.mutedForeground),
            ),
            const SizedBox(height: 16),
            Text(
              title ?? NiceTableStrings.of(context).emptyTitle,
              textAlign: TextAlign.center,
              style: theme.cellTextStyle.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.foreground,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: theme.subtitleTextStyle.copyWith(fontSize: 13),
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Shown when loading failed.
class NiceErrorState extends StatelessWidget {
  /// Creates an error state.
  const NiceErrorState({
    required this.message,
    this.title,
    this.onRetry,
    super.key,
  });

  /// Headline; defaults to [NiceTableStrings.errorTitle].
  final String? title;

  /// What went wrong, in user terms.
  final String message;

  /// Shows a Retry button when set.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = NiceTableTheme.of(context);
    final strings = NiceTableStrings.of(context);
    return NiceEmptyState(
      icon: Icons.error_outline_rounded,
      title: title ?? strings.errorTitle,
      message: message,
      action: onRetry == null
          ? null
          : FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(strings.retry),
              style: FilledButton.styleFrom(
                foregroundColor: theme.statusPalette.error.foreground,
                backgroundColor: theme.statusPalette.error.background,
              ),
            ),
    );
  }
}

/// Pulsing placeholder rows shown while the first page loads.
class NiceSkeletonRows extends StatefulWidget {
  /// Creates skeleton rows.
  const NiceSkeletonRows({
    required this.columnWidths,
    required this.leadingWidth,
    required this.density,
    this.rowCount = 6,
    super.key,
  });

  /// Widths of the visible columns.
  final List<double> columnWidths;

  /// Width of the leading gutter.
  final double leadingWidth;

  /// Row density.
  final NiceDensity density;

  /// Number of placeholder rows.
  final int rowCount;

  @override
  State<NiceSkeletonRows> createState() => _NiceSkeletonRowsState();
}

class _NiceSkeletonRowsState extends State<NiceSkeletonRows>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = NiceTableTheme.of(context);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Semantics(
      label: NiceTableStrings.of(context).loading,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final alpha = reduceMotion ? 0.7 : 0.45 + 0.55 * _pulse.value;
          final color = theme.skeleton.withValues(
            alpha: theme.skeleton.a * alpha,
          );
          return Column(
            children: [
              for (var r = 0; r < widget.rowCount; r++)
                SizedBox(
                  height: widget.density.rowHeight,
                  child: Row(
                    children: [
                      SizedBox(
                        width: theme.horizontalPadding + widget.leadingWidth,
                      ),
                      for (var c = 0; c < widget.columnWidths.length; c++)
                        SizedBox(
                          width: widget.columnWidths[c],
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: theme.cellPadding,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: _factor(r, c),
                                child: Container(
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  double _factor(int row, int col) {
    const pattern = [0.72, 0.48, 0.6, 0.36, 0.8, 0.52];
    return pattern[(row * 3 + col * 5) % pattern.length];
  }
}
