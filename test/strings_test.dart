import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nicetables/nicetables.dart';

class Item {
  const Item(this.name, this.done);
  final String name;
  final bool done;
}

final items = List.generate(30, (i) => Item('Item $i', i.isEven));

List<NiceColumn<Item>> columns() => [
      NiceColumn.text('name', 'Name', (i) => i.name),
      NiceColumn.boolean('done', 'Done', (i) => i.done),
    ];

const french = NiceTableStrings(
  search: 'Rechercher',
  rows: 'lignes',
  rowCount: _lignes,
  rowsPerPage: 'Lignes par page',
  nextPage: 'Page suivante',
  previousPage: 'Page precedente',
  emptyTitle: 'Rien pour le moment',
  errorTitle: 'Chargement impossible',
  retry: 'Reessayer',
  columns: 'Colonnes',
  refresh: 'Actualiser',
  noMatchTitle: _aucune,
  clearFilters: 'Effacer les filtres',
  rowRange: _plage,
);

String _lignes(int count, String rowLabel) => '$count $rowLabel';
String _aucune(String rowLabel) => 'Aucune $rowLabel';
String _plage(int first, int last, int total, String rowLabel) =>
    '$first a $last sur $total';

/// Pumps [child] on a surface wide enough for the footer's full layout
/// (the "Rows per page" label only shows from 880 px).
Future<void> pumpTable(
  WidgetTester tester,
  Widget child, {
  NiceTableStrings? scoped,
}) async {
  await tester.binding.setSurfaceSize(const Size(1400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: scoped == null
            ? child
            : NiceTableStringsScope(strings: scoped, child: child),
      ),
    ),
  );
  // The row count reaches the toolbar one frame after the first build.
  await tester.pump();
}

void main() {
  testWidgets('English is drawn when nothing is configured', (tester) async {
    await pumpTable(
      tester,
      NiceTable<Item>(rows: items, columns: columns(), title: 'Items'),
    );

    expect(find.text('Rows per page'), findsOneWidget);
    expect(find.text('30 rows'), findsOneWidget);
    expect(find.textContaining('of 30 rows'), findsOneWidget);
    expect(find.byTooltip('Next page'), findsOneWidget);
    expect(find.byTooltip('Columns'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
  });

  testWidgets('a table-level strings argument translates the chrome',
      (tester) async {
    await pumpTable(
      tester,
      NiceTable<Item>(
        rows: items,
        columns: columns(),
        title: 'Items',
        strings: french,
        onRefresh: () {},
      ),
    );

    expect(find.text('Lignes par page'), findsOneWidget);
    expect(find.text('30 lignes'), findsOneWidget);
    expect(find.text('1 a 25 sur 30'), findsOneWidget);
    expect(find.byTooltip('Page suivante'), findsOneWidget);
    expect(find.byTooltip('Colonnes'), findsOneWidget);
    expect(find.byTooltip('Actualiser'), findsOneWidget);
    expect(find.text('Rechercher'), findsOneWidget);
    expect(find.text('Rows per page'), findsNothing);
  });

  testWidgets(
      'a scope above the table translates it, and the table argument wins',
      (tester) async {
    await pumpTable(
      tester,
      NiceTable<Item>(rows: items, columns: columns(), title: 'Items'),
      scoped: french,
    );
    expect(find.text('Lignes par page'), findsOneWidget);

    await pumpTable(
      tester,
      NiceTable<Item>(
        rows: items,
        columns: columns(),
        title: 'Items',
        strings: const NiceTableStrings(rowsPerPage: 'Zeilen pro Seite'),
      ),
      scoped: french,
    );
    expect(find.text('Zeilen pro Seite'), findsOneWidget);
    expect(find.text('Lignes par page'), findsNothing);
  });

  testWidgets('the explicit searchHint, emptyTitle and rowLabel still win',
      (tester) async {
    await pumpTable(
      tester,
      NiceTable<Item>(
        rows: const [],
        columns: columns(),
        title: 'Items',
        strings: french,
        searchHint: 'Find an item',
        emptyTitle: 'No items',
        rowLabel: 'items',
      ),
    );

    expect(find.text('Find an item'), findsOneWidget);
    expect(find.text('No items'), findsOneWidget);
    expect(find.text('0 items'), findsWidgets);
  });

  testWidgets('the empty, no-match and error states use the strings',
      (tester) async {
    await pumpTable(
      tester,
      NiceTable<Item>(rows: const [], columns: columns(), strings: french),
    );
    expect(find.text('Rien pour le moment'), findsOneWidget);

    final controller = NiceTableController<Item>(search: 'zzz');
    await pumpTable(
      tester,
      NiceTable<Item>(
        rows: items,
        columns: columns(),
        controller: controller,
        strings: french,
      ),
    );
    expect(find.text('Aucune lignes'), findsOneWidget);
    expect(find.text('Effacer les filtres'), findsOneWidget);

    await pumpTable(
      tester,
      NiceTable<Item>(
        rows: const [],
        columns: columns(),
        error: 'boom',
        onRetry: () {},
        strings: french,
      ),
    );
    expect(find.text('Chargement impossible'), findsOneWidget);
    expect(find.text('Reessayer'), findsOneWidget);
  });

  test('displayText reads yes and no from the strings', () {
    final column = NiceColumn<Item>.text('done', 'Done', (i) => i.done);
    const strings = NiceTableStrings(yes: 'Oui', no: 'Non');

    expect(column.displayText(const Item('a', true)), 'Yes');
    expect(column.displayText(const Item('a', true), strings: strings), 'Oui');
    expect(column.displayText(const Item('a', false), strings: strings), 'Non');
  });

  test('densityLabel maps every density', () {
    const strings = NiceTableStrings(
      densityCompact: 'C',
      densityComfortable: 'M',
      densitySpacious: 'S',
    );
    expect(NiceDensity.values.map(strings.densityLabel), ['C', 'M', 'S']);
  });
}
