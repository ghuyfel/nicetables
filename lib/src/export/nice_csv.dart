import '../model/nice_column.dart';

/// Turns rows and columns into CSV text.
abstract final class NiceCsv {
  /// Encodes [rows] using the exportable [columns].
  ///
  /// Columns without a value, text or export callback (such as action
  /// columns) are skipped. Values containing the [separator], quotes or
  /// line breaks are quoted per RFC 4180.
  static String encode<T>(
    List<T> rows,
    List<NiceColumn<T>> columns, {
    String separator = ',',
    bool includeHeader = true,
    String lineBreak = '\r\n',
  }) {
    final exportable = columns
        .where((c) => c.value != null || c.text != null || c.exportText != null)
        .toList();
    final buffer = StringBuffer();
    if (includeHeader) {
      buffer.write(
        exportable.map((c) => _escape(c.label, separator)).join(separator),
      );
      buffer.write(lineBreak);
    }
    for (final row in rows) {
      buffer.write(
        exportable
            .map((c) => _escape(c.exportValue(row), separator))
            .join(separator),
      );
      buffer.write(lineBreak);
    }
    return buffer.toString();
  }

  static String _escape(String value, String separator) {
    final needsQuotes = value.contains(separator) ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    if (!needsQuotes) return value;
    return '"${value.replaceAll('"', '""')}"';
  }
}
