import '../question/question.dart';

/// 補助簿問題（商品有高帳・現金出納帳など）の1セルの判定結果の種類。
enum LedgerCellDiffKind {
  /// 値が正解と一致。
  correct,

  /// セルはあるが値が違う。
  wrongValue,

  /// 正解にあるがユーザー入力にないセル（未入力）。
  missing,

  /// ユーザー入力にあるが正解にないセル（余分な入力）。
  extra,
}

/// 補助簿問題1セルの判定結果。[expected] は正解側、[actual] はユーザー入力側
/// （該当しない側は null）。
class LedgerCellDiff {
  const LedgerCellDiff({required this.kind, this.expected, this.actual});

  final LedgerCellDiffKind kind;
  final LedgerCell? expected;
  final LedgerCell? actual;
}

/// 補助簿問題の判定結果。
class LedgerJudgeResult {
  const LedgerJudgeResult({required this.diffs});

  /// セルごとの判定。
  final List<LedgerCellDiff> diffs;

  /// 正解セル数（[LedgerCellDiffKind.correct] の数）。
  int get correctCount => diffs.where((d) => d.kind == LedgerCellDiffKind.correct).length;

  /// 採点対象のセル総数（正解の [LedgerAnswer.blankCells] の数）。
  int get totalCount => diffs.where((d) => d.expected != null).length;

  /// 全セルが正解と一致しているか。
  bool get isCorrect =>
      totalCount > 0 && diffs.every((d) => d.kind == LedgerCellDiffKind.correct);
}

/// 補助簿問題の正解 [correct]（[LedgerAnswer.blankCells]）とユーザー入力
/// [userInput] を、記入行×列グループ×項目の組み合わせで対応づけて比較する。
LedgerJudgeResult judgeLedger(LedgerAnswer correct, List<LedgerCell> userInput) {
  bool samePosition(LedgerCell a, LedgerCell b) =>
      a.rowIndex == b.rowIndex && a.group == b.group && a.field == b.field;

  final remainingExpected = List<LedgerCell>.from(correct.blankCells);
  final remainingActual = List<LedgerCell>.from(userInput);
  final diffs = <LedgerCellDiff>[];

  for (var i = remainingExpected.length - 1; i >= 0; i--) {
    final expected = remainingExpected[i];
    final j = remainingActual.indexWhere((actual) => samePosition(expected, actual));
    if (j == -1) continue;
    final actual = remainingActual[j];
    diffs.add(LedgerCellDiff(
      kind: actual.value == expected.value
          ? LedgerCellDiffKind.correct
          : LedgerCellDiffKind.wrongValue,
      expected: expected,
      actual: actual,
    ));
    remainingExpected.removeAt(i);
    remainingActual.removeAt(j);
  }

  for (final e in remainingExpected) {
    diffs.add(LedgerCellDiff(kind: LedgerCellDiffKind.missing, expected: e));
  }
  for (final a in remainingActual) {
    diffs.add(LedgerCellDiff(kind: LedgerCellDiffKind.extra, actual: a));
  }

  return LedgerJudgeResult(diffs: diffs);
}
