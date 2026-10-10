import 'package:ukalab_core/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _options = [
  FailureChoiceSpec(optionId: 'recall', text: '再現率を優先する', isCorrect: true),
  FailureChoiceSpec(optionId: 'precision', text: '適合率を優先する', isCorrect: false),
];

ConfusionMatrixScenarioSpec _scenario({
  int initialTp = 40,
  int initialFp = 10,
  int initialFn = 10,
  int initialTn = 40,
}) =>
    ConfusionMatrixScenarioSpec(
      title: 'がん検診',
      description: '見逃し(偽陰性)と誤検知(偽陽性)、どちらが重いか。',
      initialTp: initialTp,
      initialFp: initialFp,
      initialFn: initialFn,
      initialTn: initialTn,
      options: _options,
      explanation: '病気を見逃す(偽陰性)方が重いため、再現率を優先する。',
    );

Widget _app(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child)),
    );

void main() {
  testWidgets('初期の混同行列から正解率・適合率・再現率・F値を表示する', (tester) async {
    await tester.pumpWidget(_app(ConfusionMatrixLabWidget(scenario: _scenario())));

    // accuracy=(40+40)/100=80%, precision=40/50=80%, recall=40/50=80%, f1=80%
    expect(find.text('正解率 80.0%'), findsOneWidget);
    expect(find.text('適合率 80.0%'), findsOneWidget);
    expect(find.text('再現率 80.0%'), findsOneWidget);
    expect(find.text('F値 80.0%'), findsOneWidget);
  });

  testWidgets('TPのスライダーを動かすと指標が連動する', (tester) async {
    await tester.pumpWidget(_app(ConfusionMatrixLabWidget(scenario: _scenario(
      initialTp: 0,
      initialFp: 0,
      initialFn: 100,
      initialTn: 0,
    ))));

    // tp=0,fp=0,fn=100,tn=0: recall=0/(0+100)=0%
    expect(find.text('再現率 0.0%'), findsOneWidget);

    final slider = find.byType(Slider).first;
    await tester.drag(slider, const Offset(500, 0));
    await tester.pumpAndSettle();

    expect(find.text('再現率 0.0%'), findsNothing);
  });

  testWidgets('正しい選択肢を選ぶと解説が出る', (tester) async {
    await tester.pumpWidget(_app(ConfusionMatrixLabWidget(scenario: _scenario())));

    await tester.tap(find.text('再現率を優先する'));
    await tester.pumpAndSettle();

    expect(find.text('わかった!'), findsOneWidget);
    expect(find.text('病気を見逃す(偽陰性)方が重いため、再現率を優先する。'), findsOneWidget);
  });

  testWidgets('誤った選択肢を選ぶとやり直しを促す', (tester) async {
    await tester.pumpWidget(_app(ConfusionMatrixLabWidget(scenario: _scenario())));

    await tester.tap(find.text('適合率を優先する'));
    await tester.pumpAndSettle();

    expect(find.text('んー、違うかも。もう一度選んでみて。'), findsOneWidget);
    expect(find.text('わかった!'), findsNothing);
  });
}
