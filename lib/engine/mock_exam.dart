import '../config/exam_config.dart';
import '../question/question.dart';

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

/// 模擬試験を採点して合否を判定する。
///
/// [answers] は qid → 選んだ選択肢の番号。未回答は null または欠落（不正解扱い）。
/// 科目別の最低得点率は、出題が1問以上ある科目にだけ適用する。
MockExamResult scoreMockExam({
  required List<Question> questions,
  required Map<String, int?> answers,
  required PassRule rule,
}) {
  final subjectScore = <String, int>{};
  final subjectMax = <String, int>{};
  var score = 0;
  var max = 0;

  for (final q in questions) {
    max += q.points;
    subjectMax[q.subjectId] = (subjectMax[q.subjectId] ?? 0) + q.points;
    final correct = answers[q.qid] == q.answerIndex;
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
