import 'package:test/test.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

Question q(String qid, {List<String> compareWith = const [], String topicId = 'ch1'}) =>
    Question.fromJson({
      'qid': qid,
      'examId': 'sample',
      'subjectId': 'math',
      'topicId': topicId,
      'prompt': '問題',
      'choices': ['a', 'b'],
      'answerIndex': 0,
      'explanation': '解説',
      'source': 'original',
      'sourceRef': '自作',
      'contentVer': '1',
      if (compareWith.isNotEmpty) 'compareWith': compareWith,
    });

Term term(
  String id, {
  List<String> relatedQuestionIds = const [],
  String headline = 'ひとこと',
  String? commonMistake,
  bool disabled = false,
}) =>
    Term(
      termId: id,
      examId: 'sample',
      term: id,
      headline: headline,
      definition: '定義',
      source: QuestionSource.original,
      sourceRef: '自作',
      contentVer: '1',
      relatedQuestionIds: relatedQuestionIds,
      commonMistake: commonMistake,
      disabled: disabled,
    );

ProgressRecord rec(String topicId, bool correct, DateTime at) => ProgressRecord(
      qid: 'x',
      subjectId: 'math',
      correct: correct,
      at: at,
      topicId: topicId,
    );

void main() {
  group('buildComparison', () {
    final terms = [
      term('t-answer', relatedQuestionIds: ['q1'], headline: '答え', commonMistake: '相手と取り違えやすい'),
      term('t-rival', headline: '相手'),
      term('t-off', disabled: true),
    ];

    test('答えの用語を先に、紛らわしい相手を後に並べる。無効・未定義・重複は除く', () {
      final view = buildComparison(
        q('q1', compareWith: ['t-rival', 't-off', 't-missing', 't-answer']),
        terms,
      );

      expect(view!.rows.map((r) => r.term.termId), ['t-answer', 't-rival']);
      expect(view.rows.map((r) => r.isAnswer), [true, false]);
    });

    test('違いの1行は、よくある間違いがあればそれ、無ければひとこと', () {
      final view = buildComparison(q('q1', compareWith: ['t-rival']), terms)!;

      expect(view.rows[0].differenceLine, '相手と取り違えやすい');
      expect(view.rows[1].differenceLine, '相手');
    });

    test('並べる用語が2つに満たなければ null', () {
      expect(buildComparison(q('q1'), terms), isNull);
      expect(buildComparison(q('q1', compareWith: ['t-off']), terms), isNull);
      expect(buildComparison(q('q9', compareWith: ['t-rival']), terms), isNull);
    });
  });

  group('weeklyWeakTop', () {
    final now = DateTime(2026, 10, 16, 12);

    test('今週の解答だけで数え、弱い順に limit 件まで', () {
      final records = [
        rec('A', false, now.subtract(const Duration(days: 20))),
        rec('B', false, now.subtract(const Duration(days: 1))),
        rec('C', false, now),
        rec('C', false, now),
      ];

      expect(weeklyWeakTop(records, now: now).map((t) => t.chapterId), ['C', 'B']);
      expect(weeklyWeakTop(records, now: now, limit: 1).map((t) => t.chapterId), ['C']);
    });

    test('未来の記録・弱点が無い章は含めない', () {
      final records = [
        rec('A', true, now),
        rec('B', false, now.add(const Duration(days: 1))),
      ];

      expect(weeklyWeakTop(records, now: now), isEmpty);
    });
  });

  group('weakTrend', () {
    final now = DateTime(2026, 10, 16, 12);

    test('弱点が減った章は改善、増えた章は悪化。改善が大きい順', () {
      final records = [
        // A: 1週間前は誤答ばかり → 今は正解し直した
        for (var i = 0; i < 3; i++) rec('A', false, DateTime(2026, 10, 6, 12)),
        for (var i = 0; i < 3; i++) rec('A', true, now),
        // B: 今週になって誤答が出た
        rec('B', false, now),
      ];

      final trends = weakTrend(records, now: now);

      expect(trends.map((t) => t.chapterId), ['A', 'B']);
      expect(trends[0].improved, isTrue);
      expect(trends[0].currentScore < trends[0].previousScore, isTrue);
      expect(trends[1].improved, isFalse);
      expect(trends[1].previousScore, 0);
      expect(trends[1].currentScore > 0, isTrue);
      expect(trends[1].delta > 0, isTrue);
    });

    test('記録が無ければ空', () {
      expect(weakTrend(const [], now: now), isEmpty);
    });
  });
}
