/// Direction of a column sort.
enum NiceSortDirection {
  /// A to Z, smallest to largest, oldest to newest.
  ascending,

  /// Z to A, largest to smallest, newest to oldest.
  descending;

  /// The opposite direction.
  NiceSortDirection get flipped => this == NiceSortDirection.ascending
      ? NiceSortDirection.descending
      : NiceSortDirection.ascending;
}

/// The active sort: which column and in which direction.
class NiceSort {
  /// Creates a sort descriptor.
  const NiceSort(this.columnId, [this.direction = NiceSortDirection.ascending]);

  /// Id of the sorted `NiceColumn`.
  final String columnId;

  /// Direction of the sort.
  final NiceSortDirection direction;

  /// Whether this sort is ascending.
  bool get ascending => direction == NiceSortDirection.ascending;

  @override
  bool operator ==(Object other) =>
      other is NiceSort &&
      other.columnId == columnId &&
      other.direction == direction;

  @override
  int get hashCode => Object.hash(columnId, direction);

  @override
  String toString() => 'NiceSort($columnId, ${direction.name})';
}
