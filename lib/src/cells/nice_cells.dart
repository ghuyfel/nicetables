import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model/nice_status.dart';
import '../model/nice_table_strings.dart';
import '../theme/nice_table_theme.dart';

/// A soft, pill-shaped status chip: a coloured dot and label on a tinted
/// background, coloured by the theme's [NiceStatusPalette].
class NiceStatusChip extends StatelessWidget {
  /// Creates a status chip.
  const NiceStatusChip({
    required this.label,
    required this.status,
    this.icon,
    this.showDot = true,
    this.compact = false,
    super.key,
  });

  /// Creates a chip from a [NiceStatusValue].
  NiceStatusChip.fromValue(
    NiceStatusValue value, {
    IconData? icon,
    bool showDot = true,
    bool compact = false,
    Key? key,
  }) : this(
          label: value.label,
          status: value.status,
          icon: icon,
          showDot: showDot,
          compact: compact,
          key: key,
        );

  /// Text inside the chip.
  final String label;

  /// Picks the colours.
  final NiceStatus status;

  /// Optional icon shown instead of the dot.
  final IconData? icon;

  /// Whether to show the leading dot (ignored when [icon] is set).
  final bool showDot;

  /// Tighter padding for compact rows.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = NiceTableTheme.of(context);
    final colors = theme.statusPalette.of(status);
    final textStyle = theme.cellTextStyle.copyWith(
      color: colors.foreground,
      fontSize: compact ? 12 : 13,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: 0.1,
    );
    return Semantics(
      label: 'Status: $label',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 3 : 4,
        ),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(icon, size: 14, color: colors.foreground),
              )
            else if (showDot)
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(right: 7),
                decoration: BoxDecoration(
                  color: colors.foreground,
                  shape: BoxShape.circle,
                ),
              ),
            Flexible(
              child: Text(
                label,
                style: textStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A circular avatar that shows an image when available and otherwise the
/// initials of [name] on a hue derived from the name, so the same person
/// always gets the same colour.
class NiceAvatar extends StatelessWidget {
  /// Creates an avatar.
  const NiceAvatar({
    required this.name,
    this.image,
    this.size = 32,
    super.key,
  });

  /// Full name; up to two initials are drawn.
  final String name;

  /// Optional picture.
  final ImageProvider<Object>? image;

  /// Diameter in px.
  final double size;

  /// Initials for [name]: first letters of the first and last word.
  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  /// A stable, pleasant hue for [name].
  static Color colorOf(String name, {required bool dark}) {
    var hash = 0;
    for (final unit in name.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    final hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1, hue, dark ? 0.45 : 0.55, dark ? 0.70 : 0.38)
        .toColor();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = colorOf(name, dark: dark);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: dark ? 0.22 : 0.14),
        image: image == null
            ? null
            : DecorationImage(image: image!, fit: BoxFit.cover),
      ),
      alignment: Alignment.center,
      child: image == null
          ? Text(
              initialsOf(name),
              style: TextStyle(
                color: color,
                fontSize: size * 0.38,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                height: 1,
              ),
            )
          : null,
    );
  }
}

/// An avatar beside a name with an optional muted subtitle, the classic
/// "person" cell.
class NiceAvatarCell extends StatelessWidget {
  /// Creates a person cell.
  const NiceAvatarCell({
    required this.name,
    this.subtitle,
    this.image,
    this.avatarSize = 32,
    super.key,
  });

  /// Primary text, also used for the initials.
  final String name;

  /// Muted second line (email, role).
  final String? subtitle;

  /// Optional picture.
  final ImageProvider<Object>? image;

