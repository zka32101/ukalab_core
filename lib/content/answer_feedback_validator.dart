import '../experience/comparison_view.dart';
import '../question/question.dart';
import '../term/term.dart';
import 'question_validator.dart';

/// `subtopic-conflict` 検査で「細目IDは1つの何に属するか」の単位。
enum SubtopicScope {
  /// 同じ細目IDは1つの `topicId` にだけ付く（既定。従来の挙動）
  topic,

  /// 同じ細目IDは1つの `subjectId` にだけ付く。
  /// `topicId` が概念単位で、章を `subjectId` で表す試験向け（細目IDは `<subjectId>-<細目>` など）
  subject,
}

/// 論点タグ（章 `topicId`＋細目 `subtopicId`）と比較対象タグ（`compareWith`）の検査。
///
/// 次は既存の検査が受け持つ（ここでは重ねない）。
/// - 章・細目が空文字: 読み込み時にエラー（章）／タグなし扱い（細目）
/// - 比較対象の空・重複・用語データに無いID: [validateCompareTargets]
/// - 用語の `relatedQuestionIds` が存在しない qid を指す: [validateTerms]
///
/// ここで見つけるもの:
/// - `subtopic-conflict`: 同じ細目IDが複数の章に付いている（細目は1つの章に属する）。
///   [subtopicScope] を [SubtopicScope.subject] にすると、章の代わりに `subjectId` 単位で検査する
/// - `compare-self`: 比較対象が、その問題の答えの用語（`relatedQuestionIds` にその問題を持つ用語）自身
/// - `compare-no-view`: 比較対象はあるが、違いの比較表示が作れない（答えの用語が無く、
///   有効な比較対象が2つに満たない等）。解答後に何も出ないタグになるので直す
///
/// 用語を使う検査は [terms] が空なら行わない（`--terms` が無いとき）。
List<ContentIssue> validateAnswerFeedbackTags(
  List<Question> questions, {
  List<Term> terms = const [],
  SubtopicScope subtopicScope = SubtopicScope.topic,
}) {
  String unitOf(Question q) =>
      subtopicScope == SubtopicScope.subject ? q.subjectId : q.topicId;
  final unitName = subtopicScope == SubtopicScope.subject ? '科目' : '章';
  final issues = <ContentIssue>[];

  final chaptersBySubtopic = <String, Set<String>>{};
  for (final q in questions) {
    final sub = q.subtopicId;
    if (sub != null) {
      chaptersBySubtopic.putIfAbsent(sub, () => <String>{}).add(unitOf(q));
    }
  }
  for (final q in questions) {
    final sub = q.subtopicId;
    if (sub == null) continue;
    final chapters = chaptersBySubtopic[sub]!;
    if (chapters.length > 1) {
      final list = chapters.toList()..sort();
      issues.add(ContentIssue(
        q.qid,
        'subtopic-conflict',
        '細目 "$sub" が複数の$unitName（${list.join('、')}）に付いています',
      ));
    }
  }

  if (terms.isEmpty) return issues;
  for (final q in questions) {
    if (q.compareWith.isEmpty) continue;
    final answerTermIds = {
      for (final t in terms)
        if (t.relatedQuestionIds.contains(q.qid)) t.termId,
    };
    for (final id in q.compareWith.toSet()) {
      if (answerTermIds.contains(id)) {
        issues.add(ContentIssue(
          q.qid,
          'compare-self',
          '比較対象 "$id" はこの問題の答えの用語自身です',
        ));
      }
    }
    if (buildComparison(q, terms) == null) {
      issues.add(ContentIssue(
        q.qid,
        'compare-no-view',
        'compareWith はあるが違いの比較表示が作れません'
            '（答えの用語の relatedQuestionIds にこの問題を入れるか、比較対象を2つ以上にしてください）',
      ));
    }
  }
  return issues;
}
