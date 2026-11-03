import 'package:flutter/material.dart';

import '../model/nice_density.dart';
import '../model/nice_status.dart';

/// Foreground and soft background pair for one [NiceStatus].
class NiceStatusColors {
  /// Creates a status colour pair.
  const NiceStatusColors({required this.foreground, required this.background});

  /// Text, icon and dot colour.
  final Color foreground;

  /// Soft chip background.
  final Color background;

  /// Interpolates between two pairs.
  static NiceStatusColors lerp(
          NiceStatusColors a, NiceStatusColors b, double t) =>
      NiceStatusColors(
        foreground: Color.lerp(a.foreground, b.foreground, t)!,
        background: Color.lerp(a.background, b.background, t)!,
      );
}

/// Colours for every [NiceStatus].
class NiceStatusPalette {
  /// Creates a status palette.
  const NiceStatusPalette({
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.neutral,
  });

  /// Soft palette for light surfaces: dark saturated text on a tinted
  /// background, all at least 4.5:1.
  const NiceStatusPalette.light()
      : success = const NiceStatusColors(
          foreground: Color(0xFF15803D),
          background: Color(0xFFDCFCE7),
        ),
        warning = const NiceStatusColors(
          foreground: Color(0xFFB45309),
          background: Color(0xFFFEF3C7),
        ),
        error = const NiceStatusColors(
          foreground: Color(0xFFB91C1C),
          background: Color(0xFFFEE2E2),
        ),
        info = const NiceStatusColors(
          foreground: Color(0xFF1D4ED8),
          background: Color(0xFFDBEAFE),
        ),
        neutral = const NiceStatusColors(
          foreground: Color(0xFF4B5563),
          background: Color(0xFFF3F4F6),
        );

  /// Palette for dark surfaces: light text on a translucent tint.
  const NiceStatusPalette.dark()
      : success = const NiceStatusColors(
          foreground: Color(0xFF4ADE80),
          background: Color(0x2E22C55E),
        ),
        warning = const NiceStatusColors(
          foreground: Color(0xFFFBBF24),
          background: Color(0x2EF59E0B),
        ),
        error = const NiceStatusColors(
          foreground: Color(0xFFF87171),
          background: Color(0x2EEF4444),
        ),
        info = const NiceStatusColors(
          foreground: Color(0xFF60A5FA),
          background: Color(0x2E3B82F6),
        ),
        neutral = const NiceStatusColors(
          foreground: Color(0xFFD1D5DB),
          background: Color(0x299CA3AF),
        );

  /// Colours for success.
  final NiceStatusColors success;

  /// Colours for warning.
  final NiceStatusColors warning;

  /// Colours for error.
  final NiceStatusColors error;

  /// Colours for info.
  final NiceStatusColors info;

  /// Colours for neutral.
  final NiceStatusColors neutral;

  /// Colours for [status].
  NiceStatusColors of(NiceStatus status) => switch (status) {
        NiceStatus.success => success,
        NiceStatus.warning => warning,
        NiceStatus.error => error,
        NiceStatus.info => info,
        NiceStatus.neutral => neutral,
      };

  /// Interpolates between two palettes.
  static NiceStatusPalette lerp(
    NiceStatusPalette a,
    NiceStatusPalette b,
    double t,
  ) =>
      NiceStatusPalette(
        success: NiceStatusColors.lerp(a.success, b.success, t),
        warning: NiceStatusColors.lerp(a.warning, b.warning, t),
        error: NiceStatusColors.lerp(a.error, b.error, t),
        info: NiceStatusColors.lerp(a.info, b.info, t),
        neutral: NiceStatusColors.lerp(a.neutral, b.neutral, t),
      );
}

