import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/answer_feedback.dart';
import 'package:ukalab_core/ukalab_core.dart';

Question _question({String qid = 'q1', List<String>? compareWith}) =>
    Question.fromJson({
      'qid': qid,
      'examId': 'sample',
      'subjectId': 'math',
      'topicId': 'ch1',
      'prompt': '問題',
      'choices': ['a', 'b', 'c'],
      'answerIndex': 1,
      'explanation': '解説',
      'source': 'original',
      'sourceRef': '自作',
      'contentVer': '1',
      if (compareWith != null) 'compareWith': compareWith,
    });

Term _term(String id, String name, {List<String> related = const []}) =>
    Term.fromJson({
      'termId': id,
      'examId': 'sample',
      'term': name,
      'headline': '$nameのひとこと',
      'definition': '$nameの定義',
      'commonMistake': '$nameとの違い',
      'relatedQuestionIds': related,
      'source': 'original',
      'sourceRef': '自作',
      'contentVer': '1',
    });

Widget _app(Widget child, {KitStrings? kit}) {
  final body = MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
  return kit == null ? body : KitStringsScope(strings: kit, child: body);
}

void main() {
  const ja = AnswerFeedbackStrings.ja;

  group('WrongCauseSelector', () {
    testWidgets('4つのラベルを出し、選択と取り消しをコールバックで返す', (tester) async {
      final calls = <WrongCause?>[];
      WrongCause? current;
      await tester.pumpWidget(_app(StatefulBuilder(
        builder: (context, setState) => WrongCauseSelector(
          selected: current,
          onSelected: (c) {
            calls.add(c);
            setState(() => current = c);
          },
        ),
      )));

      for (final label in ['知識不足', 'ひっかけ', '計算ミス', '読み違い']) {
        expect(find.text(label), findsOneWidget);
      }
      await tester.tap(find.text('ひっかけ'));
      await tester.pump();
      await tester.tap(find.text('ひっかけ'));
      await tester.pump();
      expect(calls, [WrongCause.trap, null]);
    });

    testWidgets('includeCalculation: false で「計算ミス」を出さない', (tester) async {
      await tester.pumpWidget(_app(
        WrongCauseSelector(includeCalculation: false, onSelected: (_) {}),
      ));
      expect(find.text('計算ミス'), findsNothing);
      expect(find.text('知識不足'), findsOneWidget);
      expect(find.text('ひっかけ'), findsOneWidget);
      expect(find.text('読み違い'), findsOneWidget);
    });

    testWidgets('言語は KitStringsScope に従う', (tester) async {
      await tester.pumpWidget(_app(
        WrongCauseSelector(onSelected: (_) {}),
        kit: KitStrings.en,
      ));
      expect(find.text(AnswerFeedbackStrings.en.causeTrap), findsOneWidget);
      expect(find.text('ひっかけ'), findsNothing);
    });
  });

  group('AnswerFeedbackPanel', () {
    testWidgets('不正解なら原因の選択を出し、選ぶと onCause と対策を返す', (tester) async {
      final causes = <WrongCause?>[];
      await tester.pumpWidget(_app(AnswerFeedbackPanel(
        question: _question(),
        selectedIndex: 0,
        onCause: causes.add,
      )));

      expect(find.byType(WrongCauseSelector), findsOneWidget);
      expect(find.text(ja.prescriptionTitle), findsNothing);

      await tester.tap(find.text('知識不足'));
      await tester.pump();
      expect(causes, [WrongCause.knowledge]);
      expect(find.text(ja.prescriptionTitle), findsOneWidget);
      expect(find.text(ja.prescriptionStudy), findsOneWidget);

      await tester.tap(find.text('ひっかけ'));
      await tester.pump();
      expect(find.text(ja.prescriptionCompare), findsOneWidget);

      await tester.tap(find.text('ひっかけ'));
      await tester.pump();
      expect(causes.last, isNull);
      expect(find.text(ja.prescriptionTitle), findsNothing);
    });

    testWidgets('正解なら何も出さない', (tester) async {
      await tester.pumpWidget(_app(AnswerFeedbackPanel(
        question: _question(compareWith: const ['t2']),
        selectedIndex: 1,
        terms: [_term('t1', '用語A', related: const ['q1']), _term('t2', '用語B')],
        onCause: (_) {},
      )));
      expect(find.byType(WrongCauseSelector), findsNothing);
      expect(find.byType(ComparisonCard), findsNothing);
    });

    testWidgets('isCorrect を渡せば選択式でない問題にも使える', (tester) async {
      await tester.pumpWidget(_app(AnswerFeedbackPanel(
        question: _question(),
        selectedIndex: null,
        isCorrect: false,
        onCause: (_) {},
      )));
      expect(find.byType(WrongCauseSelector), findsOneWidget);
    });

    testWidgets('compareWith が無くても落ちず、比較表示は出さない', (tester) async {
      await tester.pumpWidget(_app(AnswerFeedbackPanel(
        question: _question(),
        selectedIndex: 0,
        terms: [_term('t1', '用語A', related: const ['q1'])],
        onCause: (_) {},
      )));
      expect(tester.takeException(), isNull);
      expect(find.byType(ComparisonCard), findsNothing);
      expect(find.byType(WrongCauseSelector), findsOneWidget);
    });

    testWidgets('compareWith と用語があれば違いの比較表示を出す', (tester) async {
      await tester.pumpWidget(_app(AnswerFeedbackPanel(
        question: _question(compareWith: const ['t2']),
        selectedIndex: 0,
        terms: [_term('t1', '用語A', related: const ['q1']), _term('t2', '用語B')],
        onCause: (_) {},
      )));
      expect(find.byType(ComparisonCard), findsOneWidget);
      expect(find.text(ja.comparisonTitle), findsOneWidget);
      expect(find.text('用語A'), findsOneWidget);
      expect(find.text('用語B'), findsOneWidget);
      expect(find.text('用語Bとの違い'), findsOneWidget);
      expect(find.text(ja.comparisonAnswer), findsOneWidget);
      expect(find.text(ja.comparisonOther), findsOneWidget);
    });

    testWidgets('includeCalculation: false なら「計算ミス」を出さない', (tester) async {
      await tester.pumpWidget(_app(AnswerFeedbackPanel(
        question: _question(),
        selectedIndex: 0,
        includeCalculation: false,
        onCause: (_) {},
      )));
      expect(find.text('計算ミス'), findsNothing);
      expect(find.text('読み違い'), findsOneWidget);
    });

    testWidgets('別の問題に変わると選択をリセットする', (tester) async {
      Widget panel(String qid) => _app(AnswerFeedbackPanel(
            question: _question(qid: qid),
            selectedIndex: 0,
            onCause: (_) {},
          ));
      await tester.pumpWidget(panel('q1'));
      await tester.tap(find.text('読み違い'));
      await tester.pump();
      expect(find.text(ja.prescriptionMisread), findsOneWidget);

      await tester.pumpWidget(panel('q2'));
      expect(find.text(ja.prescriptionTitle), findsNothing);
    });
  });

  group('WeakSummaryCard', () {
    final now = DateTime(2026, 10, 13, 12);
    ProgressRecord rec(String chapter, DateTime at, WrongCause? cause,
            {bool correct = false}) =>
        ProgressRecord(
          qid: 'q-$chapter-${at.microsecondsSinceEpoch}',
          subjectId: 'math',
          correct: correct,
          at: at,
          topicId: chapter,
          cause: cause,
        );

    final records = [
      rec('ch1', now.subtract(const Duration(days: 10)), null),
      rec('ch1', now.subtract(const Duration(days: 1)), WrongCause.trap),
      rec('ch1', now.subtract(const Duration(days: 1, hours: 1)), WrongCause.trap),
      rec('ch2', now.subtract(const Duration(days: 2)), WrongCause.calculation),
      rec('ch3', now.subtract(const Duration(hours: 3)), null, correct: true),
    ];

    testWidgets('記録が無ければ「弱点なし」の文言', (tester) async {
      await tester.pumpWidget(_app(WeakSummaryCard(records: const [], now: now)));
      expect(find.text(ja.weakTitle), findsOneWidget);
      expect(find.text(ja.weakEmpty), findsOneWidget);
    });

    testWidgets('トップ・原因別・推移を出す', (tester) async {
      await tester.pumpWidget(_app(WeakSummaryCard(
        records: records,
        now: now,
        chapterLabel: (id) => '章$id',
      )));
      expect(find.text(ja.weakTopTitle(2)), findsOneWidget);
      expect(find.text('章ch1'), findsWidgets);
      expect(find.text('章ch2'), findsWidgets);
      expect(find.text('章ch3'), findsNothing);
      expect(find.text(ja.weakCauseTitle), findsOneWidget);
      expect(find.text('ひっかけ'), findsOneWidget);
      expect(find.text('計算ミス'), findsOneWidget);
      expect(find.text(ja.weakTrendTitle), findsOneWidget);
      expect(find.text(ja.weakTrendNote), findsOneWidget);
      expect(find.text(ja.trendWorse), findsWidgets);
    });

    testWidgets('includeCalculation: false なら計算ミスを内訳に出さない', (tester) async {
      await tester.pumpWidget(_app(WeakSummaryCard(
        records: records,
        now: now,
        includeCalculation: false,
      )));
      expect(find.text('計算ミス'), findsNothing);
      expect(find.textContaining('計算ミス:'), findsNothing);
      expect(find.text('ひっかけ'), findsOneWidget);
    });
  });

  test('canShowWeakSummary は premium のときだけ true', () {
    expect(canShowWeakSummary(isPremium: true), isTrue);
    expect(canShowWeakSummary(isPremium: false), isFalse);
  });

  test('内蔵の全言語で文言が空でない', () {
    for (final s in [
      AnswerFeedbackStrings.ja,
      AnswerFeedbackStrings.en,
      AnswerFeedbackStrings.zhHans,
      AnswerFeedbackStrings.zhHant,
      AnswerFeedbackStrings.ko,
    ]) {
      for (final c in WrongCause.values) {
        expect(s.causeLabel(c), isNotEmpty);
      }
      for (final p in WeakPrescription.values) {
        expect(s.prescriptionText(p), isNotEmpty);
      }
      expect(s.weakTopTitle(3), contains('3'));
      expect(s.weakAttempts(5, 2), allOf(contains('5'), contains('2')));
    }
    expect(AnswerFeedbackStrings.forLanguageCode('fr'), same(AnswerFeedbackStrings.ja));
  });
}
