import 'dart:math';

import '../question/question.dart';

enum PracticeMode { practice, mock, weak }

/// 解答ログ1件。
class AnswerRecord {
  const AnswerRecord({
    required this.qid,
    required this.choiceIndex,
    required this.correct,
    required this.ms,
    required this.at,
    required this.mode,
  });

  final String qid;
  final int choiceIndex;
  final bool correct;
  final int ms;
  final DateTime at;
  final PracticeMode mode;
}

/// 演習1回分。出題順の決定と解答の記録だけを担う（画面・保存は持たない）。
class PracticeSession {
  /// [pool] から [size] 問を選ぶ。無効（disabled）の問題は除く。
  /// [priorityQids]（間隔反復の期限切れなど）は先頭に、与えた順で並べる。
  /// 残りは [seed] で再現可能にシャッフルする。
  PracticeSession({
    required Iterable<Question> pool,
    required this.size,
    this.mode = PracticeMode.practice,
    int seed = 0,
    List<String> priorityQids = const [],
  }) : questions = _pick(pool, size, seed, priorityQids);

  final int size;
  final PracticeMode mode;
  final List<Question> questions;
  final List<AnswerRecord> _records = [];

  static List<Question> _pick(
    Iterable<Question> pool,
    int size,
    int seed,
    List<String> priorityQids,
  ) {
    final active = {
      for (final q in pool)
        if (!q.disabled) q.qid: q,
    };
    final first = [
      for (final id in priorityQids) ?active.remove(id),
    ];
    final rest = active.values.toList()..shuffle(Random(seed));
    return [...first, ...rest].take(size).toList();
  }

  List<AnswerRecord> get records => List.unmodifiable(_records);
  int get index => _records.length;
  bool get finished => index >= questions.length;
  Question? get current => finished ? null : questions[index];
  int get correctCount => _records.where((r) => r.correct).length;

  /// 現在の問題に答える。終了後に呼ぶと [StateError]。
  AnswerRecord answer(int choiceIndex, {int ms = 0, DateTime? at}) {
    final q = current;
    if (q == null) throw StateError('セッションは終了しています');
    final record = AnswerRecord(
      qid: q.qid,
      choiceIndex: choiceIndex,
      correct: choiceIndex == q.answerIndex,
      ms: ms,
      at: at ?? DateTime.now(),
      mode: mode,
    );
    _records.add(record);
    return record;
  }
}