/// Every colour, text style and spacing a `NiceTable` uses.
///
/// Tables resolve their theme in this order: an explicit `theme` argument,
/// the nearest [NiceTableThemeScope], a `NiceTableTheme` registered as a
/// [ThemeExtension] on the app theme, and finally [NiceTableTheme.of],
/// which derives everything from `Theme.of(context)` so dark mode and
/// brand colours work with zero configuration.
class NiceTableTheme extends ThemeExtension<NiceTableTheme> {
  /// Creates a theme. Prefer [NiceTableTheme.fromTheme] or
  /// [NiceTableTheme.fromColorScheme] and `copyWith` the slots you need.
  const NiceTableTheme({
    required this.surface,
    required this.headerBackground,
    required this.headerForeground,
    required this.headerTextStyle,
    required this.cellTextStyle,
    required this.subtitleTextStyle,
    required this.monoTextStyle,
    required this.foreground,
    required this.mutedForeground,
    required this.accent,
    required this.onAccent,
    required this.stripe,
    required this.hover,
    required this.selected,
    required this.selectedHover,
    required this.divider,
    required this.border,
    required this.focusRing,
    required this.skeleton,
    required this.statusPalette,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.showBorder = true,
    this.showStripes = false,
    this.showRowDividers = true,
    this.showColumnDividers = false,
    this.horizontalPadding = 16,
    this.cellPadding = 12,
    this.density = NiceDensity.comfortable,
    this.hoverDuration = const Duration(milliseconds: 120),
    this.shadow,
  });

