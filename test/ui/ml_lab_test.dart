import 'package:ukalab_core/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _points = [
  MlLabPointSpec(x: 1, y: 1, label: 0),
  MlLabPointSpec(x: 2, y: 1.5, label: 0),
  MlLabPointSpec(x: 1.5, y: 2, label: 0),
  MlLabPointSpec(x: 1, y: 2.5, label: 0),
  MlLabPointSpec(x: 8, y: 8, label: 1),
  MlLabPointSpec(x: 7, y: 8.5, label: 1),
  MlLabPointSpec(x: 8.5, y: 7, label: 1),
  MlLabPointSpec(x: 9, y: 8, label: 1),
];

Widget _app(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child)),
    );

void main() {
  testWidgets('タイトル・説明・手法選択を表示する', (tester) async {
    await tester.pumpWidget(_app(const MlLabWidget(
      title: '線形分離',
      description: '2つのかたまりに分かれた点です。',
      points: _points,
    )));

    expect(find.text('線形分離'), findsOneWidget);
    expect(find.text('2つのかたまりに分かれた点です。'), findsOneWidget);
    expect(find.text('k近傍法'), findsOneWidget);
    expect(find.text('決定木'), findsOneWidget);
    expect(find.text('線形分類'), findsOneWidget);
  });

  testWidgets('kNNのkスライダーを動かせる', (tester) async {
    await tester.pumpWidget(_app(const MlLabWidget(
      title: '線形分離',
      description: '説明',
      points: _points,
    )));

    expect(find.text('k'), findsOneWidget);

    final slider = find.byType(Slider).first;
    await tester.drag(slider, const Offset(100, 0));
    await tester.pumpAndSettle();
    // 例外なく再描画できることを確認(境界の再計算がクラッシュしない)
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('決定木に切り替えると深さスライダーが出る', (tester) async {
    await tester.pumpWidget(_app(const MlLabWidget(
      title: '線形分離',
      description: '説明',
      points: _points,
    )));

    await tester.tap(find.text('決定木'));
    await tester.pumpAndSettle();
    expect(find.text('深さ'), findsOneWidget);
  });

  testWidgets('線形分類に切り替えると正則化スライダーが出る', (tester) async {
    await tester.pumpWidget(_app(const MlLabWidget(
      title: '線形分離',
      description: '説明',
      points: _points,
    )));

    await tester.tap(find.text('線形分類'));
    await tester.pumpAndSettle();
    expect(find.text('正則化'), findsOneWidget);
  });
}
