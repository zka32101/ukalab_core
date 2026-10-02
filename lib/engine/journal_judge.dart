import '../question/question.dart';

/// 仕訳1行の判定結果の種類。
enum JournalLineDiffKind {
  /// 貸借・科目・金額とも正解と一致。
  correct,

  /// 貸借・金額は合っているが科目が違う。
  wrongAccount,

  /// 貸借・科目は合っているが金額が違う。
  wrongAmount,

  /// 科目・金額は合っているが貸借が逆。
  sideSwapped,

  /// 正解にあるがユーザー入力にない行（行の不足）。
  missing,

  /// ユーザー入力にあるが正解にない行（余分な行）。
  extra,
}

/// 仕訳1行の判定結果。[expected] は正解側、[actual] はユーザー入力側（該当しない側は null）。
class JournalLineDiff {
  const JournalLineDiff({required this.kind, this.expected, this.actual});

  final JournalLineDiffKind kind;
  final JournalLine? expected;
  final JournalLine? actual;
}

/// 仕訳問題の判定結果。
class JournalJudgeResult {
  const JournalJudgeResult({required this.diffs, required this.balanced});

  /// 行ごとの判定（企画設計書3-2「誤りは科目の誤り・金額の誤り・貸借の逆などに分けて指摘」）。
  final List<JournalLineDiff> diffs;

  /// ユーザー入力の借方合計＝貸方合計か（入力中の即時判定用。完全正解とは別）。
  final bool balanced;

  /// 全行が正解と一致しているか。
  bool get isCorrect =>
      diffs.isNotEmpty && diffs.every((d) => d.kind == JournalLineDiffKind.correct);
}

/// 仕訳の正解 [correct] とユーザー入力 [userInput] を比較する。
///
/// 完全一致 → 貸借逆 → 科目違い → 金額違い の順に行同士を対応づけ、
/// 対応しなかった正解行は [JournalLineDiffKind.missing]、
/// 対応しなかった入力行は [JournalLineDiffKind.extra] になる。
JournalJudgeResult judgeJournal(JournalAnswer correct, List<JournalLine> userInput) {
  final remainingExpected = List<JournalLine>.from(correct.lines);
  final remainingActual = List<JournalLine>.from(userInput);
  final diffs = <JournalLineDiff>[];

  void matchPass(
    bool Function(JournalLine expected, JournalLine actual) test,
    JournalLineDiffKind kind,
  ) {
    for (var i = remainingExpected.length - 1; i >= 0; i--) {
      final expected = remainingExpected[i];
      final j = remainingActual.indexWhere((actual) => test(expected, actual));
      if (j != -1) {
        diffs.add(JournalLineDiff(kind: kind, expected: expected, actual: remainingActual[j]));
        remainingExpected.removeAt(i);
        remainingActual.removeAt(j);
      }
    }
  }

  matchPass((e, a) => e == a, JournalLineDiffKind.correct);
  matchPass(
    (e, a) => e.account == a.account && e.amount == a.amount && e.side != a.side,
    JournalLineDiffKind.sideSwapped,
  );
  matchPass(
    (e, a) => e.side == a.side && e.amount == a.amount && e.account != a.account,
    JournalLineDiffKind.wrongAccount,
  );
  matchPass(
    (e, a) => e.side == a.side && e.account == a.account && e.amount != a.amount,
    JournalLineDiffKind.wrongAmount,
  );

  for (final e in remainingExpected) {
    diffs.add(JournalLineDiff(kind: JournalLineDiffKind.missing, expected: e));
  }
  for (final a in remainingActual) {
    diffs.add(JournalLineDiff(kind: JournalLineDiffKind.extra, actual: a));
  }

  final debit = _sum(userInput, JournalSide.debit);
  final credit = _sum(userInput, JournalSide.credit);

  return JournalJudgeResult(diffs: diffs, balanced: debit == credit);
}

int _sum(List<JournalLine> lines, JournalSide side) =>
    lines.where((l) => l.side == side).fold(0, (sum, l) => sum + l.amount);
