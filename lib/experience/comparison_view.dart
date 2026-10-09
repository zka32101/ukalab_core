import '../question/question.dart';
import '../term/term.dart';

/// 違いの比較表示の1行（用語1つ分）。
class ComparisonRow {
  const ComparisonRow({required this.term, required this.isAnswer});

  final Term term;

  /// この問題の答えにあたる用語か（false は、紛らわしい相手）。
  final bool isAnswer;

  /// 「1行ずつ見せる」違いの説明。よくある間違い・紛らわしい用語との違いがあればそれ、
  /// 無ければ「ひとことで言うと」。
  String get differenceLine {
    final mistake = term.commonMistake;
    return mistake != null && mistake.trim().isNotEmpty ? mistake : term.headline;
  }
}

/// 違いの比較表示。正解の用語と、紛らわしい相手の用語を並べる。
class ComparisonView {
  const ComparisonView(this.rows);

  /// 答えの用語が先、紛らわしい相手が後（登録順）。
  final List<ComparisonRow> rows;
}

/// 問題の比較対象タグ（[Question.compareWith]）から、違いの比較表示を自動生成する。
///
/// 答えの用語は、[Term.relatedQuestionIds] にこの問題の qid を持つ用語。
/// 紛らわしい相手は [Question.compareWith] の用語。無効な用語・見つからない用語・
/// 重複は除く。並べる用語が2つに満たなければ null（比較表示は出さない）。
ComparisonView? buildComparison(Question question, List<Term> terms) {
  final byId = {for (final t in terms) t.termId: t};
  final rows = <ComparisonRow>[];
  final seen = <String>{};

  for (final t in terms) {
    if (!t.disabled && t.relatedQuestionIds.contains(question.qid) && seen.add(t.termId)) {
      rows.add(ComparisonRow(term: t, isAnswer: true));
    }
  }
  for (final id in question.compareWith) {
    final t = byId[id];
    if (t != null && !t.disabled && seen.add(t.termId)) {
      rows.add(ComparisonRow(term: t, isAnswer: false));
    }
  }
  return rows.length >= 2 ? ComparisonView(rows) : null;
}
