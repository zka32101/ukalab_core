import 'package:ukalab_core/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _points = [
  NnBuilderPointSpec(x: 1, y: 1, label: 0),
  NnBuilderPointSpec(x: 2, y: 1.5, label: 0),
  NnBuilderPointSpec(x: 1.5, y: 2, label: 0),
  NnBuilderPointSpec(x: 1, y: 2.5, label: 0),
  NnBuilderPointSpec(x: 8, y: 8, label: 1),
  NnBuilderPointSpec(x: 7, y: 8.5, label: 1),
  NnBuilderPointSpec(x: 8.5, y: 7, label: 1),
  NnBuilderPointSpec(x: 9, y: 8, label: 1),
];

Widget _app(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child)),
    );

void main() {
  testWidgets('タイトル・説明・ハイパーパラメータ操作を表示する', (tester) async {
    await tester.pumpWidget(_app(const NnBuilderWidget(
      title: '2つのかたまりを分ける',
      description: '2つのかたまりに分かれた点です。',
      points: _points,
    )));

    expect(find.text('2つのかたまりを分ける'), findsOneWidget);
    expect(find.text('2つのかたまりに分かれた点です。'), findsOneWidget);
    expect(find.text('1層'), findsOneWidget);
    expect(find.text('2層'), findsOneWidget);
    expect(find.text('シグモイド'), findsOneWidget);
    expect(find.text('ReLU'), findsOneWidget);
    expect(find.text('tanh'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('学習曲線で誤差が最終的に下がる', (tester) async {
    await tester.pumpWidget(_app(const NnBuilderWidget(
      title: '2つのかたまりを分ける',
      description: '説明',
      points: _points,
    )));

    expect(find.textContaining('誤差: '), findsOneWidget);
    final textWidget = tester.widget<Text>(find.textContaining('誤差: '));
    final text = textWidget.data!;
    final match = RegExp(r'誤差: ([\d.]+) → ([\d.]+)').firstMatch(text)!;
    final start = double.parse(match.group(1)!);
    final end = double.parse(match.group(2)!);
    expect(end, lessThan(start));
  });

  testWidgets('隠れ層の数を切り替えても例外なく再描画できる', (tester) async {
    await tester.pumpWidget(_app(const NnBuilderWidget(
      title: '2つのかたまりを分ける',
      description: '説明',
      points: _points,
    )));

    await tester.tap(find.text('2層'));
    await tester.pumpAndSettle();
    expect(find.byType(CustomPaint), findsWidgets);

    await tester.tap(find.text('tanh'));
    await tester.pumpAndSettle();
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
