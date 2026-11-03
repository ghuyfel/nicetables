import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nicetables/nicetables.dart';

class Row3 {
  const Row3(this.id, this.name);
  final int id;
  final String name;
}

final rows = List.generate(8, (i) => Row3(i, 'Row $i'));

List<NiceColumn<Row3>> columns() => [
      NiceColumn.custom(
        'name',
        'Name',
        (context, r, _) => NiceAvatarCell(name: r.name, subtitle: 'sub'),
        value: (r) => r.name,
      ),
      NiceColumn.text('plain', 'Plain', (r) => r.name,
          subtitle: (r) => 'second line'),
      NiceColumn.status(
        'status',
        'Status',
        (r) => const NiceStatusValue('Ok', NiceStatus.success),
        filterOptions: const [],
      ),
      NiceColumn.custom(
        'progress',
        'Progress',
        (context, r, _) => const NiceProgressCell(0.4),
      ),
      NiceColumn.boolean('flag', 'Flag', (r) => r.id.isEven),
      NiceColumn.actions(
        'actions',
        (context, r, _) => NiceRowActions(
          inlineCount: 1,
          actions: [
            NiceAction(
                label: 'Open', icon: Icons.open_in_new, onPressed: () {}),
            NiceAction(label: 'More', onPressed: () {}),
          ],
        ),
        width: 80,
      ),
    ];

void main() {
  // Any RenderFlex overflow throws inside pump, failing the test.
  for (final density in NiceDensity.values) {
    for (final width in [1100.0, 700.0]) {
      testWidgets('no overflow at ${density.name} density, $width px',
          (tester) async {
        tester.view.physicalSize = const Size(1400, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final c = NiceTableController<Row3>(density: density)
          ..selectAll([0, 1]);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: width,
                height: 600,
                child: NiceTable<Row3>(
                  rows: rows,
                  columns: columns(),
                  controller: c,
                  rowKey: (r) => r.id,
                  title: 'Overflow',
                  selectionMode: NiceSelectionMode.multi,
                  showDensityToggle: true,
                  showExport: true,
                  onRefresh: () {},
                  expandedBuilder: (_, r) => Text('detail ${r.id}'),
                  bulkActions: (context, selected) => [
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                    ),
                    FilledButton(onPressed: () {}, child: const Text('Go')),
                  ],
                  actions: [
                    FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add),
                      label: const Text('New'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('2 selected'), findsOneWidget);
        await tester.tap(find.byTooltip('Expand').first);
        await tester.pumpAndSettle();
        expect(find.text('detail 0'), findsOneWidget);
        // Overflow exceptions thrown during pumps fail the test by
        // themselves, with the full widget chain in the report.
      });
    }
  }
}
