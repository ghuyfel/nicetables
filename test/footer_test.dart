import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nicetables/nicetables.dart';
import 'package:nicetables/src/widgets/nice_table_footer.dart';

class Item {
  const Item(this.id);
  final int id;
}

final items = List.generate(240, Item.new);
final columns = [NiceColumn<Item>.number('id', 'Id', (i) => i.id)];

/// Pumps a table [width] px wide on a 1400 x 900 surface.
Future<void> pumpTable(
  WidgetTester tester,
  NiceTableController<Item> c, {
  double width = 1100,
}) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            height: 600,
            child:
                NiceTable<Item>(rows: items, columns: columns, controller: c),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('nicePaginationItems', () {
    test('shows every page when they fit', () {
      expect(nicePaginationItems(7, 3), [1, 2, 3, 4, 5, 6, 7]);
      expect(nicePaginationItems(1, 1), [1]);
      expect(nicePaginationItems(0, 1), [1]);
    });

    test('elides the far side only, keeping a constant window', () {
      expect(nicePaginationItems(20, 1), [1, 2, 3, 4, 5, null, 20]);
      expect(nicePaginationItems(20, 4), [1, 2, 3, 4, 5, null, 20]);
      expect(nicePaginationItems(20, 5), [1, null, 4, 5, 6, null, 20]);
      expect(nicePaginationItems(20, 10), [1, null, 9, 10, 11, null, 20]);
      expect(nicePaginationItems(20, 17), [1, null, 16, 17, 18, 19, 20]);
      expect(nicePaginationItems(20, 20), [1, null, 16, 17, 18, 19, 20]);
    });

    test('siblings 0 gives the tight form', () {
      expect(
        nicePaginationItems(20, 10, siblings: 0),
        [1, null, 10, null, 20],
      );
      expect(nicePaginationItems(20, 2, siblings: 0), [1, 2, 3, null, 20]);
    });

    test('a window never duplicates boundary pages', () {
      for (var count = 1; count <= 30; count++) {
        for (var page = 1; page <= count; page++) {
          final pages = nicePaginationItems(count, page).whereType<int>();
          expect(pages.toSet().length, pages.length, reason: '$count/$page');
          expect(pages, contains(page), reason: '$count/$page');
          expect(pages.first, 1);
          expect(pages.last, count);
        }
      }
    });
  });

  group('NiceTableFooter', () {
    testWidgets('numbered pages, current highlighted, taps navigate',
        (tester) async {
      final c = NiceTableController<Item>(pageSize: 25);
      await pumpTable(tester, c);
      expect(c.pageCount, 10);
      expect(find.text('1–25 of 240 rows'), findsOneWidget);
      expect(find.bySemanticsLabel('Page 1, current page'), findsOneWidget);
      expect(find.text('…'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Page 3'));
      await tester.pumpAndSettle();
      expect(c.page, 2);
      expect(find.text('51–75 of 240 rows'), findsOneWidget);

      await tester.tap(find.byTooltip('Last page'));
      await tester.pumpAndSettle();
      expect(c.page, 9);
      expect(find.bySemanticsLabel('Page 10, current page'), findsOneWidget);
      final next = find.ancestor(
        of: find.byTooltip('Next page'),
        matching: find.byType(IconButton),
      );
      expect(tester.widget<IconButton>(next).onPressed, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('go to page field jumps and clamps', (tester) async {
      final c = NiceTableController<Item>(pageSize: 25);
      await pumpTable(tester, c);
      final field = find.bySemanticsLabel('Go to page');
      expect(field, findsOneWidget);
      await tester.enterText(field, '7');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(c.page, 6);
      await tester.enterText(field, '99');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(c.page, 9);
    });

    testWidgets('selection count shows beside the range', (tester) async {
      final c = NiceTableController<Item>(pageSize: 25)..selectAll([1, 2, 3]);
      await pumpTable(tester, c);
      expect(find.text('1–25 of 240 rows, 3 selected'), findsOneWidget);
    });

    testWidgets('medium width drops labels and ends, keeps numbers',
        (tester) async {
      final c = NiceTableController<Item>(pageSize: 25);
      await pumpTable(tester, c, width: 700);
      expect(find.text('Rows per page'), findsNothing);
      expect(find.byTooltip('First page'), findsNothing);
      expect(find.bySemanticsLabel('Go to page'), findsNothing);
      expect(find.bySemanticsLabel('Page 10'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('narrow width shows previous, "1 of 10", next', (tester) async {
      final c = NiceTableController<Item>(pageSize: 25);
      await pumpTable(tester, c, width: 480);
      expect(find.text('1 of 10'), findsOneWidget);
      expect(find.bySemanticsLabel('Page 10'), findsNothing);
      await tester.tap(find.byTooltip('Next page'));
      await tester.pumpAndSettle();
      expect(find.text('2 of 10'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
