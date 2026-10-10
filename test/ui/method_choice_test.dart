import 'package:ukalab_core/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _options = [
  FailureChoiceSpec(optionId: 'classification', text: '分類（教師あり学習）', isCorrect: true),
  FailureChoiceSpec(optionId: 'clustering', text: 'クラスタリング（教師なし学習）', isCorrect: false),
];

final _scenario = MethodChoiceScenarioSpec(
  title: '顧客の離脱予測',
  caseDescription: '顧客の年齢・購入履歴から、将来の離脱(はい/いいえ)を予測したい。',
  options: _options,
  explanation: '正解・不正解のラベル付きデータから学習するため、分類(教師あり学習)が適切。',
);

Widget _app(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child)),
    );

void main() {
  testWidgets('事例と選択肢を表示する', (tester) async {
    await tester.pumpWidget(_app(MethodChoiceWidget(scenario: _scenario)));

    expect(find.text('顧客の離脱予測'), findsOneWidget);
    expect(find.text('顧客の年齢・購入履歴から、将来の離脱(はい/いいえ)を予測したい。'), findsOneWidget);
    expect(find.text('分類（教師あり学習）'), findsOneWidget);
    expect(find.text('クラスタリング（教師なし学習）'), findsOneWidget);
  });

  testWidgets('正しい選択肢を選ぶと解説が出る', (tester) async {
    await tester.pumpWidget(_app(MethodChoiceWidget(scenario: _scenario)));

    await tester.tap(find.text('分類（教師あり学習）'));
    await tester.pumpAndSettle();

    expect(find.text('わかった!'), findsOneWidget);
    expect(find.text('正解・不正解のラベル付きデータから学習するため、分類(教師あり学習)が適切。'), findsOneWidget);
  });

  testWidgets('誤った選択肢を選ぶとやり直しを促す', (tester) async {
    await tester.pumpWidget(_app(MethodChoiceWidget(scenario: _scenario)));

    await tester.tap(find.text('クラスタリング（教師なし学習）'));
    await tester.pumpAndSettle();

    expect(find.text('んー、違うかも。もう一度選んでみて。'), findsOneWidget);
    expect(find.text('わかった!'), findsNothing);
  });
}
