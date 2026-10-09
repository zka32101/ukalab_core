import 'package:test/test.dart';
import 'package:ukalab_core/ukalab_core.dart';

Map<String, dynamic> questionJson({
  String qid = 'q1',
  Object? compareWith,
  Object? subtopicId,
}) =>
    {
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
      if (compareWith != null) 'compareWith': compareWith,
      if (subtopicId != null) 'subtopicId': subtopicId,
    };

void main() {
  group('Question の論点タグ（細目）と比較対象', () {
    test('細目と比較対象を読み書きできる', () {
      final q = Question.fromJson(
        questionJson(compareWith: ['t1', 't2'], subtopicId: 'ch1-a'),
      );

      expect(q.topicId, 'ch1');
      expect(q.subtopicId, 'ch1-a');
      expect(q.compareWith, ['t1', 't2']);
      expect(Question.fromJson(q.toJson()).compareWith, ['t1', 't2']);
      expect(Question.fromJson(q.toJson()).subtopicId, 'ch1-a');
    });

    test('無い場合は細目 null・比較対象は空で、toJson にキーを出さない', () {
      final q = Question.fromJson(questionJson());

      expect(q.subtopicId, isNull);
      expect(q.compareWith, isEmpty);
      expect(q.toJson().containsKey('subtopicId'), isFalse);
      expect(q.toJson().containsKey('compareWith'), isFalse);
    });

    test('compareWith が文字列の配列でないと読み込みエラー', () {
      expect(
        () => Question.fromJson(questionJson(compareWith: 'oops')),
        throwsFormatException,
      );
      expect(
        () => Question.fromJson(questionJson(compareWith: [1, 2])),
        throwsFormatException,
      );
    });
  });

  group('validateCompareTargets', () {
    Question q(String qid, List<String> compareWith) =>
        Question.fromJson(questionJson(qid: qid, compareWith: compareWith));

    test('すべて存在すれば問題なし', () {
      expect(validateCompareTargets([q('q1', ['t1', 't2'])], ['t1', 't2', 't3']), isEmpty);
    });

    test('比較対象が無い問題は検査対象外', () {
      expect(validateCompareTargets([q('q1', [])], const []), isEmpty);
    });

    test('存在しないID・重複・空のIDを検出する', () {
      final issues = validateCompareTargets(
        [
          q('q1', ['t9']),
          q('q2', ['t1', 't1']),
          q('q3', [' ']),
        ],
        ['t1'],
      );

      expect(issues.map((i) => i.code), ['compare-unknown', 'compare-duplicate', 'compare-empty']);
      expect(issues.map((i) => i.qid), ['q1', 'q2', 'q3']);
    });
  });
}
