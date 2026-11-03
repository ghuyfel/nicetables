/// Vertical rhythm of the table: how tall each row is and how much padding
/// cells get.
enum NiceDensity {
  /// 40 px rows. Dense operational screens and long lists.
  compact(40, 36),

  /// 52 px rows. The default; balanced for mixed text and chips.
  comfortable(52, 44),

  /// 64 px rows. Avatars with subtitles, touch-first layouts.
  spacious(64, 48);

  const NiceDensity(this.rowHeight, this.headerHeight);

  /// Height of a data row in logical pixels.
  final double rowHeight;

  /// Height of the header row in logical pixels.
  final double headerHeight;
}
