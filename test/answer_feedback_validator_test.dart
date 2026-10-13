import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ukalab_core.dart';

Question _q(String qid, {String topic = 'ch1', String? sub, List<String>? compare}) =>
    Question.fromJson({
      'qid': qid,
      'examId': 'sample',
      'subjectId': 'math',
      'topicId': topic,
      if (sub != null) 'subtopicId': sub,
      'prompt': '問題',
      'choices': ['a', 'b'],
      'answerIndex': 0,
      'explanation': '解説',
      'source': 'original',
      'sourceRef': '自作',
      'contentVer': '1',
      if (compare != null) 'compareWith': compare,
    });

Term _t(String id, {List<String> related = const []}) => Term.fromJson({
      'termId': id,
      'examId': 'sample',
      'term': id,
      'headline': 'h',
      'definition': 'd',
      'relatedQuestionIds': related,
      'source': 'original',
      'sourceRef': '自作',
      'contentVer': '1',
    });

List<String> _codes(List<ContentIssue> issues) => [for (final i in issues) i.code];

void main() {
  group('validateAnswerFeedbackTags', () {
    test('問題が無ければ指摘なし', () {
      expect(validateAnswerFeedbackTags(const []), isEmpty);
    });

    test('正しいタグは指摘なし', () {
      final qs = [
        _q('q1', sub: 'a', compare: ['t2']),
        _q('q2', sub: 'a'),
      ];
      final terms = [_t('t1', related: ['q1']), _t('t2')];
      expect(validateAnswerFeedbackTags(qs, terms: terms), isEmpty);
    });

    test('同じ細目IDが複数の章にあると subtopic-conflict', () {
      final issues = validateAnswerFeedbackTags([
        _q('q1', topic: 'ch1', sub: 'x'),
        _q('q2', topic: 'ch2', sub: 'x'),
        _q('q3', topic: 'ch1', sub: 'y'),
      ]);
      expect(_codes(issues), ['subtopic-conflict', 'subtopic-conflict']);
      expect(issues.map((i) => i.qid), ['q1', 'q2']);
    });

    test('比較対象が答えの用語自身だと compare-self', () {
      final issues = validateAnswerFeedbackTags(
        [_q('q1', compare: ['t1', 't2'])],
        terms: [_t('t1', related: ['q1']), _t('t2')],
      );
      expect(_codes(issues), ['compare-self']);
    });

    test('比較表示が作れないタグは compare-no-view', () {
      final issues = validateAnswerFeedbackTags(
        [_q('q1', compare: ['t2'])],
        terms: [_t('t2')],
      );
      expect(_codes(issues), ['compare-no-view']);
    });

    test('比較対象が2つ以上あれば答えの用語が無くても表示できる', () {
      expect(
        validateAnswerFeedbackTags(
          [_q('q1', compare: ['t1', 't2'])],
          terms: [_t('t1'), _t('t2')],
        ),
        isEmpty,
      );
    });

    test('用語が空のときは用語を使う検査をしない', () {
      expect(validateAnswerFeedbackTags([_q('q1', compare: ['t2'])]), isEmpty);
    });
  });

  group('既存の検査との組み合わせ（空・重複・存在しない参照）', () {
    test('比較対象の空・重複・未定義は validateCompareTargets が検出する', () {
      final issues = validateCompareTargets(
        [_q('q1', compare: ['t1', 't1', '', 'zzz'])],
        ['t1'],
      );
      expect(_codes(issues), ['compare-duplicate', 'compare-empty', 'compare-unknown']);
    });

    test('用語の relatedQuestionIds が存在しない qid だと validateTerms が検出する', () {
      final issues = validateTerms([_t('t1', related: ['nope'])], questions: [_q('q1')]);
      expect(_codes(issues), contains('unknown-related-question'));
    });
  });
}
