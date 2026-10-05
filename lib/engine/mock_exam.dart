import 'dart:math';

import '../config/exam_config.dart';
import '../question/question.dart';
import 'journal_judge.dart';
import 'ledger_judge.dart';
import 'worksheet_judge.dart';

/// 得点と満点。
class ScoreLine {
  const ScoreLine(this.score, this.max);

  final int score;
  final int max;

  /// 得点率（%）。満点が0なら0。
  double get pct => max == 0 ? 0 : score * 100 / max;
}

/// 模擬試験の結果。
class MockExamResult {
  const MockExamResult({
    required this.total,
    required this.bySubject,
    required this.passed,
    required this.shortBy,
    required this.subjectShortfalls,
  });

  final ScoreLine total;
  final Map<String, ScoreLine> bySubject;
  final bool passed;

  /// 総合の合格ラインまであと何点か（到達済みなら0）。「あと◯点」表示用。
  final int shortBy;

  /// 足切りに満たない科目と、その最低点まであと何点か。
  final Map<String, int> subjectShortfalls;

  /// 総合は届いているが足切りで不合格か。
  bool get failedBySubjectCutoff => !passed && shortBy == 0;
}

/// 必要得点（得点率 pct を満たす最小の整数点）。
int requiredScore(double pct, int max) => (pct * max / 100 - 1e-9).ceil();

/// 模擬試験の出題を選ぶ。無効（disabled）の問題は除く。
///
/// [level.subjectQuestionCounts] があれば科目ごとにその数だけ抽出する
/// （出題順は指定した科目の順。各科目の問題が足りない分はそのまま不足する）。
/// 無ければ全体から [level.questionCount] 問を抽出する。
List<Question> pickMockExamQuestions({
  required Iterable<Question> pool,
  required LevelConfig level,
  int seed = 0,
}) {
  final active = pool.where((q) => !q.disabled).toList();
  final counts = level.subjectQuestionCounts;
  if (counts == null) {
    return (List<Question>.from(active)..shuffle(Random(seed)))
        .take(level.questionCount)
        .toList();
  }
  final result = <Question>[];
  var salt = 0;
  for (final entry in counts.entries) {
    final subjectPool = active.where((q) => q.subjectId == entry.key).toList()
      ..shuffle(Random(seed + salt));
    result.addAll(subjectPool.take(entry.value));
    salt++;
  }
  return result;
}

bool _isCorrect(Question q, Object? answer) {
  switch (q.type) {
    case QuestionType.choice:
      return answer is int && answer == q.answerIndex;
    case QuestionType.journal:
      final expected = q.journalAnswer;
      if (expected == null || answer is! List<JournalLine>) return false;
      return judgeJournal(expected, answer).isCorrect;
    case QuestionType.worksheet:
      final expected = q.worksheetAnswer;
      if (expected == null || answer is! List<WorksheetCell>) return false;
      return judgeWorksheet(expected, answer).isCorrect;
    case QuestionType.ledger:
      final expected = q.ledgerAnswer;
      if (expected == null || answer is! List<LedgerCell>) return false;
      return judgeLedger(expected, answer).isCorrect;
  }
}

/// 模擬試験を採点して合否を判定する。
///
/// [answers] は qid → 回答。choice型は選んだ選択肢の番号（int）、journal型は
/// 入力した仕訳の行（`List<JournalLine>`）、worksheet型は入力したセル
/// （`List<WorksheetCell>`）。未回答は null・型違い・欠落のいずれも
/// 不正解扱い。科目別の最低得点率は、出題が1問以上ある科目にだけ適用する。
MockExamResult scoreMockExam({
  required List<Question> questions,
  required Map<String, Object?> answers,
  required PassRule rule,
}) {
  final subjectScore = <String, int>{};
  final subjectMax = <String, int>{};
  var score = 0;
  var max = 0;

  for (final q in questions) {
    max += q.points;
    subjectMax[q.subjectId] = (subjectMax[q.subjectId] ?? 0) + q.points;
    final correct = _isCorrect(q, answers[q.qid]);
    final got = correct ? q.points : 0;
    score += got;
    subjectScore[q.subjectId] = (subjectScore[q.subjectId] ?? 0) + got;
  }

  final bySubject = {
    for (final id in subjectMax.keys)
      id: ScoreLine(subjectScore[id] ?? 0, subjectMax[id]!),
  };

  final shortBy = max == 0
      ? 0
      : (requiredScore(rule.totalPct, max) - score).clamp(0, max);

  final shortfalls = <String, int>{};
  final cutoff = rule.subjectMinPct;
  if (cutoff != null) {
    bySubject.forEach((id, line) {
      final need = requiredScore(cutoff, line.max) - line.score;
      if (need > 0) shortfalls[id] = need;
    });
  }

  return MockExamResult(
    total: ScoreLine(score, max),
    bySubject: bySubject,
    passed: max > 0 && shortBy == 0 && shortfalls.isEmpty,
    shortBy: shortBy,
    subjectShortfalls: shortfalls,
  );
}
