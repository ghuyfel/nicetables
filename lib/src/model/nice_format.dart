/// Small, dependency-free formatters used by the default cells.
///
/// They are deliberately simple; pass your own `text` callback to a column
/// (or use `intl`) when you need locale-aware output.
abstract final class NiceFormat {
  /// Formats a number with thousands separators and [decimals] fraction
  /// digits, e.g. `1234567.891` with 2 decimals becomes `1,234,567.89`.
  static String number(
    num value, {
    int? decimals,
    String thousands = ',',
    String decimal = '.',
  }) {
    final fixed = decimals == null
        ? (value is int ? value.toString() : _trim(value.toString()))
        : value.toStringAsFixed(decimals);
    final negative = fixed.startsWith('-');
    final body = negative ? fixed.substring(1) : fixed;
    final dot = body.indexOf('.');
    final intPart = dot == -1 ? body : body.substring(0, dot);
    final fracPart = dot == -1 ? '' : body.substring(dot + 1);
    final buffer = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      final fromEnd = intPart.length - i;
      buffer.write(intPart[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buffer.write(thousands);
    }
    final out = fracPart.isEmpty ? '$buffer' : '$buffer$decimal$fracPart';
    return negative ? '-$out' : out;
  }

  static String _trim(String s) {
    if (!s.contains('.')) return s;
    var end = s.length;
    while (end > 0 && s[end - 1] == '0') {
      end--;
    }
    if (end > 0 && s[end - 1] == '.') end--;
    return s.substring(0, end);
  }

  /// Formats a date as `yyyy-MM-dd`.
  static String date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

  /// Formats a date and time as `yyyy-MM-dd HH:mm`.
  static String dateTime(DateTime d) => '${date(d)} ${time(d)}';

  /// Formats a time as `HH:mm`.
  static String time(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

  /// Formats a date relative to now: "just now", "5 min ago", "3 h ago",
  /// "2 d ago", otherwise the calendar date.
  static String relative(DateTime d, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(d);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays < 7) return '${diff.inDays} d ago';
    return date(d);
  }

  /// Formats a byte count as `1.2 MB`.
  static String bytes(num value) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var v = value.toDouble();
    var i = 0;
    while (v >= 1024 && i < units.length - 1) {
      v /= 1024;
      i++;
    }
    return '${i == 0 ? v.toInt() : v.toStringAsFixed(1)} ${units[i]}';
  }

  /// Formats a fraction in `0..1` as a percentage, e.g. `0.256` becomes
  /// `25.6%` with one decimal.
  static String percent(num fraction, {int decimals = 0}) =>
      '${(fraction * 100).toStringAsFixed(decimals)}%';

  static String _two(int v) => v.toString().padLeft(2, '0');
}
