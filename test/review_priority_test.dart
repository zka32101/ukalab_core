import 'package:test/test.dart';
import 'package:ukalab_core/ukalab_core.dart';

ProgressRecord _r(String qid, bool correct, DateTime at) =>
    ProgressRecord(qid: qid, subjectId: 's', correct: correct, at: at);

void main() {
  test('最新の解答が不正解の問題だけを対象にする', () {
    final records = [
      _r('q1', false, DateTime(2026, 1, 1)),
      _r('q2', true, DateTime(2026, 1, 1)),
    ];

    expect(reviewPriorityQids(records), ['q1']);
  });

  test('同じqidを複数回解いた場合は最新の正誤で判定する', () {
    final records = [
      _r('q1', false, DateTime(2026, 1, 1)),
      _r('q1', true, DateTime(2026, 1, 5)), // 後で正解し直した
      _r('q2', true, DateTime(2026, 1, 1)),
      _r('q2', false, DateTime(2026, 1, 5)), // 後で間違えた
    ];

    expect(reviewPriorityQids(records), ['q2']);
  });

  test('不正解のまま放置されている期間が長い順（古い順）に並べる', () {
    final records = [
      _r('q1', false, DateTime(2026, 1, 10)),
      _r('q2', false, DateTime(2026, 1, 1)),
      _r('q3', false, DateTime(2026, 1, 5)),
    ];

    expect(reviewPriorityQids(records), ['q2', 'q3', 'q1']);
  });

  test('記録が0件なら空リストを返す', () {
    expect(reviewPriorityQids([]), isEmpty);
  });

  test('すべて正解していれば空リストを返す', () {
    final records = [
      _r('q1', true, DateTime(2026, 1, 1)),
      _r('q2', true, DateTime(2026, 1, 2)),
    ];

    expect(reviewPriorityQids(records), isEmpty);
  });
}
