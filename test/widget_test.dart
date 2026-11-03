import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nicetables/nicetables.dart';

class Person {
  const Person(this.id, this.name, this.age, this.active);
  final int id;
  final String name;
  final int age;
  final bool active;
}

final people = List.generate(
  30,
  (i) => Person(i, 'Person ${i.toString().padLeft(2, '0')}', 20 + i, i.isEven),
);

List<NiceColumn<Person>> columns() => [
      NiceColumn.text('name', 'Name', (p) => p.name),
      NiceColumn.number('age', 'Age', (p) => p.age),
      NiceColumn.boolean('active', 'Active', (p) => p.active),
    ];

Widget wrap(Widget child,
        {Size size = const Size(1000, 700), bool dark = false}) =>
    MaterialApp(
      theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
      home: Scaffold(
        body: Center(
          child: SizedBox(width: size.width, height: size.height, child: child),
        ),
      ),
    );

void main() {
  testWidgets('renders header, first page and footer', (tester) async {
    await tester.pumpWidget(
      wrap(
          NiceTable<Person>(rows: people, columns: columns(), title: 'People')),
    );
    await tester.pumpAndSettle();
    expect(find.text('NAME'), findsOneWidget);
    expect(find.text('People'), findsOneWidget);
    expect(find.text('30 rows'), findsOneWidget);
    expect(find.text('Person 00'), findsOneWidget);
    expect(find.text('Person 25'), findsNothing); // page size 25
    expect(find.text('1–25 of 30'), findsOneWidget);
  });

  testWidgets('tapping a header sorts and tapping next pages', (tester) async {
    final c = NiceTableController<Person>(pageSize: 5);
    await tester.pumpWidget(
      wrap(NiceTable<Person>(rows: people, columns: columns(), controller: c)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('AGE'));
    await tester.pumpAndSettle();
    expect(c.sort, const NiceSort('age'));
    await tester.tap(find.text('AGE'));
    await tester.pumpAndSettle();
    expect(c.sort, const NiceSort('age', NiceSortDirection.descending));
    expect(find.text('Person 29'), findsOneWidget);
    expect(find.text('Person 00'), findsNothing);

    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();
    expect(c.page, 1);
    expect(find.text('Person 24'), findsOneWidget);
  });

  testWidgets('search filters rows and shows the empty state', (tester) async {
    await tester.pumpWidget(
      wrap(NiceTable<Person>(rows: people, columns: columns())),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Person 1');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Person 10'), findsOneWidget);
    expect(find.text('Person 00'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('No matching rows'), findsOneWidget);
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(find.text('Person 00'), findsOneWidget);
  });

  testWidgets('multi selection via checkbox and select-all', (tester) async {
    final c = NiceTableController<Person>(pageSize: 5);
    List<Person>? last;
    await tester.pumpWidget(
      wrap(
        NiceTable<Person>(
          rows: people,
          columns: columns(),
          controller: c,
          rowKey: (p) => p.id,
          selectionMode: NiceSelectionMode.multi,
          onSelectionChanged: (s) => last = s,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Select row 2'));
    await tester.pumpAndSettle();
    expect(c.selectedKeys, {1});
    expect(last!.single.id, 1);
    expect(find.text('1 selected'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Select all rows on this page'));
    await tester.pumpAndSettle();
    expect(c.selectedCount, 5);
    expect(find.text('Select all 30'), findsOneWidget);
    await tester.tap(find.text('Select all 30'));
    await tester.pumpAndSettle();
    expect(c.selectedCount, 30);

    await tester.tap(find.byTooltip('Clear selection'));
    await tester.pumpAndSettle();
    expect(c.hasSelection, isFalse);
  });

  testWidgets('row tap and expansion', (tester) async {
    Person? tapped;
    await tester.pumpWidget(
      wrap(
        NiceTable<Person>(
          rows: people,
          columns: columns(),
          rowKey: (p) => p.id,
          onRowTap: (p) => tapped = p,
          expandedBuilder: (_, p) => Text('Detail for ${p.name}'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Person 03'));
    expect(tapped?.id, 3);
    await tester.tap(find.byTooltip('Expand').first);
    await tester.pumpAndSettle();
    expect(find.text('Detail for Person 00'), findsOneWidget);
  });

  testWidgets('loading skeleton, error and retry', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      wrap(
          NiceTable<Person>(rows: const [], columns: columns(), loading: true)),
    );
    await tester.pump();
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);

    await tester.pumpWidget(
      wrap(
        NiceTable<Person>(
          rows: const [],
          columns: columns(),
          error: 'boom',
          onRetry: () => retried = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('boom'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });

  testWidgets('switches to cards below the breakpoint', (tester) async {
    await tester.pumpWidget(
      wrap(
        NiceTable<Person>(rows: people, columns: columns()),
        size: const Size(380, 700),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('NAME'), findsNothing); // no header row in cards
    expect(find.text('Person 00'), findsOneWidget);
    expect(find.text('Age'), findsWidgets); // key/value labels
  });

  testWidgets('sizes to content without a bounded height', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: NiceTable<Person>(
              rows: people.take(3).toList(),
              columns: columns(),
              paged: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Person 02'), findsOneWidget);
    expect(find.text('3 rows'), findsWidgets);
  });

  testWidgets('async table fetches, pages and surfaces errors', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      wrap(
        NiceAsyncTable<Person>(
          columns: columns(),
          fetch: (q) async {
            calls++;
            await Future<void>.delayed(const Duration(milliseconds: 50));
            if (q.search == 'fail') throw StateError('nope');
            final start = q.offset.clamp(0, people.length);
            final end = (start + q.pageSize).clamp(0, people.length);
            return NicePage(
                rows: people.sublist(start, end), total: people.length);
          },
        ),
      ),
    );
    await tester.pump();
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text('Person 00'), findsOneWidget);

    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Person 25'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'fail');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.textContaining('nope'), findsOneWidget);
  });

  testWidgets('theme derives from dark mode and honours scope', (tester) async {
    late NiceTableTheme resolved;
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) {
            resolved = NiceTableTheme.of(context);
            return const SizedBox();
          },
        ),
        dark: true,
      ),
    );
    expect(resolved.statusPalette.success.foreground, const Color(0xFF4ADE80));

    await tester.pumpWidget(
      wrap(
        NiceTableThemeScope(
          theme: NiceTableTheme.fromColorScheme(const ColorScheme.light())
              .copyWith(accent: Colors.purple),
          child: Builder(
            builder: (context) {
              resolved = NiceTableTheme.of(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(resolved.accent, Colors.purple);
  });
}
