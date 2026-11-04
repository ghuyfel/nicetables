import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nicetables/nicetables.dart';

Widget table({required bool loading, Widget? refreshIndicator}) => MaterialApp(
      home: Scaffold(
        body: NiceTable<int>(
          rows: const [1, 2, 3],
          columns: [NiceColumn.number('n', 'N', (i) => i)],
          onRefresh: () {},
          loading: loading,
          refreshIndicator: refreshIndicator,
        ),
      ),
    );

void main() {
  testWidgets('the refresh button shows the given indicator while loading', (tester) async {
    await tester.pumpWidget(table(loading: true, refreshIndicator: const Icon(Icons.hourglass_top, key: Key('mine'))));
    await tester.pump();

    expect(find.byKey(const Key('mine')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.refresh_rounded), findsNothing);
  });

  testWidgets('without one, the default spinner shows; neither shows when idle', (tester) async {
    await tester.pumpWidget(table(loading: true));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpWidget(table(loading: false, refreshIndicator: const Icon(Icons.hourglass_top, key: Key('mine'))));
    await tester.pump();
    expect(find.byKey(const Key('mine')), findsNothing);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
  });
}
