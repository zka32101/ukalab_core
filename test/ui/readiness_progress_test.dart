import 'package:ukalab_core/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  masteryInputTests();
  const rule = ReadinessRule.standard;
  const half = MasteryInput(coverage: 0.7, accuracy: 0.7); // 0.49

  test('習得度が足りなければ、あと何%かが出る', () {
    final p = rule.progress(mastery: half, mockPassed: false);
    expect(p.isReady, isFalse);
    expect(p.masteryPercentLeft, 31);
    expect(p.mockNeeded, isTrue);
  });

  test('isReady と progress.isReady は一致する', () {
    const full = MasteryInput(coverage: 1, accuracy: 1);
    expect(rule.progress(mastery: full, mockPassed: true).isReady,
        rule.isReady(mastery: full, mockPassed: true));
    expect(rule.progress(mastery: full, mockPassed: false).isReady, isFalse);
  });

  testWidgets('カードは責めない文言で進み具合を出す', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ReadinessProgressCard(
            progress: rule.progress(mastery: half, mockPassed: false)),
      ),
    ));
    expect(find.text('習得度があと31%、模擬試験の合格でそろいます'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}

void masteryInputTests() {
  group('MasteryInput の共通計算', () {
    test('回答がなければ0', () {
      final m = MasteryInput.fromLogs(questionIds: {'a', 'b'}, logs: const []);
      expect(m.coverage, 0);
      expect(m.accuracy, 0);
    });

    test('区分の問題だけを数え、網羅率と正答率を出す', () {
      final m = MasteryInput.fromLogs(
        questionIds: {'a', 'b', 'c', 'd'},
        logs: [
          (questionId: 'a', isCorrect: true),
          (questionId: 'a', isCorrect: false),
          (questionId: 'b', isCorrect: true),
          (questionId: 'zzz', isCorrect: true),
        ],
      );
      expect(m.coverage, 0.5);
      expect(m.accuracy, closeTo(2 / 3, 1e-9));
    });

    test('件数からも同じ値になり、範囲外は0〜1に収まる', () {
      final m = MasteryInput.fromCounts(
          distinctAnswered: 5, totalQuestions: 4, correct: 3, answered: 3);
      expect(m.coverage, 1.0);
      expect(m.accuracy, 1.0);
      expect(MasteryInput.fromCounts(distinctAnswered: 0, totalQuestions: 0, correct: 0, answered: 0).coverage, 0);
    });
  });
}
