import 'package:flutter_test/flutter_test.dart';
import 'package:nicetables/nicetables.dart';

class Item {
  const Item(this.id, this.name, this.amount, this.status);
  final int id;
  final String name;
  final double amount;
  final NiceStatusValue status;
}

const ok = NiceStatusValue('Ok', NiceStatus.success);
const bad = NiceStatusValue('Bad', NiceStatus.error);

final items = [
  const Item(1, 'banana', 3, ok),
  const Item(2, 'Apple', 10, bad),
  const Item(3, 'cherry', 1, ok),
  const Item(4, 'date', 7, bad),
  const Item(5, 'elderberry', 7, ok),
];

final columns = <NiceColumn<Item>>[
  NiceColumn.text('name', 'Name', (i) => i.name),
  NiceColumn.number('amount', 'Amount', (i) => i.amount),
  NiceColumn.status('status', 'Status', (i) => i.status),
];

void main() {
  group('NiceTableController.process', () {
    test('returns rows unchanged without criteria', () {
      final c = NiceTableController<Item>();
      final r = c.process(items, columns);
      expect(r.pageRows.map((i) => i.id), [1, 2, 3, 4, 5]);
      expect(r.total, 5);
    });

    test('sorts strings case-insensitively and flips direction', () {
      final c = NiceTableController<Item>()..sortBy('name');
      expect(
        c.process(items, columns).pageRows.map((i) => i.name),
        ['Apple', 'banana', 'cherry', 'date', 'elderberry'],
      );
      c.toggleSort('name');
      expect(c.sort, const NiceSort('name', NiceSortDirection.descending));
      expect(c.process(items, columns).pageRows.first.name, 'elderberry');
      c.toggleSort('name');
      expect(c.sort, isNull);
    });

    test('sort is stable for ties', () {
      final c = NiceTableController<Item>()..sortBy('amount');
      final ids = c.process(items, columns).pageRows.map((i) => i.id).toList();
      expect(ids, [3, 1, 4, 5, 2]);
    });

    test('search is token based and case-insensitive', () {
      final c = NiceTableController<Item>()..setSearch('  ERR ');
      expect(c.process(items, columns).pageRows.map((i) => i.id), [3, 5]);
      c.setSearch('ok eld');
      expect(c.process(items, columns).pageRows.map((i) => i.id), [5]);
      c.setSearch('bad eld');
      expect(c.process(items, columns).pageRows, isEmpty);
      // Number columns are not searched by default.
      c.setSearch('7');
      expect(c.process(items, columns).pageRows, isEmpty);
    });

    test('filters compose with AND and reset the page', () {
      final c = NiceTableController<Item>(pageSize: 2)..goToPage(1);
      c.setFilter(
        'status',
        NiceFilter.equals(value: ok, valueOf: (i) => i.status),
      );
      expect(c.page, 0);
      expect(c.process(items, columns).matchingRows.map((i) => i.id), [1, 3, 5]);
      c.setFilter(
        'amount',
        NiceFilter.range(min: 2, max: null, valueOf: (i) => i.amount),
      );
      expect(c.process(items, columns).matchingRows.map((i) => i.id), [1, 5]);
      c.clearFilters();
      expect(c.filters, isEmpty);
    });

    test('pages and keeps the first row on page size change', () {
      final c = NiceTableController<Item>(pageSize: 2);
      final r1 = c.process(items, columns);
      expect(r1.pageRows.map((i) => i.id), [1, 2]);
      c.setTotalRows(r1.total);
      expect(c.pageCount, 3);
      c.nextPage();
      c.nextPage();
      expect(c.page, 2);
      expect(c.process(items, columns).pageRows.map((i) => i.id), [5]);
      c.setPageSize(3);
      expect(c.page, 1);
      expect(c.firstRowNumber, 4);
      expect(c.lastRowNumber, 5);
    });

    test('caches the sorted list between calls with the same query', () {
      final c = NiceTableController<Item>()..sortBy('name');
      final a = c.process(items, columns).matchingRows;
      final b = c.process(items, columns).matchingRows;
      expect(identical(a, b), isTrue);
      c.invalidate();
      expect(identical(c.process(items, columns).matchingRows, a), isFalse);
    });
  });

  group('selection, expansion, columns', () {
    test('selection helpers', () {
      final c = NiceTableController<Item>();
      var notified = 0;
      c.addListener(() => notified++);
      c.toggleSelected(1);
      c.selectAll([2, 3]);
      expect(c.selectedKeys, {1, 2, 3});
      c.deselectAll([2]);
      expect(c.selectedCount, 2);
      c.selectOnly(9);
      expect(c.selectedKeys, {9});
      c.clearSelection();
      expect(c.hasSelection, isFalse);
      expect(notified, 5);
    });

    test('column visibility respects the column default', () {
      final hiddenByDefault =
          NiceColumn<Item>.text('x', 'X', (i) => i.id, visible: false);
      final c = NiceTableController<Item>();
      expect(c.isColumnVisible(columns.first), isTrue);
      expect(c.isColumnVisible(hiddenByDefault), isFalse);
      c.toggleColumn(hiddenByDefault);
      expect(c.isColumnVisible(hiddenByDefault), isTrue);
      c.toggleColumn(columns.first);
      expect(c.visibleColumns([...columns, hiddenByDefault]).length, 3);
    });

    test('reset restores defaults', () {
      final c = NiceTableController<Item>(pageSize: 10)
        ..sortBy('name')
        ..setSearch('a')
        ..toggleSelected(1)
        ..setColumnWidth('name', 200)
        ..reset();
      expect(c.query, const NiceQuery<Item>(pageSize: 10));
      expect(c.selectedKeys, isEmpty);
      expect(c.columnWidths, isEmpty);
    });
  });

  group('NiceCsv', () {
    test('encodes with header, quoting and skips action columns', () {
      final cols = [
        ...columns,
        NiceColumn<Item>.actions('a', (_, __, ___) => throw UnimplementedError()),
      ];
      final csv = NiceCsv.encode(
        [const Item(1, 'has, comma', 1234.5, ok)],
        cols,
        lineBreak: '\n',
      );
      expect(csv, 'Name,Amount,Status\n"has, comma",1234.5,Ok\n');
    });
  });

  group('NiceFormat', () {
    test('number', () {
      expect(NiceFormat.number(1234567.891, decimals: 2), '1,234,567.89');
      expect(NiceFormat.number(-1000), '-1,000');
      expect(NiceFormat.number(12.5), '12.5');
      expect(NiceFormat.number(0.1 + 0.2, decimals: 1), '0.3');
    });
    test('dates and bytes', () {
      expect(NiceFormat.dateTime(DateTime(2026, 1, 5, 9, 7)), '2026-01-05 09:07');
      expect(
        NiceFormat.relative(
          DateTime(2026, 1, 1, 10),
          now: DateTime(2026, 1, 1, 12),
        ),
        '2 h ago',
      );
      expect(NiceFormat.bytes(1536), '1.5 KB');
      expect(NiceFormat.percent(0.256, decimals: 1), '25.6%');
    });
  });
}
