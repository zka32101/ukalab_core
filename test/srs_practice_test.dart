import 'package:test/test.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

Question q(String qid, {bool disabled = false}) => Question(
      qid: qid,
      examId: 'sample',
      subjectId: 'math',
      topicId: 't',
      prompt: 'p',
      choices: const ['a', 'b', 'c'],
      answerIndex: 1,
      explanation: 'e',
      source: QuestionSource.original,
      sourceRef: '自作',
      contentVer: '1',
      disabled: disabled,
    );

void main() {
  final now = DateTime(2026, 10, 2, 9);

  group('Srs', () {
    test('初回正解は箱1、1日後に復習', () {
      final item = Srs.review(null, qid: 'a', correct: true, now: now);
      expect(item.box, 1);
      expect(item.dueAt, now.add(const Duration(days: 1)));
    });

    test('正解を重ねると箱が上がり、最大で止まる', () {
      SrsItem? item;
      for (var i = 0; i < 10; i++) {
        item = Srs.review(item, qid: 'a', correct: true, now: now);
      }
      expect(item!.box, Srs.maxBox);
      expect(item.dueAt, now.add(const Duration(days: 30)));
    });

    test('不正解は箱0に戻り、すぐ再出題の対象', () {
      final high = Srs.review(
        SrsItem(qid: 'a', box: 4, dueAt: DateTime(2026, 11)),
        qid: 'a',
        correct: false,
        now: now,
      );
      expect(high.box, 0);
      expect(high.dueAt, now);
    });

    test('due は期限切れだけを、古い順・同じなら低い箱の順に返す', () {
      final items = [
        SrsItem(qid: 'future', box: 1, dueAt: now.add(const Duration(days: 1))),
        SrsItem(qid: 'old-high', box: 3, dueAt: now.subtract(const Duration(days: 2))),
        SrsItem(qid: 'same-high', box: 2, dueAt: now),
        SrsItem(qid: 'same-low', box: 0, dueAt: now),
      ];
      expect(Srs.due(items, now).map((i) => i.qid),
          ['old-high', 'same-low', 'same-high']);
      expect(Srs.due(items, now, limit: 2).map((i) => i.qid),
          ['old-high', 'same-low']);
    });

    test('JSON の往復', () {
      final item = Srs.review(null, qid: 'a', correct: true, now: now);
      final again = SrsItem.fromJson(item.toJson());
      expect((again.qid, again.box, again.dueAt), (item.qid, item.box, item.dueAt));
    });
  });

  group('PracticeSession', () {
    final pool = [for (var i = 0; i < 20; i++) q('q$i')];

    test('同じ seed なら同じ出題順（再現可能）', () {
      final a = PracticeSession(pool: pool, size: 10, seed: 42);
      final b = PracticeSession(pool: pool, size: 10, seed: 42);
      final c = PracticeSession(pool: pool, size: 10, seed: 43);
      expect(a.questions.map((x) => x.qid), b.questions.map((x) => x.qid));
      expect(a.questions.map((x) => x.qid),
          isNot(c.questions.map((x) => x.qid)));
      expect(a.questions, hasLength(10));
    });

    test('無効な問題は出ない', () {
      final s = PracticeSession(
        pool: [q('ok'), q('off', disabled: true)],
        size: 10,
      );
      expect(s.questions.map((x) => x.qid), ['ok']);
    });

    test('優先問題は先頭に、指定順で並ぶ（無効・存在しないものは無視）', () {
      final s = PracticeSession(
        pool: [...pool, q('off', disabled: true)],
        size: 5,
        seed: 1,
        priorityQids: ['q7', 'off', 'nope', 'q3'],
      );
      expect(s.questions.take(2).map((x) => x.qid), ['q7', 'q3']);
      expect(s.questions.map((x) => x.qid).toSet(), hasLength(5));
    });

    test('解答の記録と正答数、終了後の解答はエラー', () {
      final s = PracticeSession(pool: [q('a'), q('b')], size: 2, mode: PracticeMode.weak);
      expect(s.finished, isFalse);
      final first = s.answer(1, ms: 800, at: now); // 正解=1
      expect(first.correct, isTrue);
      expect(first.mode, PracticeMode.weak);
      expect(s.answer(0).correct, isFalse);
      expect(s.finished, isTrue);
      expect(s.current, isNull);
      expect(s.correctCount, 1);
      expect(s.records, hasLength(2));
      expect(() => s.answer(1), throwsStateError);
    });

    test('プールより大きい size でも落ちない', () {
      expect(PracticeSession(pool: [q('a')], size: 10).questions, hasLength(1));
    });
  });
}
