import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nicetables_example/main.dart';

Future<void> loadRoboto() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ??
      (await Process.run('where', ['flutter']))
          .stdout
          .toString()
          .split('\n')
          .first
          .trim()
          .replaceAll(RegExp(r'[\\/]bin[\\/]flutter(\.bat)?\s*$'), '');
  final dir = Directory('$flutterRoot/bin/cache/artifacts/material_fonts');
  final loader = FontLoader('Roboto');
  for (final name in [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf'
  ]) {
    final f = File('${dir.path}/$name');
    if (f.existsSync()) {
      final bytes = await f.readAsBytes();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
  }
  await loader.load();
  // Material icons.
  final icons = File(
      '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final il = FontLoader('MaterialIcons')
      ..addFont(
          Future.value(ByteData.view((await icons.readAsBytes()).buffer)));
    await il.load();
  }
}

Future<void> snap(WidgetTester tester, String name) async {
  // Real async engine work only completes inside runAsync.
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byType(RepaintBoundary).first);
    final image =
        await boundary.toImage(pixelRatio: tester.view.devicePixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final out = Platform.environment['SNAP_DIR'] ?? '.';
    File('$out/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

/// Bounded alternative to pumpAndSettle (never hangs on repeating animations).
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Renders the gallery's Transactions tab to PNG files for visual checks.
///
/// Opt in with `SNAP_DIR=<folder> flutter test test/screenshot_test.dart`
/// (and `FLUTTER_ROOT` so real fonts load); it is skipped otherwise.
void main() {
  final snapDir = Platform.environment['SNAP_DIR'];
  testWidgets('render transactions tab', skip: snapDir == null, (tester) async {
    await tester.runAsync(loadRoboto);
    for (final (dpr, w, h, label) in [
      (1.0, 1400.0, 900.0, 'dpr1_1400'),
      (1.5, 1400.0, 900.0, 'dpr15_1400'),
      (1.0, 1000.0, 700.0, 'dpr1_1000'),
    ]) {
      tester.view.devicePixelRatio = dpr;
      tester.view.physicalSize = Size(w * dpr, h * dpr);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GalleryApp());
      await settle(tester);
      await snap(tester, 'transactions_$label');
      // Hover a row and open an expander for the detail panel.
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text('Yara Volkov').first));
      await settle(tester);
      await tester.tap(find.byTooltip('Expand').first);
      await settle(tester);
      await snap(tester, 'transactions_${label}_hover_expanded');
      await gesture.removePointer();
      await tester.pump();
      // Compact density via the toolbar menu.
      await tester.tap(find.byTooltip('Density'));
      await settle(tester);
      await tester.tap(find.text('Compact'));
      await settle(tester);
      await snap(tester, 'transactions_${label}_compact');
    }
  });
}
