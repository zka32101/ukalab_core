import 'package:test/test.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

ProgressRecord rec(
  String qid,
  bool correct,
  DateTime at, {
  String? topicId,
  int? ms,
}) =>
    ProgressRecord(
      qid: qid,
      subjectId: 'math',
      correct: correct,
      at: at,
      topicId: topicId,
      ms: ms,
    );

Question q(String qid, String topicId) => Question.fromJson({
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
    });

void main() {
  group('summarizeByDay', () {
    test('日付ごとに解答数・正答数・学習時間をまとめ、古い日付から並べる', () {
      final days = summarizeByDay([
        rec('a', true, DateTime(2026, 10, 9, 20), ms: 30000),
        rec('b', false, DateTime(2026, 10, 8, 9), ms: 20000),
        rec('c', true, DateTime(2026, 10, 9, 8), ms: 90000),
        rec('d', true, DateTime(2026, 10, 9, 9)),
      ]);

      expect(days.map((d) => d.date), [DateTime(2026, 10, 8), DateTime(2026, 10, 9)]);
      expect(days[0].answered, 1);
      expect(days[0].correct, 0);
      expect(days[0].seconds, 20);
      expect(days[1].answered, 3);
      expect(days[1].correct, 3);
      expect(days[1].seconds, 120);
      expect(days[1].accuracy, 1.0);
    });

    test('記録が無ければ空', () {
      expect(summarizeByDay(const []), isEmpty);
    });
  });

  group('summarizeByTopic', () {
    test('章ごとにまとめ、解答数の多い順。旧データは問題データから補う', () {
      final topics = summarizeByTopic(
        [
          rec('a', true, DateTime(2026, 10, 9), topicId: 'ch2'),
          rec('b', false, DateTime(2026, 10, 9), topicId: 'ch2'),
          rec('c', true, DateTime(2026, 10, 9)),
          rec('d', true, DateTime(2026, 10, 9), topicId: 'ch1'),
          rec('zz', true, DateTime(2026, 10, 9)),
        ],
        questions: [q('c', 'ch1')],
      );

      expect(topics.map((t) => t.topicId), ['ch1', 'ch2']);
      expect(topics[0].answered, 2);
      expect(topics[0].correct, 2);
      expect(topics[1].answered, 2);
      expect(topics[1].accuracy, 0.5);
    });
  });

  group('CSV', () {
    test('日付ごとの CSV: ヘッダー・日付の書式・小数1桁', () {
      final csv = dailySummaryCsv([
        DailyStudySummary(date: DateTime(2026, 10, 9), answered: 3, correct: 2, seconds: 150),
      ]);

      expect(csv, '日付,解答数,正答数,正答率(%),学習時間(分)\n2026-10-09,3,2,66.7,2.5\n');
    });

    test('分野ごとの CSV', () {
      final csv = topicAccuracyCsv([
        const TopicAccuracy(topicId: 'ch1', answered: 4, correct: 3),
      ]);

      expect(csv, '分野,解答数,正答数,正答率(%)\nch1,4,3,75.0\n');
    });

    test('カンマ・引用符・改行を含む分野名は引用符で囲む', () {
      final csv = topicAccuracyCsv([
        const TopicAccuracy(topicId: 'a,"b"', answered: 1, correct: 1),
      ]);

      expect(csv, '分野,解答数,正答数,正答率(%)\n"a,""b""",1,1,100.0\n');
    });

    test('記録が無ければヘッダーのみ。個人情報の列は無い', () {
      final csv = dailySummaryCsv(const []);

      expect(csv, '日付,解答数,正答数,正答率(%),学習時間(分)\n');
      expect(csv.contains('qid'), isFalse);
      expect(csv.contains('uid'), isFalse);
    });
  });
}
