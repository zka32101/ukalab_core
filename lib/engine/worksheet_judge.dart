import '../question/question.dart';

/// 表埋め問題（精算表・財務諸表など）の1セルの判定結果の種類。
enum WorksheetCellDiffKind {
  /// 金額が正解と一致。
  correct,

  /// セルはあるが金額が違う。
  wrongAmount,

  /// 正解にあるがユーザー入力にないセル（未入力）。
  missing,

  /// ユーザー入力にあるが正解にないセル（余分な入力）。
  extra,
}

/// 表埋め問題1セルの判定結果。[expected] は正解側、[actual] はユーザー入力側
/// （該当しない側は null）。
class WorksheetCellDiff {
  const WorksheetCellDiff({required this.kind, this.expected, this.actual});

  final WorksheetCellDiffKind kind;
  final WorksheetCell? expected;
  final WorksheetCell? actual;
}

/// 表埋め問題の判定結果。
class WorksheetJudgeResult {
  const WorksheetJudgeResult({required this.diffs});

  /// セルごとの判定。
  final List<WorksheetCellDiff> diffs;

  /// 正解セル数（[WorksheetCellDiffKind.correct] の数）。
  int get correctCount =>
      diffs.where((d) => d.kind == WorksheetCellDiffKind.correct).length;

  /// 採点対象のセル総数（正解の [WorksheetAnswer.blankCells] の数）。
  int get totalCount => diffs.where((d) => d.expected != null).length;

  /// 全セルが正解と一致しているか。
  bool get isCorrect =>
      totalCount > 0 && diffs.every((d) => d.kind == WorksheetCellDiffKind.correct);
}

/// 表埋め問題の正解 [correct]（[WorksheetAnswer.blankCells]）とユーザー入力
/// [userInput] を、勘定科目×列の組み合わせで対応づけて比較する。
WorksheetJudgeResult judgeWorksheet(WorksheetAnswer correct, List<WorksheetCell> userInput) {
  bool samePosition(WorksheetCell a, WorksheetCell b) =>
      a.account == b.account && a.column == b.column;

  final remainingExpected = List<WorksheetCell>.from(correct.blankCells);
  final remainingActual = List<WorksheetCell>.from(userInput);
  final diffs = <WorksheetCellDiff>[];

  for (var i = remainingExpected.length - 1; i >= 0; i--) {
    final expected = remainingExpected[i];
    final j = remainingActual.indexWhere((actual) => samePosition(expected, actual));
    if (j == -1) continue;
    final actual = remainingActual[j];
    diffs.add(WorksheetCellDiff(
      kind: actual.amount == expected.amount
          ? WorksheetCellDiffKind.correct
          : WorksheetCellDiffKind.wrongAmount,
      expected: expected,
      actual: actual,
    ));
    remainingExpected.removeAt(i);
    remainingActual.removeAt(j);
  }

  for (final e in remainingExpected) {
    diffs.add(WorksheetCellDiff(kind: WorksheetCellDiffKind.missing, expected: e));
  }
  for (final a in remainingActual) {
    diffs.add(WorksheetCellDiff(kind: WorksheetCellDiffKind.extra, actual: a));
  }

  return WorksheetJudgeResult(diffs: diffs);
}
