import '../model/nice_column.dart';

/// Resolved widths for the visible columns of a table.
class NiceColumnLayout {
  /// Creates a layout.
  const NiceColumnLayout({
    required this.widths,
    required this.pinnedCount,
    required this.leadingWidth,
  });

  /// Width of each visible column, in order.
  final List<double> widths;

  /// How many leading columns are pinned.
  final int pinnedCount;

  /// Width of the selection and expansion gutter before the first column.
  final double leadingWidth;

  /// Width of the pinned block (gutter plus pinned columns).
  double get pinnedWidth {
    var w = leadingWidth;
    for (var i = 0; i < pinnedCount && i < widths.length; i++) {
      w += widths[i];
    }
    return w;
  }

  /// Width of the scrolling block (the columns after the pinned ones).
  double get scrollingWidth {
    var w = 0.0;
    for (var i = pinnedCount; i < widths.length; i++) {
      w += widths[i];
    }
    return w;
  }

  /// Total width of every column plus the gutter.
  double get totalWidth => pinnedWidth + scrollingWidth;

  /// Distributes [available] px over [columns].
  ///
  /// Fixed columns and user [overrides] take their width; the remainder is
  /// shared by flex columns proportionally, with each clamped to its
  /// bounds and the slack redistributed over the columns that were not
  /// clamped. When minimums do not fit, the total exceeds [available] and
  /// the table scrolls horizontally.
  static NiceColumnLayout resolve<T>({
    required List<NiceColumn<T>> columns,
    required double available,
    required Map<String, double> overrides,
    required int pinnedCount,
    required double leadingWidth,
  }) {
    final n = columns.length;
    final widths = List<double>.filled(n, 0);
    var pending = <int>[];
    var remaining = available - leadingWidth;
    for (var i = 0; i < n; i++) {
      final c = columns[i];
      final override = overrides[c.id];
      if (override != null) {
        widths[i] = override;
        remaining -= override;
      } else if (c.width.isFixed) {
        widths[i] = c.width.fixed!;
        remaining -= widths[i];
      } else {
        pending.add(i);
      }
    }

    // Proportional shares; whoever hits a bound is fixed at it and the
    // rest is shared again among the others.
    while (pending.isNotEmpty) {
      final totalFlex =
          pending.fold<double>(0, (s, i) => s + columns[i].width.flex);
      final next = <int>[];
      var clampedAny = false;
      for (final i in pending) {
        final policy = columns[i].width;
        final share = totalFlex <= 0
            ? 0.0
            : (remaining > 0 ? remaining : 0) * (policy.flex / totalFlex);
        final clamped = policy.clamp(share);
        widths[i] = clamped;
        if ((clamped - share).abs() > 0.5) {
          remaining -= clamped;
          clampedAny = true;
        } else {
          next.add(i);
        }
      }
      if (!clampedAny) break;
      pending = next;
    }

    for (var i = 0; i < n; i++) {
      widths[i] = widths[i].floorToDouble();
    }
    return NiceColumnLayout(
      widths: widths,
      pinnedCount: pinnedCount.clamp(0, n),
      leadingWidth: leadingWidth,
    );
  }
}
