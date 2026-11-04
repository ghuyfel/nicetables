import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nicetables/nicetables.dart';

void main() {
  testWidgets('the go-to-page field draws no outline of its own under an outlined input theme', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const outlined = OutlineInputBorder(borderSide: BorderSide(color: Colors.red));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          inputDecorationTheme: const InputDecorationTheme(
            border: outlined,
            enabledBorder: outlined,
            focusedBorder: outlined,
          ),
        ),
        home: Scaffold(
          body: NiceTable<int>(
            rows: List.generate(400, (i) => i),
            columns: [NiceColumn.number('n', 'N', (i) => i)],
          ),
        ),
      ),
    );
    await tester.pump();

    // The go-to field is the footer's only numeric field.
    final field = tester.widget<TextField>(
      find.byWidgetPredicate((w) => w is TextField && w.keyboardType == TextInputType.number),
    );
    final decoration = field.decoration!;
    expect(decoration.border, InputBorder.none);
    expect(decoration.enabledBorder, InputBorder.none);
    expect(decoration.focusedBorder, InputBorder.none);
    expect(decoration.filled, isFalse);
  });
}
