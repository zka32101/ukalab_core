import 'package:ukalab_core/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

List<List<double>> _grid8x8() => [
      for (var r = 0; r < 8; r++) [for (var c = 0; c < 8; c++) (r + c) % 2 == 0 ? 1.0 : 0.0],
    ];

Widget _app(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child)),
    );

void main() {
  testWidgets('タイトル・説明・フィルタ選択・3段階の表示を表示する', (tester) async {
    await tester.pumpWidget(_app(ConvLabWidget(
      image: ConvLabImageSpec(title: '手書き風の「1」', description: '縦棒だけの画像。', grid: _grid8x8()),
    )));

    expect(find.text('手書き風の「1」'), findsOneWidget);
    expect(find.text('縦棒だけの画像。'), findsOneWidget);
    expect(find.text('縦エッジ検出'), findsOneWidget);
    expect(find.text('横エッジ検出'), findsOneWidget);
    expect(find.text('ぼかし'), findsOneWidget);
    expect(find.text('シャープ化'), findsOneWidget);
    expect(find.text('入力画像'), findsOneWidget);
    expect(find.text('特徴マップ'), findsOneWidget);
    expect(find.text('プーリング後'), findsOneWidget);
  });

  testWidgets('フィルタを切り替えても例外なく再描画できる', (tester) async {
    await tester.pumpWidget(_app(ConvLabWidget(
      image: ConvLabImageSpec(title: '手書き風の「1」', description: '説明', grid: _grid8x8()),
    )));

    await tester.tap(find.text('ぼかし'));
    await tester.pumpAndSettle();
    expect(find.byType(CustomPaint), findsWidgets);

    await tester.tap(find.text('シャープ化'));
    await tester.pumpAndSettle();
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
