import 'package:test/test.dart';
import 'package:ukalab_core/ukalab_core.dart';

final now = DateTime(2026, 10, 9, 23, 30);

Question q(
  String qid, {
  List<String> tags = const [],
  bool disabled = false,
}) =>
    Question.fromJson({
      'qid': qid,
      'examId': 'sample',
      'subjectId': 'math',
      'topicId': 'ch1',
      'prompt': '問題',
      'choices': ['a', 'b'],
      'answerIndex': 0,
      'explanation': '解説',
      'source': 'original',
      'sourceRef': '自作',
      'contentVer': '1',
      if (tags.isNotEmpty) 'tags': tags,
      if (disabled) 'disabled': true,
    });

ProgressRecord rec(String qid, bool correct, {int daysAgo = 0}) => ProgressRecord(
      qid: qid,
      subjectId: 'math',
      correct: correct,
      at: now.subtract(Duration(days: daysAgo)),
    );

void main() {
  group('nextExamDate / examEveStatus', () {
    test('今日以降で最も近い試験日を選ぶ。過去の日付は無視する', () {
      final next = nextExamDate(
        [DateTime(2026, 10, 1), DateTime(2026, 12, 6), DateTime(2026, 10, 20)],
        now,
      );

      expect(next, DateTime(2026, 10, 20));
    });

    test('試験当日も対象。今日以降の試験日が無ければ null', () {
      expect(nextExamDate([DateTime(2026, 10, 9, 8)], now), DateTime(2026, 10, 9));
      expect(nextExamDate([DateTime(2026, 10, 8)], now), isNull);
      expect(nextExamDate(const [], now), isNull);
      expect(examEveStatus(const [], now), isNull);
    });

    test('試験日の3日前から直前モード（時刻は無視して日付で数える）', () {
      expect(examEveStatus([DateTime(2026, 10, 12)], now)!.daysLeft, 3);
      expect(examEveStatus([DateTime(2026, 10, 12)], now)!.active, isTrue);
      expect(examEveStatus([DateTime(2026, 10, 13)], now)!.active, isFalse);
      expect(examEveStatus([DateTime(2026, 10, 9)], now)!.daysLeft, 0);
      expect(examEveStatus([DateTime(2026, 10, 9)], now)!.active, isTrue);
      expect(examEveStatus([DateTime(2026, 10, 10)], now)!.daysLeft, 1);
    });

    test('windowDays を変えられる', () {
      expect(examEveStatus([DateTime(2026, 10, 14)], now, windowDays: 7)!.active, isTrue);
    });
  });

  group('buildExamEveSet', () {
    final questions = [
      q('q-wrong'),
      q('q-old-wrong'),
      q('q-freq', tags: [QuestionTag.frequent]),
      q('q-formula', tags: [QuestionTag.formula]),
      q('q-both', tags: [QuestionTag.frequent, QuestionTag.formula]),
      q('q-plain'),
      q('q-off', tags: [QuestionTag.frequent], disabled: true),
    ];
    final records = [
      rec('q-wrong', false, daysAgo: 2),
      rec('q-old-wrong', false, daysAgo: 30),
    ];

    test('直近の誤答・頻出・計算式だけを、優先度の高い順に出す', () {
      final set = buildExamEveSet(questions, records, now: now);

      expect(
        set.map((i) => i.question.qid),
        ['q-wrong', 'q-both', 'q-freq', 'q-formula'],
      );
    });

    test('出す理由を持つ（直近の誤答・頻出・計算式）', () {
      final set = buildExamEveSet(questions, records, now: now);
      final byQid = {for (final i in set) i.question.qid: i.reasons};

      expect(byQid['q-wrong'], [ExamEveReason.recentWrong]);
      expect(byQid['q-both'], [ExamEveReason.frequent, ExamEveReason.formula]);
    });

    test('古い誤答（recentDays 超）・無効な問題・理由のない問題は出さない', () {
      final ids = buildExamEveSet(questions, records, now: now).map((i) => i.question.qid);

      expect(ids, isNot(contains('q-old-wrong')));
      expect(ids, isNot(contains('q-off')));
      expect(ids, isNot(contains('q-plain')));
    });

    test('正解し直した問題は直近の誤答に数えない', () {
      final set = buildExamEveSet(
        questions,
        [rec('q-wrong', false, daysAgo: 2), rec('q-wrong', true, daysAgo: 1)],
        now: now,
      );

      expect(set.map((i) => i.question.qid), isNot(contains('q-wrong')));
    });

    test('size で絞る', () {
      expect(buildExamEveSet(questions, records, now: now, size: 2).length, 2);
      expect(buildExamEveSet(questions, records, now: now, size: 0), isEmpty);
    });
  });

  group('Question.tags', () {
    test('読み書きできる。無ければ空でキーを出さない', () {
      final tagged = q('q1', tags: [QuestionTag.frequent]);

      expect(Question.fromJson(tagged.toJson()).tags, ['frequent']);
      expect(q('q2').tags, isEmpty);
      expect(q('q2').toJson().containsKey('tags'), isFalse);
    });
  });

  group('PremiumFeature', () {
    test('premium でなければ使えない', () {
      for (final f in PremiumFeature.values) {
        expect(canUsePremiumFeature(f, isPremium: false), isFalse);
        expect(canUsePremiumFeature(f, isPremium: true), isTrue);
      }
    });
  });
}
