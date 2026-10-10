import 'package:ukalab_core/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
      theme: UkalabTheme.light(field: UkalabField.ai, cert: UkalabCert.gKentei),
      home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child)),
    );

void main() {
  testWidgets('予測するとあなたの予測・正解・解説が出る', (tester) async {
    await tester.pumpWidget(_app(const PredictRunWidget(
      title: '確率の手ざわり',
      question: '陽性なら本当に病気の確率は?',
      correctAnswer: 0.15,
      explanation: '事前確率が低いと、検査で陽性でも病気である確率は意外と低い。',
    )));

    expect(find.text('予測する'), findsOneWidget);
    await tester.tap(find.text('予測する'));
    await tester.pump();

    expect(find.text('あなたの予測'), findsOneWidget);
    expect(find.text('正解'), findsOneWidget);
    expect(find.text('15%'), findsOneWidget);
    expect(find.textContaining('事前確率が低いと'), findsOneWidget);
  });

  testWidgets('もう一度予測するとスライダーに戻る', (tester) async {
    await tester.pumpWidget(_app(const PredictRunWidget(
      title: '確率の手ざわり',
      question: '陽性なら本当に病気の確率は?',
      correctAnswer: 0.15,
      explanation: '解説',
    )));

    await tester.tap(find.text('予測する'));
    await tester.pump();
    await tester.tap(find.text('もう一度予測する'));
    await tester.pump();

    expect(find.text('予測する'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets('valueLabel でパーセント以外の表示にできる', (tester) async {
    await tester.pumpWidget(_app(PredictRunWidget(
      title: '期待値',
      question: 'このくじの期待値は?',
      correctAnswer: 10,
      explanation: '解説',
      min: 0,
      max: 100,
      valueLabel: (v) => '${v.round()}円',
    )));

    expect(find.text('50円'), findsOneWidget);
    await tester.tap(find.text('予測する'));
    await tester.pump();
    expect(find.text('10円'), findsOneWidget);
  });
}