  /// Avatar diameter.
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    final theme = NiceTableTheme.of(context);
    return Row(
      children: [
        NiceAvatar(name: name, image: image, size: avatarSize),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.cellTextStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.foreground,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(
                  subtitle!,
                  style: theme.subtitleTextStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Monospace text with tabular figures for ids, hashes, serials and
/// timestamps.
class NiceMonoText extends StatelessWidget {
  /// Creates mono text.
  const NiceMonoText(this.text, {this.muted = false, super.key});

  /// The text.
  final String text;

  /// Use the muted foreground.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = NiceTableTheme.of(context);
    return Text(
      text,
      style: muted
          ? theme.monoTextStyle.copyWith(color: theme.mutedForeground)
          : theme.monoTextStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Text with a copy button that appears on hover (always visible on touch
/// screens) and copies [copyValue] to the clipboard.
class NiceCopyableText extends StatefulWidget {
  /// Creates copyable text.
  const NiceCopyableText(
    this.text, {
    this.copyValue,
    this.mono = true,
    this.onCopied,
    super.key,
  });

  /// Visible text.
  final String text;

  /// Value to copy; defaults to [text].
  final String? copyValue;

  /// Render in the theme's mono style.
  final bool mono;

  /// Called after a successful copy, for a toast.
  final VoidCallback? onCopied;

  @override
  State<NiceCopyableText> createState() => _NiceCopyableTextState();
}

class _NiceCopyableTextState extends State<NiceCopyableText> {
  bool _hover = false;
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(
        ClipboardData(text: widget.copyValue ?? widget.text));
    if (!mounted) return;
    setState(() => _copied = true);
    widget.onCopied?.call();
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = NiceTableTheme.of(context);
    final touch = Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.android;
    final visible = _hover || _copied || touch;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              widget.text,
              style: widget.mono ? theme.monoTextStyle : theme.cellTextStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          AnimatedOpacity(
            duration: theme.hoverDuration,
            opacity: visible ? 1 : 0,
            child: Tooltip(
              message: _copied
                  ? NiceTableStrings.of(context).copied
                  : NiceTableStrings.of(context).copy,
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: visible ? _copy : null,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    _copied ? Icons.check_rounded : Icons.copy_rounded,
                    size: 15,
                    color: _copied
                        ? theme.statusPalette.success.foreground
                        : theme.mutedForeground,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A slim progress bar with a percentage label.
class NiceProgressCell extends StatelessWidget {
  /// Creates a progress cell for a [value] in `0..1`.
  const NiceProgressCell(this.value, {this.showLabel = true, super.key});

  /// Fraction complete, clamped to `0..1`.
  final double value;

  /// Whether to show the percentage.
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final theme = NiceTableTheme.of(context);
    final v = value.clamp(0.0, 1.0);
    final color =
        v >= 1 ? theme.statusPalette.success.foreground : theme.accent;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 6,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: v),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (context, t, _) => LinearProgressIndicator(
                  value: t,
                  minHeight: 6,
                  backgroundColor: theme.skeleton,
                  color: color,
                ),
              ),
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 10),
          SizedBox(
            width: 40,
            child: Text(
              '${(v * 100).round()}%',
              textAlign: TextAlign.end,
              style: theme.cellTextStyle.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
                color: theme.mutedForeground,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A number with a coloured up/down delta beside it.
class NiceTrendCell extends StatelessWidget {
  /// Creates a trend cell.
  const NiceTrendCell({
    required this.text,
    required this.delta,
    this.deltaText,
    this.positiveIsGood = true,
    super.key,
  });

  /// The formatted main value.
  final String text;

  /// Change; sign picks the colour and arrow.
  final num delta;

  /// Formatted delta; defaults to a signed percentage of [delta].
  final String? deltaText;

  /// Whether a positive delta is shown in the success colour.
  final bool positiveIsGood;

  @override
  Widget build(BuildContext context) {
    final theme = NiceTableTheme.of(context);
    final up = delta > 0;
    final flat = delta == 0;
    final good = flat ? null : (up == positiveIsGood);
    final color = flat
        ? theme.mutedForeground
        : good!
            ? theme.statusPalette.success.foreground
            : theme.statusPalette.error.foreground;
    final label = deltaText ??
        '${up ? '+' : ''}${delta is int ? delta : delta.toStringAsFixed(1)}%';
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          text,
          style: theme.cellTextStyle.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          flat
              ? Icons.remove_rounded
              : up
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
          size: 13,
          color: color,
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: theme.cellTextStyle.copyWith(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// A 32 px icon button style with no minimum tap target, so buttons fit
/// inside every row density (Material's default 48 px minimum overflows
/// 40 px compact rows).
final ButtonStyle niceSmallIconButtonStyle = IconButton.styleFrom(
  minimumSize: const Size(32, 32),
  fixedSize: const Size(32, 32),
  padding: EdgeInsets.zero,
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
);

/// One action in a [NiceRowActions] menu.
class NiceAction {
  /// Creates an action.
  const NiceAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.destructive = false,
    this.enabled = true,
  });

  /// Menu label (also the tooltip when shown inline).
  final String label;

  /// Called when chosen.
  final VoidCallback onPressed;

  /// Optional icon.
  final IconData? icon;

  /// Shown in the error colour, after a divider.
  final bool destructive;

  /// Whether the item can be chosen.
  final bool enabled;
}

/// Row actions: the first [inlineCount] actions as icon buttons and the
/// rest behind a three-dot menu.
///
/// Use it inside `NiceColumn.actions`.
class NiceRowActions extends StatelessWidget {
  /// Creates row actions.
  const NiceRowActions({
    required this.actions,
    this.inlineCount = 0,
    super.key,
  });

  /// Actions in display order.
  final List<NiceAction> actions;

  /// How many leading actions (that have an icon) to show inline.
  final int inlineCount;

  @override
  Widget build(BuildContext context) {
    final theme = NiceTableTheme.of(context);
    final inline = actions.take(inlineCount).where((a) => a.icon != null);
    final menu = actions.skip(inlineCount).toList();
    final errorColor = theme.statusPalette.error.foreground;
    // Each button is 32 px wide; if the column is narrower than that, the
    // buttons scale down rather than overflow.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerEnd,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          for (final a in inline)
            IconButton(
              tooltip: a.label,
              iconSize: 18,
              style: niceSmallIconButtonStyle,
              color: a.destructive ? errorColor : theme.mutedForeground,
              onPressed: a.enabled ? a.onPressed : null,
              icon: Icon(a.icon),
            ),
          if (menu.isNotEmpty)
            PopupMenuButton<int>(
              tooltip: NiceTableStrings.of(context).moreActions,
              iconSize: 18,
              iconColor: theme.mutedForeground,
              padding: EdgeInsets.zero,
              style: niceSmallIconButtonStyle,
              constraints: const BoxConstraints(minWidth: 180),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: theme.border),
              ),
              onSelected: (i) => menu[i].onPressed(),
              itemBuilder: (context) => [
                for (var i = 0; i < menu.length; i++) ...[
                  if (menu[i].destructive && i > 0 && !menu[i - 1].destructive)
                    const PopupMenuDivider(),
                  PopupMenuItem<int>(
                    value: i,
                    enabled: menu[i].enabled,
                    height: 40,
                    child: Row(
                      children: [
                        if (menu[i].icon != null) ...[
                          Icon(
                            menu[i].icon,
                            size: 18,
                            color: menu[i].destructive
                                ? errorColor
                                : theme.mutedForeground,
                          ),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          menu[i].label,
                          style: theme.cellTextStyle.copyWith(
                            color: menu[i].destructive ? errorColor : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              icon: const Icon(Icons.more_horiz_rounded),
            ),
        ],
      ),
    );
  }
}
