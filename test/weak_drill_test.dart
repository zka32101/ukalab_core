import 'package:test/test.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

final now = DateTime(2026, 10, 9, 12);

Question q(
  String qid, {
  String topicId = 'ch1',
  String? subtopicId,
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
      if (subtopicId != null) 'subtopicId': subtopicId,
      if (disabled) 'disabled': true,
    });

ProgressRecord rec(
  String qid,
  bool correct, {
  String? topicId,
  String? subtopicId,
  int? ms,
  WrongCause? cause,
  Duration ago = Duration.zero,
}) =>
    ProgressRecord(
      qid: qid,
      subjectId: 'math',
      correct: correct,
      at: now.subtract(ago),
      topicId: topicId,
      subtopicId: subtopicId,
      ms: ms,
      cause: cause,
    );

void main() {
  group('computeWeakTopics', () {
    test('誤答が多い論点ほど弱い。全問正解の論点は含めない', () {
      final topics = computeWeakTopics(
        [
          rec('a1', false, topicId: 'A'),
          rec('a2', false, topicId: 'A'),
          rec('a3', false, topicId: 'A'),
          rec('b1', true, topicId: 'B'),
          rec('b2', true, topicId: 'B'),
          rec('c1', false, topicId: 'C'),
          rec('c2', true, topicId: 'C'),
          rec('c3', true, topicId: 'C'),
        ],
        now: now,
      );

      expect(topics.map((t) => t.chapterId), ['A', 'C']);
      expect(topics[0].score, closeTo(0.75, 1e-9));
      expect(topics[1].score, closeTo(0.25, 1e-9));
      expect(topics[0].attempts, 3);
      expect(topics[0].misses, 3);
    });

    test('古い解答ほど軽い（半減期14日）', () {
      final topics = computeWeakTopics(
        [rec('a1', false, topicId: 'A', ago: const Duration(days: 14))],
        now: now,
      );

      expect(topics.single.score, closeTo(0.5 / 1.5, 1e-9));
    });

    test('遅い正解は弱点の候補に入る', () {
      final topics = computeWeakTopics(
        [rec('a1', true, topicId: 'A', ms: 25000)],
        now: now,
      );

      expect(topics.single.score, closeTo(0.25, 1e-9));
      expect(topics.single.misses, 0);
    });

    test('細目ごとに分け、byChapter なら章にまとめる', () {
      final records = [
        rec('a1', false, topicId: 'A', subtopicId: 'x'),
        rec('a2', false, topicId: 'A', subtopicId: 'y'),
      ];

      final bySub = computeWeakTopics(records, now: now);
      final byChapter = computeWeakTopics(records, now: now, byChapter: true);

      expect(bySub.map((t) => t.key).toSet(), {'A/x', 'A/y'});
      expect(byChapter.single.key, 'A');
      expect(byChapter.single.attempts, 2);
    });

    test('記録に論点が無い旧データは問題データから補う。補えなければ数えない', () {
      final topics = computeWeakTopics(
        [rec('a1', false), rec('zz', false)],
        now: now,
        questions: [q('a1', topicId: 'A', subtopicId: 'x')],
      );

      expect(topics.single.key, 'A/x');
    });

    test('誤答の原因の内訳と、最も多い原因・処方', () {
      final topic = computeWeakTopics(
        [
          rec('a1', false, topicId: 'A', cause: WrongCause.trap),
          rec('a2', false, topicId: 'A', cause: WrongCause.trap),
          rec('a3', false, topicId: 'A', cause: WrongCause.knowledge),
          rec('a4', false, topicId: 'A'),
        ],
        now: now,
      ).single;

      expect(topic.causeCounts, {WrongCause.trap: 2, WrongCause.knowledge: 1});
      expect(topic.dominantCause, WrongCause.trap);
      expect(topic.prescription, WeakPrescription.compareFirst);
    });

    test('原因ラベルが無ければ処方は null', () {
      final topic = computeWeakTopics(
        [rec('a1', false, topicId: 'A')],
        now: now,
      ).single;

      expect(topic.dominantCause, isNull);
      expect(topic.prescription, isNull);
    });

    test('原因ごとの処方', () {
      expect(prescriptionFor(WrongCause.knowledge), WeakPrescription.studyExplanation);
      expect(prescriptionFor(WrongCause.calculation), WeakPrescription.calculationSteps);
      expect(prescriptionFor(WrongCause.misread), WeakPrescription.markKeyPoints);
    });
  });

  group('buildWeakDrill', () {
    final questions = [
      q('a-hard', topicId: 'A', difficulty: 5),
      q('a-easy', topicId: 'A', difficulty: 1),
      q('a-off', topicId: 'A', difficulty: 2, disabled: true),
      q('b-mid', topicId: 'B', difficulty: 3),
      q('c-easy', topicId: 'C', difficulty: 1),
    ];

    test('弱い論点から、やさしい問題 → 難しい問題の順に出す。無効な問題は出さない', () {
      final drill = buildWeakDrill(
        questions,
        [
          rec('a1', false, topicId: 'A'),
          rec('a2', false, topicId: 'A'),
          rec('b1', false, topicId: 'B'),
        ],
        now: now,
      );

      expect(drill.map((x) => x.qid), ['a-easy', 'b-mid', 'a-hard']);
    });

    test('size と topicLimit で絞る', () {
      final records = [
        rec('a1', false, topicId: 'A'),
        rec('a2', false, topicId: 'A'),
        rec('b1', false, topicId: 'B'),
      ];

      expect(buildWeakDrill(questions, records, now: now, size: 1).length, 1);
      expect(
        buildWeakDrill(questions, records, now: now, topicLimit: 1).map((x) => x.qid),
        ['a-easy', 'a-hard'],
      );
    });

    test('細目つきの弱点は同じ細目の問題だけを出す', () {
      final qs = [
        q('x1', topicId: 'A', subtopicId: 'x'),
        q('y1', topicId: 'A', subtopicId: 'y'),
      ];

      final drill = buildWeakDrill(
        qs,
        [rec('x1', false, topicId: 'A', subtopicId: 'x')],
        now: now,
      );

      expect(drill.map((x) => x.qid), ['x1']);
    });

    test('弱点が無ければ空', () {
      expect(
        buildWeakDrill(questions, [rec('a1', true, topicId: 'A')], now: now),
        isEmpty,
      );
      expect(buildWeakDrill(questions, const [], now: now), isEmpty);
    });
  });
}
