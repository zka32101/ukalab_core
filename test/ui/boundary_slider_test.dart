import 'package:ukalab_core/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _conditions = [
  BoundaryConditionSpec(
    conditionId: 'forProfit',
    label: '営利目的か',
    trueLabel: '営利',
    falseLabel: '非営利',
  ),
  BoundaryConditionSpec(
    conditionId: 'enjoymentPurpose',
    label: '享受目的があるか',
    trueLabel: 'あり',
    falseLabel: 'なし',
  ),
];

BoundaryConclusion? _evaluate(Map<String, bool> values) {
  if (values['enjoymentPurpose'] == true) {
    return const BoundaryConclusion(text: '対象外（目安）', lawReference: '著作権法30条の4');
  }
  return const BoundaryConclusion(text: '適法（目安）', lawReference: '著作権法30条の4');
}

Widget _app(Widget child) => MaterialApp(
      theme: UkalabTheme.light(field: UkalabField.ai, cert: UkalabCert.gKentei),
      home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child)),
    );

void main() {
  testWidgets('条件を切り替えると結論が変わる', (tester) async {
    await tester.pumpWidget(_app(BoundarySliderWidget(
      title: '学習用データの収集',
      conditions: _conditions,
      evaluate: _evaluate,
    )));

    expect(find.text('適法（目安）'), findsOneWidget);
    expect(find.text('根拠: 著作権法30条の4'), findsOneWidget);

    await tester.tap(find.text('享受目的があるか'));
    await tester.pump();

    expect(find.text('対象外（目安）'), findsOneWidget);
  });

  testWidgets('結論がない組み合わせは未設定と表示する', (tester) async {
    await tester.pumpWidget(_app(BoundarySliderWidget(
      title: '学習用データの収集',
      conditions: _conditions,
      evaluate: (_) => null,
    )));
    expect(find.text('この組み合わせの判定は未設定です'), findsOneWidget);
  });

  testWidgets('目安であることを常に明示する', (tester) async {
    await tester.pumpWidget(_app(BoundarySliderWidget(
      title: '学習用データの収集',
      conditions: _conditions,
      evaluate: _evaluate,
    )));
    expect(find.textContaining('必ず原文・専門家にご確認ください'), findsOneWidget);
  });

  testWidgets('初期値を指定できる', (tester) async {
    await tester.pumpWidget(_app(BoundarySliderWidget(
      title: '学習用データの収集',
      conditions: _conditions,
      evaluate: _evaluate,
      initialValues: const {'enjoymentPurpose': true},
    )));
    expect(find.text('対象外（目安）'), findsOneWidget);
  });
}
