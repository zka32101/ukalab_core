import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ukalab_core.dart';

ProgressRecord _rec(String qid, DateTime at,
        {bool correct = false, WrongCause? cause, String chapter = 'ch1'}) =>
    ProgressRecord(
      qid: qid,
      subjectId: 's',
      correct: correct,
      at: at,
      topicId: chapter,
      cause: cause,
    );

void main() {
  final now = DateTime(2026, 10, 13, 12);

  group('buildWeakSummary', () {
    test('記録が無ければ空', () {
      final s = buildWeakSummary(const [], now: now);
      expect(s.isEmpty, isTrue);
      expect(s.answered, 0);
      expect(s.causeCounts, isEmpty);
    });

    test('今週の解答だけを数え、原因ラベル別に集計する', () {
      final s = buildWeakSummary([
        _rec('a', now.subtract(const Duration(days: 1)), cause: WrongCause.trap),
        _rec('b', now.subtract(const Duration(days: 2)), cause: WrongCause.trap),
        _rec('c', now.subtract(const Duration(days: 3)), cause: WrongCause.misread),
        _rec('d', now.subtract(const Duration(days: 3))),
        _rec('e', now.subtract(const Duration(days: 4)), correct: true),
        _rec('old', now.subtract(const Duration(days: 20)), cause: WrongCause.knowledge),
      ], now: now);
      expect(s.answered, 5);
      expect(s.missed, 4);
      expect(s.causeCounts, {WrongCause.trap: 2, WrongCause.misread: 1});
      expect(s.top.single.chapterId, 'ch1');
    });

    test('limit で件数を絞り、弱い順に並ぶ', () {
      final s = buildWeakSummary([
        _rec('a', now.subtract(const Duration(days: 1)), chapter: 'c1'),
        _rec('b', now.subtract(const Duration(days: 1)), chapter: 'c2'),
        _rec('c', now.subtract(const Duration(days: 1)), chapter: 'c2'),
        _rec('d', now.subtract(const Duration(days: 1)), chapter: 'c3'),
      ], now: now, limit: 2);
      expect(s.top.length, 2);
      expect(s.top.first.chapterId, 'c2');
    });

    test('推移は先週より悪化した章を正の差で返す', () {
      final s = buildWeakSummary([
        _rec('a', now.subtract(const Duration(days: 1))),
        _rec('b', now.subtract(const Duration(days: 1))),
      ], now: now);
      final t = s.trends.single;
      expect(t.previousScore, 0);
      expect(t.currentScore, greaterThan(0));
      expect(t.improved, isFalse);
    });
  });

  group('attachCauseToLatest', () {
    test('その問題の最新の誤答に原因を付ける（元のリストは変えない）', () {
      final first = _rec('q1', DateTime(2026, 10, 1));
      final second = _rec('q1', DateTime(2026, 10, 2));
      final other = _rec('q2', DateTime(2026, 10, 3));
      final records = [first, second, other];

      final next = attachCauseToLatest(records, 'q1', WrongCause.trap);
      expect(next[0].cause, isNull);
      expect(next[1].cause, WrongCause.trap);
      expect(next[1].at, second.at);
      expect(next[2], other);
      expect(records[1].cause, isNull);

      final cleared = attachCauseToLatest(next, 'q1', null);
      expect(cleared[1].cause, isNull);
    });

    test('正解の記録や該当なしは変えない', () {
      final ok = _rec('q1', DateTime(2026, 10, 1), correct: true);
      final records = [ok];
      expect(attachCauseToLatest(records, 'q1', WrongCause.trap), same(records));
      expect(attachCauseToLatest(records, 'zzz', WrongCause.trap), same(records));
    });
  });
}
