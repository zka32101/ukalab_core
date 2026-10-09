import 'package:test/test.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

final now = DateTime(2026, 10, 9, 12);

Question q(
  String qid, {
  String topicId = 'ch1',
  int difficulty = 3,
  bool disabled = false,
}) =>
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
      'difficulty': difficulty,
      if (disabled) 'disabled': true,
    });

ProgressRecord rec(
  String qid,
  bool correct, {
  String? topicId,
  int? ms,
  int daysAgo = 0,
}) =>
    ProgressRecord(
      qid: qid,
      subjectId: 'math',
      correct: correct,
      at: now.subtract(Duration(days: daysAgo)),
      topicId: topicId,
      ms: ms,
    );

void main() {
  group('QuestionTimeEstimator', () {
    test('記録が無ければ問題タイプごとの既定値', () {
      final estimator = QuestionTimeEstimator(const [], [q('a')]);

      expect(estimator.estimateSeconds(q('a')), 45);
    });

    test('同じ問題の回答時間の平均を使う', () {
      final estimator = QuestionTimeEstimator(
        [rec('a', true, ms: 30000), rec('a', true, ms: 50000)],
        [q('a')],
      );

      expect(estimator.estimateSeconds(q('a')), 40);
    });

    test('その問題の記録が無ければ、同じ章の平均を使う', () {
      final estimator = QuestionTimeEstimator(
        [rec('a', true, ms: 20000)],
        [q('a', topicId: 'ch1'), q('b', topicId: 'ch1'), q('c', topicId: 'ch2')],
      );

      expect(estimator.estimateSeconds(q('b', topicId: 'ch1')), 20);
      expect(estimator.estimateSeconds(q('c', topicId: 'ch2')), 45);
    });

    test('10〜900秒に収める', () {
      final estimator = QuestionTimeEstimator(
        [rec('fast', true, ms: 500), rec('slow', true, ms: 2000000)],
        [q('fast'), q('slow')],
      );

      expect(estimator.estimateSeconds(q('fast')), 10);
      expect(estimator.estimateSeconds(q('slow')), 900);
    });
  });

  group('buildTimeBoxedPlan', () {
    final questions = [
      for (var i = 1; i <= 20; i++) q('q${i.toString().padLeft(2, '0')}', difficulty: 1 + i % 3),
    ];

    test('空き時間に収まる問題数にする（選択式は1問45秒の目安）', () {
      final plan = buildTimeBoxedPlan(questions, const [], now: now, minutes: 5);

      expect(plan.budgetSeconds, 300);
      expect(plan.questions.length, 6);
      expect(plan.estimatedSeconds, 270);
      expect(plan.estimatedSeconds <= plan.budgetSeconds, isTrue);
    });

    test('弱点の論点を先に入れる', () {
      final qs = [
        q('x1', topicId: 'weak', difficulty: 5),
        q('x2', topicId: 'weak', difficulty: 5),
        q('e1', topicId: 'easy', difficulty: 1),
        q('e2', topicId: 'easy', difficulty: 1),
      ];

      final plan = buildTimeBoxedPlan(
        qs,
        [rec('x1', false, topicId: 'weak'), rec('x2', false, topicId: 'weak')],
        now: now,
        minutes: 2,
      );

      expect(plan.questions.map((x) => x.qid), ['x1', 'x2']);
    });

    test('firstQids を先頭に入れる', () {
      final plan = buildTimeBoxedPlan(
        questions,
        const [],
        now: now,
        minutes: 2,
        firstQids: ['q20', 'q19'],
      );

      expect(plan.questions.map((x) => x.qid).take(2), ['q20', 'q19']);
    });

    test('収まらない長い問題は飛ばし、後ろの短い問題を入れる', () {
      // 時間の目安は章の平均にも使われるので、長い問題だけ別の章にする。
      final qs = [q('long', topicId: 'chL'), q('s1'), q('s2')];

      final plan = buildTimeBoxedPlan(
        qs,
        [rec('long', true, ms: 590000)],
        now: now,
        minutes: 2,
        firstQids: ['long'],
      );

      // long（590秒）は120秒に収まらないので飛ばし、s1・s2（各45秒）を入れる。
      expect(plan.questions.map((x) => x.qid), ['s1', 's2']);
      expect(plan.estimatedSeconds, 90);
    });

    test('無効な問題は入れない。時間が0分・問題が無ければ空', () {
      final plan = buildTimeBoxedPlan(
        [q('a', disabled: true), q('b')],
        const [],
        now: now,
        minutes: 10,
      );

      expect(plan.questions.map((x) => x.qid), ['b']);
      expect(buildTimeBoxedPlan(questions, const [], now: now, minutes: 0).questions, isEmpty);
      expect(buildTimeBoxedPlan(const [], const [], now: now).questions, isEmpty);
    });

    test('同じ問題を2回入れない', () {
      final plan = buildTimeBoxedPlan(
        questions,
        [rec('q01', false, topicId: 'ch1')],
        now: now,
        minutes: 30,
        firstQids: ['q01'],
      );
      final ids = plan.questions.map((x) => x.qid).toList();

      expect(ids.toSet().length, ids.length);
    });
  });
}
