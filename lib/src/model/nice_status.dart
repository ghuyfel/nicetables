/// Semantic status used by `NiceStatusChip` and `NiceColumn.status`.
enum NiceStatus {
  /// Completed, active, approved.
  success,

  /// Pending, attention needed.
  warning,

  /// Failed, rejected, blocked.
  error,

  /// Informational, in progress.
  info,

  /// Inactive, archived, unknown.
  neutral,
}

/// A status together with the label to display for it.
///
/// Return this from `NiceColumn.status`'s `value` callback; it sorts by
/// [label] and exports as [label].
class NiceStatusValue implements Comparable<NiceStatusValue> {
  /// Creates a status value.
  const NiceStatusValue(this.label, this.status);

  /// Human readable label, e.g. "Approved".
  final String label;

  /// Semantic status that picks the chip colours.
  final NiceStatus status;

  @override
  int compareTo(NiceStatusValue other) => label.compareTo(other.label);

  @override
  String toString() => label;

  @override
  bool operator ==(Object other) =>
      other is NiceStatusValue &&
      other.label == label &&
      other.status == status;

  @override
  int get hashCode => Object.hash(label, status);
}
