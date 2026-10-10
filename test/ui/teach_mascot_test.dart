import 'package:ukalab_core/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _options = [
  MisconceptionChoiceSpec(optionId: 'wrong', text: '非営利', isCorrect: false),
  MisconceptionChoiceSpec(optionId: 'right', text: '享受目的を含まない', isCorrect: true),
];

Widget _app(Widget child) => MaterialApp(
      theme: UkalabTheme.light(field: UkalabField.ai, cert: UkalabCert.gKentei),
      home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child)),
    );

void main() {
  testWidgets('最初は誤った選択肢が入った答案を表示する', (tester) async {
    await tester.pumpWidget(_app(const TeachMascotWidget(
      title: '学習用データの収集',
      statementTemplate: 'この学習データの収集は、{blank}だから問題ない',
      options: _options,
      explanation: '著作権法30条の4は享受目的かどうかが要件。',
    )));

    expect(find.text('ここが分からない…'), findsOneWidget);
    expect(find.textContaining('この学習データの収集は、'), findsOneWidget);
    expect(find.text('著作権法30条の4は享受目的かどうかが要件。'), findsNothing);
  });

  testWidgets('誤りをタップすると、まだ解けないヒントが出る', (tester) async {
    await tester.pumpWidget(_app(const TeachMascotWidget(
      title: '学習用データの収集',
      statementTemplate: 'この学習データの収集は、{blank}だから問題ない',
      options: _options,
      explanation: '解説',
    )));

    await tester.tap(find.widgetWithText(ChoiceChip, '非営利'));
    await tester.pump();

    expect(find.text('んー、違うかも。もう一度選んでみて。'), findsOneWidget);
    expect(find.text('ここが分からない…'), findsOneWidget);
  });

  testWidgets('正解をタップすると、わかった演出と解説が出る', (tester) async {
    await tester.pumpWidget(_app(const TeachMascotWidget(
      title: '学習用データの収集',
      statementTemplate: 'この学習データの収集は、{blank}だから問題ない',
      options: _options,
      explanation: '著作権法30条の4は享受目的かどうかが要件。',
    )));

    await tester.tap(find.widgetWithText(ChoiceChip, '享受目的を含まない'));
    await tester.pump();

    expect(find.text('わかった!'), findsOneWidget);
    expect(find.text('著作権法30条の4は享受目的かどうかが要件。'), findsOneWidget);
  });

  testWidgets('解けたあとは選択肢をタップしても変わらない', (tester) async {
    await tester.pumpWidget(_app(const TeachMascotWidget(
      title: '学習用データの収集',
      statementTemplate: 'この学習データの収集は、{blank}だから問題ない',
      options: _options,
      explanation: '解説',
    )));

    await tester.tap(find.widgetWithText(ChoiceChip, '享受目的を含まない'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ChoiceChip, '非営利'));
    await tester.pump();

    expect(find.text('わかった!'), findsOneWidget);
  });
}