  /// Derives a theme from a [ColorScheme] and [TextTheme].
  ///
  /// This is the single place the defaults live; [fromTheme] delegates here.
  factory NiceTableTheme.fromColorScheme(
    ColorScheme scheme, {
    TextTheme? textTheme,
    NiceDensity density = NiceDensity.comfortable,
  }) {
    final dark = scheme.brightness == Brightness.dark;
    final on = scheme.onSurface;
    final surface = dark ? scheme.surfaceContainerLow : scheme.surface;
    final muted = on.withValues(alpha: dark ? 0.64 : 0.58);
    final base = textTheme?.bodyMedium ?? const TextStyle(fontSize: 14);
    final cell = base.copyWith(
      fontSize: 14,
      height: 1.3,
      color: on.withValues(alpha: dark ? 0.92 : 0.84),
    );
    return NiceTableTheme(
      surface: surface,
      headerBackground: dark
          ? Color.alphaBlend(on.withValues(alpha: 0.04), surface)
          : Color.alphaBlend(on.withValues(alpha: 0.025), surface),
      headerForeground: muted,
      headerTextStyle: (textTheme?.labelSmall ?? const TextStyle()).copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        height: 1.2,
        color: muted,
      ),
      cellTextStyle: cell,
      subtitleTextStyle: cell.copyWith(fontSize: 12, color: muted, height: 1.2),
      monoTextStyle: cell.copyWith(
        fontFamily: 'monospace',
        fontFamilyFallback: const [
          'JetBrains Mono',
          'SF Mono',
          'Menlo',
          'Consolas',
          'Roboto Mono',
          'monospace',
        ],
        fontSize: 13,
        letterSpacing: 0.2,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      foreground: on,
      mutedForeground: muted,
      accent: scheme.primary,
      onAccent: scheme.onPrimary,
      stripe: on.withValues(alpha: dark ? 0.03 : 0.02),
      hover: on.withValues(alpha: dark ? 0.06 : 0.04),
      selected: scheme.primary.withValues(alpha: dark ? 0.18 : 0.08),
      selectedHover: scheme.primary.withValues(alpha: dark ? 0.24 : 0.12),
      divider: on.withValues(alpha: dark ? 0.08 : 0.06),
      border: on.withValues(alpha: dark ? 0.12 : 0.10),
      focusRing: scheme.primary,
      skeleton: on.withValues(alpha: dark ? 0.10 : 0.07),
      statusPalette: dark
          ? const NiceStatusPalette.dark()
          : const NiceStatusPalette.light(),
      density: density,
      shadow: dark
          ? null
          : [
              BoxShadow(
                color: on.withValues(alpha: 0.04),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
    );
  }

  /// Derives a theme from a full [ThemeData], honouring a registered
  /// `NiceTableTheme` extension when present.
  factory NiceTableTheme.fromTheme(ThemeData theme) =>
      theme.extension<NiceTableTheme>() ??
      NiceTableTheme.fromColorScheme(
        theme.colorScheme,
        textTheme: theme.textTheme,
      );

  /// The theme for [context]: the nearest [NiceTableThemeScope], else one
  /// derived from the ambient [Theme].
  static NiceTableTheme of(BuildContext context) =>
      NiceTableThemeScope.maybeOf(context) ??
      NiceTableTheme.fromTheme(Theme.of(context));

  /// Card background behind the rows.
  final Color surface;

  /// Header row background.
  final Color headerBackground;

  /// Header icon colour.
  final Color headerForeground;

  /// Header label style.
  final TextStyle headerTextStyle;

  /// Default cell text style.
  final TextStyle cellTextStyle;

  /// Second-line style under a cell's text.
  final TextStyle subtitleTextStyle;

  /// Style for `mono` columns and ids.
  final TextStyle monoTextStyle;

  /// Strong foreground (titles, primary text).
  final Color foreground;

  /// Muted foreground (captions, footer text, icons).
  final Color mutedForeground;

  /// Brand accent: checkboxes, sort indicator, active filters, focus.
  final Color accent;

  /// Foreground on [accent].
  final Color onAccent;

  /// Alternate row background when [showStripes] is on.
  final Color stripe;

  /// Hovered row background.
  final Color hover;

  /// Selected row background.
  final Color selected;

  /// Selected and hovered row background.
  final Color selectedHover;

  /// Hairline between rows.
  final Color divider;

  /// Outer border and header underline.
  final Color border;

  /// Keyboard focus ring.
  final Color focusRing;

  /// Skeleton placeholder colour.
  final Color skeleton;

  /// Colours for status chips.
  final NiceStatusPalette statusPalette;

  /// Corner radius of the table card.
  final BorderRadius borderRadius;

  /// Whether to draw the outer border.
  final bool showBorder;

  /// Whether to tint alternate rows.
  final bool showStripes;

  /// Whether to draw hairlines between rows.
  final bool showRowDividers;

  /// Whether to draw hairlines between columns.
  final bool showColumnDividers;

  /// Padding at the leading and trailing edge of the table.
  final double horizontalPadding;

  /// Horizontal padding inside each cell.
  final double cellPadding;

  /// Default row density.
  final NiceDensity density;

  /// Duration of hover and selection colour transitions.
  final Duration hoverDuration;

  /// Optional shadow under the table card.
  final List<BoxShadow>? shadow;

  @override
  NiceTableTheme copyWith({
    Color? surface,
    Color? headerBackground,
    Color? headerForeground,
    TextStyle? headerTextStyle,
    TextStyle? cellTextStyle,
    TextStyle? subtitleTextStyle,
    TextStyle? monoTextStyle,
    Color? foreground,
    Color? mutedForeground,
    Color? accent,
    Color? onAccent,
    Color? stripe,
    Color? hover,
    Color? selected,
    Color? selectedHover,
    Color? divider,
    Color? border,
    Color? focusRing,
    Color? skeleton,
    NiceStatusPalette? statusPalette,
    BorderRadius? borderRadius,
    bool? showBorder,
    bool? showStripes,
    bool? showRowDividers,
    bool? showColumnDividers,
    double? horizontalPadding,
    double? cellPadding,
    NiceDensity? density,
    Duration? hoverDuration,
    List<BoxShadow>? shadow,
  }) =>
      NiceTableTheme(
        surface: surface ?? this.surface,
        headerBackground: headerBackground ?? this.headerBackground,
        headerForeground: headerForeground ?? this.headerForeground,
        headerTextStyle: headerTextStyle ?? this.headerTextStyle,
        cellTextStyle: cellTextStyle ?? this.cellTextStyle,
        subtitleTextStyle: subtitleTextStyle ?? this.subtitleTextStyle,
        monoTextStyle: monoTextStyle ?? this.monoTextStyle,
        foreground: foreground ?? this.foreground,
        mutedForeground: mutedForeground ?? this.mutedForeground,
        accent: accent ?? this.accent,
        onAccent: onAccent ?? this.onAccent,
        stripe: stripe ?? this.stripe,
        hover: hover ?? this.hover,
        selected: selected ?? this.selected,
        selectedHover: selectedHover ?? this.selectedHover,
        divider: divider ?? this.divider,
        border: border ?? this.border,
        focusRing: focusRing ?? this.focusRing,
        skeleton: skeleton ?? this.skeleton,
        statusPalette: statusPalette ?? this.statusPalette,
        borderRadius: borderRadius ?? this.borderRadius,
        showBorder: showBorder ?? this.showBorder,
        showStripes: showStripes ?? this.showStripes,
        showRowDividers: showRowDividers ?? this.showRowDividers,
        showColumnDividers: showColumnDividers ?? this.showColumnDividers,
        horizontalPadding: horizontalPadding ?? this.horizontalPadding,
        cellPadding: cellPadding ?? this.cellPadding,
        density: density ?? this.density,
        hoverDuration: hoverDuration ?? this.hoverDuration,
        shadow: shadow ?? this.shadow,
      );

  @override
  NiceTableTheme lerp(ThemeExtension<NiceTableTheme>? other, double t) {
    if (other is! NiceTableTheme) return this;
    return NiceTableTheme(
      surface: Color.lerp(surface, other.surface, t)!,
      headerBackground:
          Color.lerp(headerBackground, other.headerBackground, t)!,
      headerForeground:
          Color.lerp(headerForeground, other.headerForeground, t)!,
      headerTextStyle:
          TextStyle.lerp(headerTextStyle, other.headerTextStyle, t)!,
      cellTextStyle: TextStyle.lerp(cellTextStyle, other.cellTextStyle, t)!,
      subtitleTextStyle:
          TextStyle.lerp(subtitleTextStyle, other.subtitleTextStyle, t)!,
      monoTextStyle: TextStyle.lerp(monoTextStyle, other.monoTextStyle, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      stripe: Color.lerp(stripe, other.stripe, t)!,
      hover: Color.lerp(hover, other.hover, t)!,
      selected: Color.lerp(selected, other.selected, t)!,
      selectedHover: Color.lerp(selectedHover, other.selectedHover, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      border: Color.lerp(border, other.border, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      skeleton: Color.lerp(skeleton, other.skeleton, t)!,
      statusPalette:
          NiceStatusPalette.lerp(statusPalette, other.statusPalette, t),
      borderRadius: BorderRadius.lerp(borderRadius, other.borderRadius, t)!,
      showBorder: t < 0.5 ? showBorder : other.showBorder,
      showStripes: t < 0.5 ? showStripes : other.showStripes,
      showRowDividers: t < 0.5 ? showRowDividers : other.showRowDividers,
      showColumnDividers:
          t < 0.5 ? showColumnDividers : other.showColumnDividers,
      horizontalPadding:
          horizontalPadding + (other.horizontalPadding - horizontalPadding) * t,
      cellPadding: cellPadding + (other.cellPadding - cellPadding) * t,
      density: t < 0.5 ? density : other.density,
      hoverDuration: t < 0.5 ? hoverDuration : other.hoverDuration,
      shadow: t < 0.5 ? shadow : other.shadow,
    );
  }
}

/// Overrides the [NiceTableTheme] for every table in [child].
class NiceTableThemeScope extends InheritedWidget {
  /// Creates a theme scope.
  const NiceTableThemeScope({
    required this.theme,
    required super.child,
    super.key,
  });

  /// The theme to apply.
  final NiceTableTheme theme;

  /// The nearest scoped theme, if any.
  static NiceTableTheme? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NiceTableThemeScope>()?.theme;

  @override
  bool updateShouldNotify(NiceTableThemeScope oldWidget) =>
      oldWidget.theme != theme;
}
