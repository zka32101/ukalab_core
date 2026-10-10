import 'package:ukalab_core/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _curve = [
  LearningCurvePointSpec(epoch: 1, trainLoss: 0.8, valLoss: 0.9),
  LearningCurvePointSpec(epoch: 5, trainLoss: 0.2, valLoss: 0.1),
  LearningCurvePointSpec(epoch: 10, trainLoss: 0.05, valLoss: 0.6),
];

const _symptomOptions = [
  FailureChoiceSpec(optionId: 'underfit', text: '未学習', isCorrect: false),
  FailureChoiceSpec(optionId: 'overfit', text: '過学習', isCorrect: true),
];

const _treatmentOptions = [
  FailureChoiceSpec(optionId: 'more-epoch', text: 'エポック数を増やす', isCorrect: false),
  FailureChoiceSpec(optionId: 'regularize', text: '正則化を強める', isCorrect: true),
];

Widget _app(Widget child) => MaterialApp(
      theme: UkalabTheme.light(field: UkalabField.ai, cert: UkalabCert.gKentei),
      home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child)),
    );

Widget _widget() => const FailureGalleryWidget(
      title: '学習曲線1',
      curve: _curve,
      symptomOptions: _symptomOptions,
      treatmentOptions: _treatmentOptions,
      explanation: '訓練誤差は下がり続けるが検証誤差が途中から上がる、過学習の典型例。',
    );

void main() {
  testWidgets('最初は症状の選択肢を表示する', (tester) async {
    await tester.pumpWidget(_app(_widget()));

    expect(find.text('この学習曲線の症状は?'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, '過学習'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'エポック数を増やす'), findsNothing);
  });

  testWidgets('症状を誤ると、まだ解けないヒントが出る', (tester) async {
    await tester.pumpWidget(_app(_widget()));

    await tester.tap(find.widgetWithText(ChoiceChip, '未学習'));
    await tester.pump();

    expect(find.text('んー、違うかも。もう一度選んでみて。'), findsOneWidget);
    expect(find.text('この学習曲線の症状は?'), findsOneWidget);
  });

  testWidgets('症状に正解すると処方の選択肢に進む', (tester) async {
    await tester.pumpWidget(_app(_widget()));

    await tester.tap(find.widgetWithText(ChoiceChip, '過学習'));
    await tester.pump();

    expect(find.text('症状: 過学習'), findsOneWidget);
    expect(find.text('この症状への処方は?'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, '正則化を強める'), findsOneWidget);
  });

  testWidgets('処方に正解すると、わかった演出と解説が出る', (tester) async {
    await tester.pumpWidget(_app(_widget()));

    await tester.tap(find.widgetWithText(ChoiceChip, '過学習'));
    await tester.pump();
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, '正則化を強める'));
    await tester.tap(find.widgetWithText(ChoiceChip, '正則化を強める'));
    await tester.pump();

    expect(find.text('わかった!'), findsOneWidget);
    expect(find.text('訓練誤差は下がり続けるが検証誤差が途中から上がる、過学習の典型例。'), findsOneWidget);
  });

  testWidgets('処方を誤ると、まだ解けないヒントが出る', (tester) async {
    await tester.pumpWidget(_app(_widget()));

    await tester.tap(find.widgetWithText(ChoiceChip, '過学習'));
    await tester.pump();
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'エポック数を増やす'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'エポック数を増やす'));
    await tester.pump();

    expect(find.text('んー、違うかも。もう一度選んでみて。'), findsOneWidget);
    expect(find.text('この症状への処方は?'), findsOneWidget);
  });
}
